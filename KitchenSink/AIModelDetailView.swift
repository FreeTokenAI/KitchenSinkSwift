import SwiftUI
import FreeToken

struct AIModelDetailView: View {
    let model: FreeToken.AIModel
    @ObservedObject var viewModel: AIModelsViewModel
    @State private var downloadComplete = false
    @State private var showDeleteConfirmation = false

    private var modelTypeColor: Color {
        model.cloudOnly ? CyberpunkTheme.Colors.cyberCyan : CyberpunkTheme.Colors.cyberGreen
    }

    private var modelTypeIcon: String {
        model.cloudOnly ? "cloud.fill" : "internaldrive.fill"
    }

    var body: some View {
        ZStack {
            // Cyberpunk background
            CyberpunkTheme.Gradients.backgroundGradient
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .center, spacing: 16) {
                        Image(systemName: modelTypeIcon)
                            .font(.system(size: 60))
                            .foregroundColor(modelTypeColor)
                            .neonGlow(color: modelTypeColor, radius: 3)

                        Text(model.name.uppercased())
                            .font(.system(size: 24, weight: .bold))
                            .textCase(.uppercase)
                            .kerning(2)
                            .foregroundColor(CyberpunkTheme.Colors.cyberGold)
                            .neonGlow(color: CyberpunkTheme.Colors.cyberGold, radius: 2)

                        HStack(spacing: 12) {
                            Label(
                                model.cloudOnly ? "CLOUD MODEL" : "LOCAL MODEL",
                                systemImage: modelTypeIcon
                            )
                            .font(.system(size: 12, weight: .semibold))
                            .textCase(.uppercase)
                            .kerning(0.8)
                            .foregroundColor(modelTypeColor)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(modelTypeColor.opacity(0.2))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(modelTypeColor.opacity(0.5), lineWidth: 1)
                            )
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .cyberPanel()

                    VStack(alignment: .leading, spacing: 20) {
                        DetailSection(title: "MODEL INFORMATION") {
                            DetailRow(label: "MODEL CODE", value: model.code.uppercased())
                            DetailRow(label: "TRAINING CUTOFF", value: model.trainingCutoffDate.uppercased())
                            DetailRow(
                                label: "JSON TOOL CALLS",
                                value: model.jsonToolCalls ? "SUPPORTED" : "NOT SUPPORTED",
                                valueColor: model.jsonToolCalls ? CyberpunkTheme.Colors.cyberGreen : CyberpunkTheme.Colors.cyberMagenta
                            )
                        }

                        DetailSection(title: "CAPABILITIES") {
                            CapabilityRow(
                                label: "TEXT PROCESSING",
                                supported: model.capabilities.text
                            )
                            CapabilityRow(
                                label: "IMAGE TO TEXT",
                                supported: model.capabilities.imageToText
                            )
                        }

                        DetailSection(title: "RECOMMENDED PLATFORMS") {
                            PlatformRow(
                                platform: "MACOS",
                                recommended: model.recommendedPlatforms.macOS
                            )
                            PlatformRow(
                                platform: "IOS",
                                recommended: model.recommendedPlatforms.iOS
                            )
                        }

                        if !model.cloudOnly {
                            VStack(spacing: 12) {
                                if viewModel.currentlyDownloadingModel == model.code {
                                    VStack(spacing: 8) {
                                        ProgressView(value: viewModel.downloadProgress / 100.0)
                                            .tint(CyberpunkTheme.Colors.cyberCyan)
                                            .progressViewStyle(LinearProgressViewStyle())

                                        Text("DOWNLOADING: \(Int(viewModel.downloadProgress))%")
                                            .font(.system(size: 12, weight: .medium))
                                            .textCase(.uppercase)
                                            .kerning(0.8)
                                            .foregroundColor(CyberpunkTheme.Colors.cyberCyan)
                                    }
                                    .padding()
                                    .cyberPanel()
                                } else if downloadComplete || viewModel.isModelDownloaded(model.code) {
                                    VStack(spacing: 12) {
                                        HStack {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(CyberpunkTheme.Colors.cyberGreen)
                                                .neonGlow(color: CyberpunkTheme.Colors.cyberGreen, radius: 2)
                                            Text("MODEL DOWNLOADED")
                                                .font(.system(size: 14, weight: .bold))
                                                .textCase(.uppercase)
                                                .kerning(1.2)
                                                .foregroundColor(CyberpunkTheme.Colors.cyberGreen)
                                        }
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(CyberpunkTheme.Colors.cyberGreen.opacity(0.1))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(CyberpunkTheme.Colors.cyberGreen.opacity(0.5), lineWidth: 1)
                                        )

                                        Button(action: {
                                            showDeleteConfirmation = true
                                        }) {
                                            HStack {
                                                Image(systemName: "trash.fill")
                                                Text("DELETE MODEL")
                                            }
                                            .font(.system(size: 14, weight: .bold))
                                            .textCase(.uppercase)
                                            .kerning(1.2)
                                            .foregroundColor(.red)
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(Color.red.opacity(0.1))
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 12)
                                                            .stroke(Color.red.opacity(0.5), lineWidth: 1)
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
                                            Text("DOWNLOAD MODEL")
                                        }
                                        .font(.system(size: 14, weight: .bold))
                                        .textCase(.uppercase)
                                        .kerning(1.2)
                                        .frame(maxWidth: .infinity)
                                    }
                                    .cyberButton()
                                    .disabled(viewModel.currentlyDownloadingModel == model.code)
                                }
                            }
                            .padding(.top)
                        }

                        if let errorMessage = viewModel.errorMessage {
                            Text(errorMessage.uppercased())
                                .font(.system(size: 12, weight: .medium))
                                .textCase(.uppercase)
                                .kerning(0.8)
                                .foregroundColor(.red)
                                .neonGlow(color: .red, radius: 2)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.red.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.red.opacity(0.5), lineWidth: 1)
                                )
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("MODEL DETAILS")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(CyberpunkTheme.Colors.cyberPanel, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .alert("DELETE MODEL", isPresented: $showDeleteConfirmation) {
            Button("CANCEL", role: .cancel) { }
            Button("DELETE", role: .destructive) {
                Task {
                    await deleteModel()
                }
            }
        } message: {
            Text("ARE YOU SURE YOU WANT TO DELETE '\(model.name.uppercased())'? YOU CAN DOWNLOAD IT AGAIN LATER IF NEEDED.")
        }
        .alert("MODEL NOT SUPPORTED", isPresented: $viewModel.showUnsupportedAlert) {
            Button("OK", role: .cancel) {
                viewModel.showUnsupportedAlert = false
            }
        } message: {
            Text("THIS DEVICE DOES NOT MEET THE REQUIREMENTS FOR ON-DEVICE AI FOR \(viewModel.unsupportedModelName.uppercased()).")
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
                .font(.system(size: 14, weight: .bold))
                .textCase(.uppercase)
                .kerning(1.2)
                .foregroundColor(CyberpunkTheme.Colors.cyberGold)

            VStack(alignment: .leading, spacing: 8) {
                content
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .cyberPanel()
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    var valueColor: Color = CyberpunkTheme.Colors.cyberCyan

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .textCase(.uppercase)
                .kerning(0.8)
                .foregroundColor(CyberpunkTheme.Colors.cyberBlueLight)
            Spacer()
            Text(value)
                .font(.system(size: 12, weight: .bold))
                .textCase(.uppercase)
                .kerning(0.8)
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
                .font(.system(size: 12, weight: .medium))
                .textCase(.uppercase)
                .kerning(0.8)
                .foregroundColor(CyberpunkTheme.Colors.cyberBlueLight)
            Spacer()
            Image(systemName: supported ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(supported ? CyberpunkTheme.Colors.cyberGreen : CyberpunkTheme.Colors.cyberMagenta.opacity(0.6))
                .neonGlow(color: supported ? CyberpunkTheme.Colors.cyberGreen : CyberpunkTheme.Colors.cyberMagenta, radius: 2)
        }
    }
}

struct PlatformRow: View {
    let platform: String
    let recommended: Bool

    var body: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: platform == "MACOS" ? "macbook" : "iphone")
                    .foregroundColor(CyberpunkTheme.Colors.cyberBlueLight)
                Text(platform)
                    .font(.system(size: 12, weight: .medium))
                    .textCase(.uppercase)
                    .kerning(0.8)
                    .foregroundColor(CyberpunkTheme.Colors.cyberBlueLight)
            }
            Spacer()
            if recommended {
                Label("RECOMMENDED", systemImage: "star.fill")
                    .font(.system(size: 11, weight: .bold))
                    .textCase(.uppercase)
                    .kerning(0.6)
                    .foregroundColor(CyberpunkTheme.Colors.cyberGold)
                    .neonGlow(color: CyberpunkTheme.Colors.cyberGold, radius: 2)
            } else {
                Text("NOT RECOMMENDED")
                    .font(.system(size: 11, weight: .medium))
                    .textCase(.uppercase)
                    .kerning(0.6)
                    .foregroundColor(CyberpunkTheme.Colors.cyberMagenta)
            }
        }
    }
}