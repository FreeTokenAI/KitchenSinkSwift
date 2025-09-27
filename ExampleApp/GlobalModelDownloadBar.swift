import SwiftUI

struct GlobalModelDownloadBar: View {
    @ObservedObject var freeTokenClient: FreeTokenClient

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Download icon with animation
                Image(systemName: freeTokenClient.modelDownloadProgress >= 1.0 ? "checkmark.circle.fill" : "arrow.down.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(freeTokenClient.modelDownloadProgress >= 1.0 ? .green : .blue)
                    .symbolEffect(.pulse, isActive: freeTokenClient.modelDownloadProgress < 1.0)

                VStack(alignment: .leading, spacing: 2) {
                    Text(freeTokenClient.modelDownloadProgress >= 1.0 ? "Model Downloaded" :
                         freeTokenClient.modelDownloadProgress == 0 ? "Starting Download..." : "Downloading AI Model")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.primary)

                    if freeTokenClient.modelDownloadProgress >= 1.0 {
                        Text("Ready for use")
                            .font(.system(size: 11))
                            .foregroundColor(.green)
                    } else if freeTokenClient.modelDownloadProgress == 0 {
                        Text("Preparing download...")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    } else {
                        Text("\(Int(freeTokenClient.modelDownloadProgress * 100))% complete")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Progress view
                ProgressView(value: freeTokenClient.modelDownloadProgress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .frame(width: 120)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.blue.opacity(0.1),
                        Color.blue.opacity(0.05)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )

            Divider()
                .background(Color(.systemGray4))
        }
    }
}

#Preview {
    VStack {
        GlobalModelDownloadBar(freeTokenClient: {
            let client = FreeTokenClient()
            client.isDownloadingModel = true
            client.modelDownloadProgress = 0.45
            return client
        }())

        Spacer()

        Text("Content below gets pushed down")
            .font(.title)
            .padding()
    }
}
