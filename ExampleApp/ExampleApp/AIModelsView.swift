import SwiftUI
import FreeToken

struct AIModelsView: View {
    @ObservedObject private var freeTokenClient: FreeTokenClient
    @StateObject private var viewModel: AIModelsViewModel

    init(freeTokenClient: FreeTokenClient) {
        self.freeTokenClient = freeTokenClient
        _viewModel = StateObject(wrappedValue: AIModelsViewModel(freeTokenClient: freeTokenClient))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Cyberpunk background
                CyberpunkTheme.Gradients.backgroundGradient
                    .ignoresSafeArea()

                ScrollView {
                VStack(spacing: 28) {
                    VStack(alignment: .leading, spacing: 14) {
                        Label {
                            Text("BROWSE AND DOWNLOAD AI MODELS AVAILABLE IN FREETOKEN. CLOUD-ONLY MODELS ARE TOO LARGE TO RUN ON LOCAL DEVICES, WHILE LOCAL MODELS CAN BE DOWNLOADED FOR USE ON DEVICE.")
                                .textCase(.uppercase)
                                .font(.system(size: 12, weight: .medium))
                                .kerning(0.8)
                        } icon: {
                            Image(systemName: "cpu.fill")
                                .foregroundColor(CyberpunkTheme.Colors.cyberCyan)
                                .neonGlow(color: CyberpunkTheme.Colors.cyberCyan, radius: 2)
                        }
                        .foregroundColor(CyberpunkTheme.Colors.cyberBlueLight)
                    }
                    .padding()
                    .cyberPanel()
                    .shadow(color: CyberpunkTheme.Colors.cyberMagenta.opacity(0.3), radius: 10)

                    if viewModel.isLoading {
                        VStack {
                            ProgressView()
                                .tint(CyberpunkTheme.Colors.cyberCyan)
                            Text("LOADING MODELS...")
                                .font(.system(size: 12, weight: .semibold))
                                .textCase(.uppercase)
                                .kerning(1.2)
                                .foregroundColor(CyberpunkTheme.Colors.cyberCyan)
                        }
                        .padding()
                    } else if viewModel.aiModels.isEmpty {
                        Text("NO MODELS AVAILABLE")
                            .font(.system(size: 12, weight: .semibold))
                            .textCase(.uppercase)
                            .kerning(1.2)
                            .foregroundColor(CyberpunkTheme.Colors.cyberMagenta)
                            .padding()
                    } else {
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            ForEach(viewModel.aiModels, id: \.code) { model in
                                NavigationLink {
                                    AIModelDetailView(
                                        model: model,
                                        viewModel: viewModel
                                    )
                                } label: {
                                    AIModelCard(
                                        model: model,
                                        viewModel: viewModel
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }

                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage.uppercased())
                            .font(.system(size: 12, weight: .semibold))
                            .textCase(.uppercase)
                            .kerning(0.8)
                            .foregroundColor(.red)
                            .neonGlow(color: .red, radius: 2)
                            .padding()
                    }
                    }
                    .padding()
                }

                // Global download progress bar at the bottom with cyberpunk styling
                VStack {
                    Spacer()
                    if freeTokenClient.isDownloadingModel {
                        ModelDownloadProgressBar(progress: freeTokenClient.modelDownloadProgress)
                            .frame(maxWidth: 400)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(CyberpunkTheme.Colors.cyberPanel)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(CyberpunkTheme.Colors.cyberCyan, lineWidth: 1)
                                    )
                            )
                            .shadow(color: CyberpunkTheme.Colors.cyberCyan.opacity(0.5), radius: 10)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .animation(.easeInOut, value: freeTokenClient.isDownloadingModel)
            }
            .navigationTitle("AI MODELS")
            .toolbarBackground(CyberpunkTheme.Colors.cyberPanel, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .task {
                await viewModel.loadAIModels()
            }
            .refreshable {
                await viewModel.loadAIModels()
            }
        }
    }
}

struct AIModelCard: View {
    let model: FreeToken.AIModel
    @ObservedObject var viewModel: AIModelsViewModel

    private var modelTypeColor: Color {
        model.cloudOnly ? CyberpunkTheme.Colors.cyberCyan : CyberpunkTheme.Colors.cyberGreen
    }

    private var modelTypeIcon: String {
        model.cloudOnly ? "cloud.fill" : "internaldrive.fill"
    }

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Image(systemName: modelTypeIcon)
                    .font(.system(size: 36))
                    .foregroundColor(modelTypeColor)
                    .neonGlow(color: modelTypeColor, radius: 3)

                // Downloaded checkmark overlay
                if !model.cloudOnly && viewModel.isModelDownloaded(model.code) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(CyberpunkTheme.Colors.cyberGreen)
                        .background(Circle().fill(CyberpunkTheme.Colors.cyberBlueDark))
                        .neonGlow(color: CyberpunkTheme.Colors.cyberGreen, radius: 2)
                        .offset(x: 20, y: -20)
                }

                // Downloading progress overlay
                if viewModel.isModelDownloading(model.code) {
                    ProgressView(value: viewModel.getDownloadProgress(model.code) / 100.0)
                        .progressViewStyle(CircularProgressViewStyle(tint: CyberpunkTheme.Colors.cyberGold))
                        .frame(width: 30, height: 30)
                }
            }

            VStack(spacing: 4) {
                Text(model.name.uppercased())
                    .font(.system(size: 14, weight: .bold))
                    .textCase(.uppercase)
                    .kerning(1.2)
                    .foregroundColor(CyberpunkTheme.Colors.cyberGold)
                    .lineLimit(1)
                    .truncationMode(.tail)

                HStack(spacing: 4) {
                    Text(model.cloudOnly ? "CLOUD MODEL" : "LOCAL MODEL")
                        .font(.system(size: 10, weight: .semibold))
                        .textCase(.uppercase)
                        .kerning(0.8)
                        .foregroundColor(modelTypeColor)

                    if !model.cloudOnly && viewModel.isModelDownloaded(model.code) {
                        Text("• DOWNLOADED")
                            .font(.system(size: 10, weight: .semibold))
                            .textCase(.uppercase)
                            .kerning(0.8)
                            .foregroundColor(CyberpunkTheme.Colors.cyberGreen)
                    }
                }

                Text("CODE: \(model.code.uppercased())")
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundColor(CyberpunkTheme.Colors.cyberBlueLight)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 160)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(CyberpunkTheme.Colors.cyberPanel)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(modelTypeColor.opacity(0.5), lineWidth: 1)
        )
        .shadow(color: modelTypeColor.opacity(0.3), radius: 10)
        .overlay(
            Group {
                if viewModel.isModelDownloading(model.code) {
                    VStack {
                        HStack {
                            Spacer()
                            Text("\(Int(viewModel.getDownloadProgress(model.code)))%")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .padding(4)
                                .background(Color(.systemBackground).opacity(0.9))
                                .cornerRadius(4)
                        }
                        Spacer()
                    }
                    .padding(8)
                }
            }
        )
    }
}
