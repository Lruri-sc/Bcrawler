import Foundation

/// Bridges Swift ↔ Python via Process + stdout JSON protocol.
/// Each Python script writes one JSON object per line to stdout.
/// Swift reads lines asynchronously and decodes them.
actor PythonBridge {
    private let pythonPath: String
    private let scriptsDirectory: URL

    init(pythonPath: String = "/Library/Frameworks/Python.framework/Versions/3.13/bin/python3") {
        self.pythonPath = pythonPath
        if let resourceURL = Bundle.main.resourceURL {
            self.scriptsDirectory = resourceURL
        } else {
            self.scriptsDirectory = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        }
    }

    // MARK: - Search Bangumi

    /// Calls search.py with a keyword, returns parsed Bangumi array
    func searchBangumi(keyword: String) async throws -> [Bangumi] {
        let script = scriptsDirectory.appendingPathComponent("search.py")
        let output = try await runScript(script.path, arguments: ["--keyword", keyword])

        guard let data = output.data(using: .utf8) else {
            throw BridgeError.invalidOutput
        }

        let decoder = JSONDecoder()
        let results = try decoder.decode([Bangumi].self, from: data)
        return results
    }

    // MARK: - Fetch Episodes

    /// Calls fetch_episodes.py with season_id, returns Episode array
    func fetchEpisodes(seasonId: Int) async throws -> [Episode] {
        let script = scriptsDirectory.appendingPathComponent("fetch_episodes.py")
        let output = try await runScript(script.path, arguments: ["--season-id", String(seasonId)])

        guard let data = output.data(using: .utf8) else {
            throw BridgeError.invalidOutput
        }

        let decoder = JSONDecoder()
        let episodes = try decoder.decode([Episode].self, from: data)
        return episodes
    }

    // MARK: - Batch Export Danmaku

    /// Calls fetch_danmaku.py with cid list + output dir.
    /// Streams progress via onProgress callback.
    func exportDanmaku(
        episodes: [Episode],
        outputDirectory: URL,
        onProgress: @Sendable @escaping (Int, Int, String, String) -> Void
    ) async throws {
        let script = scriptsDirectory.appendingPathComponent("fetch_danmaku.py")

        // Pass cids as comma-separated, episode titles as JSON for filenames
        let cidList = episodes.map { String($0.cid) }.joined(separator: ",")
        let titleList = episodes.map { $0.displayName }
        let titlesJSON = try JSONEncoder().encode(titleList)
        let titlesString = String(data: titlesJSON, encoding: .utf8) ?? "[]"

        try await runStreamingScript(
            script.path,
            arguments: [
                "--cids", cidList,
                "--titles", titlesString,
                "--output", outputDirectory.path
            ],
            onLine: { line in
                // Each line is a JSON progress message
                guard let data = line.data(using: .utf8),
                      let msg = try? JSONDecoder().decode(ProgressMessage.self, from: data)
                else { return }

                onProgress(msg.current, msg.total, msg.episode, msg.status)
            }
        )
    }

    // MARK: - Internal

    /// Run a script and collect all stdout into a single string.
    /// Supports cooperative cancellation — terminates the process if the Task is cancelled.
    private func runScript(_ path: String, arguments: [String]) async throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: pythonPath)
        process.arguments = [path] + arguments

        let pipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = pipe
        process.standardError = errorPipe

        try process.run()

        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                process.terminationHandler = { _ in
                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()

                    if process.terminationStatus != 0 {
                        let errorString = String(data: errorData, encoding: .utf8) ?? "Unknown error"
                        if process.terminationStatus == 15 || process.terminationStatus == 9 {
                            continuation.resume(throwing: CancellationError())
                        } else {
                            continuation.resume(throwing: BridgeError.scriptFailed(code: Int(process.terminationStatus), message: errorString))
                        }
                        return
                    }

                    guard let output = String(data: data, encoding: .utf8) else {
                        continuation.resume(throwing: BridgeError.invalidOutput)
                        return
                    }

                    continuation.resume(returning: output.trimmingCharacters(in: .whitespacesAndNewlines))
                }
            }
        } onCancel: {
            if process.isRunning { process.terminate() }
        }
    }

    /// Run a script and stream stdout line-by-line (for progress)
    private func runStreamingScript(
        _ path: String,
        arguments: [String],
        onLine: @escaping (String) -> Void
    ) async throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: pythonPath)
        process.arguments = [path] + arguments

        let pipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = pipe
        process.standardError = errorPipe

        // Read stdout line by line on a background thread
        pipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty,
                  let str = String(data: data, encoding: .utf8)
            else { return }

            // May contain multiple lines
            let lines = str.components(separatedBy: .newlines)
            for line in lines where !line.isEmpty {
                onLine(line)
            }
        }

        try process.run()

        // Await completion
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            process.terminationHandler = { _ in
                continuation.resume()
            }
        }

        pipe.fileHandleForReading.readabilityHandler = nil

        if process.terminationStatus != 0 {
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let errorString = String(data: errorData, encoding: .utf8) ?? "Unknown error"
            throw BridgeError.scriptFailed(code: Int(process.terminationStatus), message: errorString)
        }
    }
}

// MARK: - Supporting Types

private struct ProgressMessage: Codable {
    let current: Int
    let total: Int
    let episode: String
    let status: String  // "downloading" | "converting" | "complete" | "error"
    let filePath: String?
    let error: String?
}

enum BridgeError: LocalizedError {
    case scriptNotFound(String)
    case scriptFailed(code: Int, message: String)
    case invalidOutput
    case pythonNotFound

    var errorDescription: String? {
        switch self {
        case .scriptNotFound(let name):
            "找不到脚本: \(name)"
        case .scriptFailed(let code, let message):
            "脚本执行失败 (code \(code)): \(message)"
        case .invalidOutput:
            "脚本输出格式错误"
        case .pythonNotFound:
            "找不到 Python3，请在设置中配置路径"
        }
    }
}
