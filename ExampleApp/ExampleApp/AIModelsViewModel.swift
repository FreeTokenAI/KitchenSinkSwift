import Foundation
import FreeToken
import Combine

@MainActor
class AIModelsViewModel: ObservableObject {
    @Published var aiModels: [FreeToken.AIModel] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentlyDownloadingModel: String?
    @Published var modelDownloadStates: [String: FreeToken.ModelDownloadState] = [:]
    @Published var downloadProgress: Double = 0.0
    @Published var showUnsupportedAlert = false
    @Published var unsupportedModelName = ""

    private let freeTokenClient: FreeTokenClient
    private var cancellables = Set<AnyCancellable>()

    init(freeTokenClient: FreeTokenClient) {
        self.freeTokenClient = freeTokenClient
    }

    func loadAIModels() async {
        isLoading = true
        errorMessage = nil

        await freeTokenClient.client.listAIModels(
            success: { models in
                await MainActor.run {
                    self.aiModels = models
                    self.isLoading = false
                }
                // Check download state for each model
                await self.checkModelDownloadStates(for: models)
            },
            error: { error in
                await MainActor.run {
                    self.errorMessage = error.message
                    self.isLoading = false
                }
            }
        )
    }

    private func checkModelDownloadStates(for models: [FreeToken.AIModel]) async {
        for model in models {
            if !model.cloudOnly {
                do {
                    let state = try await freeTokenClient.client.getAIModelDownloadState(modelCode: model.code)
                    await MainActor.run {
                        self.modelDownloadStates[model.code] = state
                    }
                } catch {
                    ExampleAppLogger.shared.log("Failed to check download state for model \(model.code): \(error)", level: .error)
                }
            }
        }
    }

    func downloadModel(modelCode: String) async {
        ExampleAppLogger.shared.log("🚀 Starting model download for: \(modelCode)")
        // Use the global download state from FreeTokenClient
        await MainActor.run {
            self.objectWillChange.send()  // Force UI update
            self.currentlyDownloadingModel = modelCode
            self.freeTokenClient.isDownloadingModel = true
            self.freeTokenClient.modelDownloadProgress = 0.0
            self.downloadProgress = 0.0
        }

        await freeTokenClient.client.downloadAIModel(
            modelCode: modelCode,
            success: { state in
                await MainActor.run {
                    self.currentlyDownloadingModel = nil
                    self.freeTokenClient.isDownloadingModel = false

                    switch state {
                    case .downloaded:
                        self.freeTokenClient.modelDownloadProgress = 1.0
                        self.downloadProgress = 100.0
                        self.modelDownloadStates[modelCode] = .downloaded
                        ExampleAppLogger.shared.log("✅ Model download completed: \(state.rawValue)")
                    case .aiNotSupported:
                        self.downloadProgress = 0.0
                        // Do NOT mark as downloaded when not supported
                        self.modelDownloadStates[modelCode] = .notDownloaded
                        if let model = self.aiModels.first(where: { $0.code == modelCode }) {
                            self.unsupportedModelName = model.name
                        } else {
                            self.unsupportedModelName = modelCode
                        }
                        self.showUnsupportedAlert = true
                        ExampleAppLogger.shared.log("⚠️ Model not supported on this device: \(modelCode)")
                    case .cloudOnly:
                        self.downloadProgress = 0.0
                        ExampleAppLogger.shared.log("☁️ Cloud-only model, no download needed: \(modelCode)")
                    }
                }
            },
            error: { error in
                await MainActor.run {
                    self.currentlyDownloadingModel = nil
                    self.freeTokenClient.isDownloadingModel = false
                    self.downloadProgress = 0.0
                    self.errorMessage = error.message
                    ExampleAppLogger.shared.log("❌ Model download failed: \(error.message)", level: .error)
                }
            },
            progressPercent: { progress in
                Task { @MainActor in
                    // SDK provides progress as 0.0-1.0, convert to percentage
                    self.downloadProgress = progress * 100.0
                    self.freeTokenClient.modelDownloadProgress = progress
                    self.objectWillChange.send()  // Force UI update
                    ExampleAppLogger.shared.log("📊 Model download progress: \(String(format: "%.1f", progress * 100))% for \(modelCode)")
                }
            }
        )
    }

    func isModelDownloading(_ modelCode: String) -> Bool {
        return currentlyDownloadingModel == modelCode && freeTokenClient.isDownloadingModel
    }

    func getDownloadProgress(_ modelCode: String) -> Double {
        if currentlyDownloadingModel == modelCode {
            return downloadProgress
        }
        return 0.0
    }

    func isModelDownloaded(_ modelCode: String) -> Bool {
        return modelDownloadStates[modelCode] == .downloaded
    }

    func deleteModel(modelCode: String) async {
        await freeTokenClient.client.deleteAIModelCache(modelCode: modelCode)

        // Update the download state after deletion
        await MainActor.run {
            self.modelDownloadStates[modelCode] = .notDownloaded
            ExampleAppLogger.shared.log("✅ Model deleted: \(modelCode)")
        }
    }
}