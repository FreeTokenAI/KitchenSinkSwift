import SwiftUI

struct ModelDownloadProgressBar: View {
    let progress: Double

    var body: some View {
        VStack(spacing: 8) {
            Text("Downloading AI model")
                .font(.caption)
                .foregroundColor(.secondary)

            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle())
                .scaleEffect(y: 1.5)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
                .shadow(radius: 4, y: -2)
        )
        .padding(.horizontal)
        .padding(.bottom, 20)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

#Preview {
    ModelDownloadProgressBar(progress: 0.45)
}