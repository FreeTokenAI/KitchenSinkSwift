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
                ScrollView {
                VStack(spacing: 28) {
                    VStack(alignment: .leading, spacing: 14) {
                        Label {
                            Text("Browse and download AI models available in FreeToken. Cloud models work instantly, while local models can be downloaded for offline use.")
                        } icon: {
                            Image(systemName: "cpu.fill")
                                .foregroundColor(.accentColor)
                        }
                        .font(.body)
                        .foregroundColor(.primary)
                    }
                    .padding()
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color(.systemGray6), Color(.systemGray5)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(14)
                    .shadow(color: Color.black.opacity(0.07), radius: 6, x: 0, y: 2)

                    if viewModel.isLoading {
                        ProgressView("Loading models...")
                            .padding()
                    } else if viewModel.aiModels.isEmpty {
                        Text("No models available")
                            .foregroundColor(.secondary)
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
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .padding()
                    }
                    }
                    .padding()
                }

                // Global download progress bar at the bottom
                VStack {
                    Spacer()
                    if freeTokenClient.isDownloadingModel {
                        ModelDownloadProgressBar(progress: freeTokenClient.modelDownloadProgress)
                            .frame(maxWidth: 400)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .animation(.easeInOut, value: freeTokenClient.isDownloadingModel)
            }
            .navigationTitle("AI Models")
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
        model.cloudOnly ? .blue : .green
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

                // Downloaded checkmark overlay
                if !model.cloudOnly && viewModel.isModelDownloaded(model.code) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.green)
                        .background(Circle().fill(Color(.systemBackground)))
                        .offset(x: 20, y: -20)
                }

                // Downloading progress overlay
                if viewModel.isModelDownloading(model.code) {
                    ProgressView(value: viewModel.getDownloadProgress(model.code) / 100.0)
                        .progressViewStyle(CircularProgressViewStyle())
                        .frame(width: 30, height: 30)
                }
            }

            VStack(spacing: 4) {
                Text(model.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .truncationMode(.tail)

                HStack(spacing: 4) {
                    Text(model.cloudOnly ? "Cloud Model" : "Local Model")
                        .font(.caption)
                        .foregroundColor(modelTypeColor)
                        .fontWeight(.medium)

                    if !model.cloudOnly && viewModel.isModelDownloaded(model.code) {
                        Text("• Downloaded")
                            .font(.caption)
                            .foregroundColor(.green)
                            .fontWeight(.medium)
                    }
                }

                Text("Code: \(model.code)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 160)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(modelTypeColor.opacity(0.2), lineWidth: 1)
        )
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
