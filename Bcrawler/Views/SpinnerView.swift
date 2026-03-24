import SwiftUI

struct SpinnerView: View {
    @State private var isAnimating = false

    var body: some View {
        Image(systemName: "arrow.trianglehead.2.counterclockwise")
            .font(.caption2)
            .foregroundStyle(.secondary)
            .rotationEffect(.degrees(isAnimating ? 360 : 0))
            .animation(
                .linear(duration: 1.0).repeatForever(autoreverses: false),
                value: isAnimating
            )
            .onAppear { isAnimating = true }
    }
}
