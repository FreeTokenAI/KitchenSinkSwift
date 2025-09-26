import SwiftUI
import FreeToken
import Combine

// Separate class to handle token counting state
class TokenCounterViewModel: ObservableObject {
    @Published var tokenCount: Int = 0
    @Published var isCounting: Bool = false
    @Published var errorMessage: String?
    @Published var currentText: String = ""  // Track text for clear button visibility

    private var cancellables = Set<AnyCancellable>()
    private let textPublisher = PassthroughSubject<String, Never>()

    init() {
        setupTextPublisher()
    }

    private func setupTextPublisher() {
        textPublisher
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] text in
                self?.updateTokenCount(for: text)
            }
            .store(in: &cancellables)
    }

    func textChanged(_ text: String, modelCode: String?, client: FreeToken) {
        currentText = text
        textPublisher.send(text)
        currentModelCode = modelCode
        currentClient = client
    }

    func clearText() {
        currentText = ""
        tokenCount = 0
        errorMessage = nil
    }

    private var currentModelCode: String?
    private weak var currentClient: FreeToken?

    private func updateTokenCount(for text: String) {
        guard !text.isEmpty else {
            tokenCount = 0
            errorMessage = nil
            return
        }

        guard let client = currentClient else { return }

        isCounting = true
        errorMessage = nil

        Task {
            do {
                let count = try await client.countTokens(
                    text: text,
                    modelCode: currentModelCode
                )

                await MainActor.run {
                    self.tokenCount = count
                    self.isCounting = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Error counting tokens: \(error.localizedDescription)"
                    self.isCounting = false
                }
            }
        }
    }
}

// Completely isolated text editor to prevent re-renders
struct IsolatedTextEditor: View {
    let onTextChange: (String) -> Void
    @State private var text: String = ""
    @Binding var shouldClear: Bool

    var body: some View {
        TextEditor(text: $text)
            .font(.system(.body, design: .monospaced))
            .padding(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(.separator), lineWidth: 1)
            )
            .frame(minHeight: 200)
            .onChange(of: text) { newText in
                onTextChange(newText)
            }
            .onChange(of: shouldClear) { clear in
                if clear {
                    text = ""
                    shouldClear = false
                }
            }
    }
}

struct TokenCounterView: View {
    @Binding var isPresented: Bool
    let freeTokenClient: FreeTokenClient

    // Model selection
    @State private var availableModels: [FreeToken.AIModel] = []
    @State private var downloadedModels: [FreeToken.AIModel] = []
    @State private var selectedModelCode: String?
    @State private var isLoadingModels: Bool = true
    @State private var shouldClearText: Bool = false

    // Token counting in separate object
    @StateObject private var tokenCounter = TokenCounterViewModel()

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                // Model selector
                VStack(alignment: .leading, spacing: 8) {
                    Text("Select Model")
                        .font(.headline)
                        .foregroundColor(.primary)

                    if isLoadingModels {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Loading models...")
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                    } else if downloadedModels.isEmpty {
                        Text("No downloaded models available")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 8)
                    } else {
                        Picker("Model", selection: $selectedModelCode) {
                            Text("Default Model").tag(nil as String?)
                            ForEach(downloadedModels, id: \.code) { model in
                                Text(model.name).tag(model.code as String?)
                            }
                        }
                        .pickerStyle(.menu)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 12)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .onChange(of: selectedModelCode) { _ in
                            // Recount tokens when model changes
                            if !tokenCounter.currentText.isEmpty {
                                tokenCounter.textChanged(tokenCounter.currentText, modelCode: selectedModelCode, client: freeTokenClient.client)
                            }
                        }
                    }
                }

                Divider()

                Text("Enter text to count tokens")
                    .font(.headline)
                    .foregroundColor(.primary)

                // Completely isolated text editor
                IsolatedTextEditor(
                    onTextChange: { newText in
                        tokenCounter.textChanged(newText, modelCode: selectedModelCode, client: freeTokenClient.client)
                    },
                    shouldClear: $shouldClearText
                )

                // Token count display - isolated to prevent TextEditor re-renders
                TokenCountDisplay(
                    tokenCount: tokenCounter.tokenCount,
                    isCounting: tokenCounter.isCounting,
                    errorMessage: tokenCounter.errorMessage,
                    inputText: tokenCounter.currentText,
                    selectedModelCode: selectedModelCode
                )

                // Clear button
                if !tokenCounter.currentText.isEmpty {
                    Button(action: {
                        shouldClearText = true
                        tokenCounter.clearText()
                    }) {
                        Label("Clear Text", systemImage: "trash")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(.orange)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Token Counter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
            .onAppear {
                Task {
                    await loadAvailableModels()
                }
            }
        }
    }

    private func loadAvailableModels() async {
        isLoadingModels = true

        // Get all available models
        await freeTokenClient.client.listAIModels(
            success: { models in
                Task {
                    // Filter to get only downloaded models
                    var downloaded: [FreeToken.AIModel] = []

                    for model in models {
                        if !model.cloudOnly {
                            do {
                                let state = try await freeTokenClient.client.getAIModelDownloadState(modelCode: model.code)
                                if state == .downloaded {
                                    downloaded.append(model)
                                }
                            } catch {
                                print("Failed to check download state for model \(model.code): \(error)")
                            }
                        }
                    }

                    await MainActor.run {
                        self.availableModels = models
                        self.downloadedModels = downloaded
                        self.isLoadingModels = false

                        // Select the first downloaded model by default if available
                        if !downloaded.isEmpty && selectedModelCode == nil {
                            selectedModelCode = nil // Use default model initially
                        }
                    }
                }
            },
            error: { error in
                await MainActor.run {
                    self.tokenCounter.errorMessage = "Failed to load models: \(error.message)"
                    self.isLoadingModels = false
                }
            }
        )
    }

}

// Separate view for token count display to isolate re-renders
struct TokenCountDisplay: View {
    let tokenCount: Int
    let isCounting: Bool
    let errorMessage: String?
    let inputText: String
    let selectedModelCode: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if isCounting {
                    ProgressView()
                        .scaleEffect(0.8)
                }

                if tokenCount > 0 || !inputText.isEmpty {
                    Text("\(tokenCount) tokens")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.accentColor)
                } else {
                    Text("Start typing to count tokens")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }

                Spacer()

                if let modelCode = selectedModelCode {
                    Text("(\(modelCode))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 8)

            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal, 8)
            }
        }
    }
}