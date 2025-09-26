import SwiftUI
import FreeToken

struct AIModelDetailView: View {
    let model: FreeToken.AIModel
    @ObservedObject var viewModel: AIModelsViewModel
    @State private var downloadComplete = false
    @State private var showDeleteConfirmation = false

    private var modelTypeColor: Color {
        model.cloudOnly ? .blue : .green
    }

    private var modelTypeIcon: String {
        model.cloudOnly ? "cloud.fill" : "internaldrive.fill"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .center, spacing: 16) {
                    Image(systemName: modelTypeIcon)
                        .font(.system(size: 60))
                        .foregroundColor(modelTypeColor)

                    Text(model.name)
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    HStack(spacing: 12) {
                        Label(
                            model.cloudOnly ? "Cloud Model" : "Local Model",
                            systemImage: modelTypeIcon
                        )
                        .font(.callout)
                        .foregroundColor(modelTypeColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(modelTypeColor.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()

                VStack(alignment: .leading, spacing: 20) {
                    DetailSection(title: "Model Information") {
                        DetailRow(label: "Model Code", value: model.code)
                        DetailRow(label: "Training Cutoff Date", value: model.trainingCutoffDate)
                        DetailRow(
                            label: "JSON Tool Calls",
                            value: model.jsonToolCalls ? "Supported" : "Not Supported",
                            valueColor: model.jsonToolCalls ? .green : .secondary
                        )
                    }

                    DetailSection(title: "Capabilities") {
                        CapabilityRow(
                            label: "Text Processing",
                            supported: model.capabilities.text
                        )
                        CapabilityRow(
                            label: "Image to Text",
                            supported: model.capabilities.imageToText
                        )
                    }

                    DetailSection(title: "Recommended Platforms") {
                        PlatformRow(
                            platform: "macOS",
                            recommended: model.recommendedPlatforms.macOS
                        )
                        PlatformRow(
                            platform: "iOS",
                            recommended: model.recommendedPlatforms.iOS
                        )
                    }

                    if !model.cloudOnly {
                        VStack(spacing: 12) {
                            if viewModel.currentlyDownloadingModel == model.code {
                                VStack(spacing: 8) {
                                    ProgressView(value: viewModel.downloadProgress / 100.0)
                                        .progressViewStyle(LinearProgressViewStyle())

                                    Text("Downloading: \(Int(viewModel.downloadProgress))%")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            } else if downloadComplete || viewModel.isModelDownloaded(model.code) {
                                VStack(spacing: 12) {
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                        Text("Model Downloaded")
                                            .font(.callout)
                                            .foregroundColor(.green)
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.green.opacity(0.1))
                                    .cornerRadius(12)

                                    Button(action: {
                                        showDeleteConfirmation = true
                                    }) {
                                        HStack {
                                            Image(systemName: "trash.fill")
                                            Text("Delete Model")
                                        }
                                        .font(.callout)
                                        .foregroundColor(.red)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color.red.opacity(0.1))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                                                )
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            } else {
                                Button(action: {
                                    Task {
                                        await downloadModel()
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: "arrow.down.circle.fill")
                                        Text("Download Model")
                                    }
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.accentColor)
                                    .cornerRadius(12)
                                }
                                .disabled(viewModel.currentlyDownloadingModel == model.code)
                            }
                        }
                        .padding(.top)
                    }

                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.callout)
                            .foregroundColor(.red)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(12)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Model Details")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Delete Model", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    await deleteModel()
                }
            }
        } message: {
            Text("Are you sure you want to delete '\(model.name)'? You can download it again later if needed.")
        }
        .alert("Model Not Supported", isPresented: $viewModel.showUnsupportedAlert) {
            Button("OK", role: .cancel) {
                viewModel.showUnsupportedAlert = false
            }
        } message: {
            Text("This device does not meet the requirements for on-device AI for \(viewModel.unsupportedModelName).")
        }
    }

    private func downloadModel() async {
        await viewModel.downloadModel(modelCode: model.code)
        // Only mark as complete if actually downloaded (not if unsupported)
        if !viewModel.isModelDownloading(model.code) && viewModel.isModelDownloaded(model.code) {
            downloadComplete = true
        }
    }

    private func deleteModel() async {
        await viewModel.deleteModel(modelCode: model.code)
        downloadComplete = false
    }
}

struct DetailSection<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)

            VStack(alignment: .leading, spacing: 8) {
                content
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    var valueColor: Color = .primary

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(valueColor)
        }
    }
}

struct CapabilityRow: View {
    let label: String
    let supported: Bool

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Image(systemName: supported ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(supported ? .green : .red.opacity(0.6))
        }
    }
}

struct PlatformRow: View {
    let platform: String
    let recommended: Bool

    var body: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: platform == "macOS" ? "macbook" : "iphone")
                    .foregroundColor(.secondary)
                Text(platform)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            if recommended {
                Label("Recommended", systemImage: "star.fill")
                    .font(.caption)
                    .foregroundColor(.orange)
            } else {
                Text("Not Recommended")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}
