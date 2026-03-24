#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_FILE="${PROJECT_ROOT}/Bcrawler/Models/Models.swift"
ICLOUD_DIR="${HOME}/Library/Mobile Documents/com~apple~CloudDocs/Bcrawler_Backups"
ICLOUD_SOURCE="${ICLOUD_DIR}/Models.swift"
ICLOUD_STRIPPED="${ICLOUD_DIR}/Models.no_comments.swift"

mkdir -p "${ICLOUD_DIR}"
cp "${SOURCE_FILE}" "${ICLOUD_SOURCE}"

python3 - <<'PY'
from pathlib import Path
import os

src = Path(os.path.expanduser("~/Library/Mobile Documents/com~apple~CloudDocs/Bcrawler_Backups/Models.swift"))
dst = Path(os.path.expanduser("~/Library/Mobile Documents/com~apple~CloudDocs/Bcrawler_Backups/Models.no_comments.swift"))
text = src.read_text(encoding="utf-8")

out = []
i = 0
n = len(text)
in_string = False
string_quote = ""
in_line_comment = False
in_block_comment = 0

while i < n:
    ch = text[i]
    nxt = text[i + 1] if i + 1 < n else ""

    if in_line_comment:
        if ch == "\n":
            in_line_comment = False
            out.append(ch)
        i += 1
        continue

    if in_block_comment > 0:
        if ch == "/" and nxt == "*":
            in_block_comment += 1
            i += 2
            continue
        if ch == "*" and nxt == "/":
            in_block_comment -= 1
            i += 2
            continue
        if ch == "\n":
            out.append("\n")
        i += 1
        continue

    if in_string:
        out.append(ch)
        if ch == "\\":
            if i + 1 < n:
                out.append(text[i + 1])
                i += 2
                continue
        if ch == string_quote:
            in_string = False
        i += 1
        continue

    if ch in ('"', "'"):
        in_string = True
        string_quote = ch
        out.append(ch)
        i += 1
        continue

    if ch == "/" and nxt == "/":
        in_line_comment = True
        i += 2
        continue

    if ch == "/" and nxt == "*":
        in_block_comment = 1
        i += 2
        continue

    out.append(ch)
    i += 1

dst.write_text("".join(out), encoding="utf-8")
PY

echo "Backed up to: ${ICLOUD_SOURCE}"
echo "Prepared for GitHub (comments removed): ${ICLOUD_STRIPPED}"
