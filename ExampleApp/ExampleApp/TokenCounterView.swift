import SwiftUI
import FreeToken
import Combine

// MARK: - Token Counter View Model
// Handles token counting functionality for estimating AI model usage
// Token counting helps predict costs and manage context window limits
// For telemetry and usage stats, see: https://docs.freetoken.ai/docs/guides/telemetry-stats
// For understanding performance optimization, see: https://docs.freetoken.ai/docs/guides/performance
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
            .foregroundColor(CyberpunkTheme.Colors.cyberCyan)
            .padding(8)
            .background(CyberpunkTheme.Colors.cyberPanel)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(CyberpunkTheme.Colors.cyberCyan.opacity(0.3), lineWidth: 1)
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
            ZStack {
                // Cyberpunk background
                CyberpunkTheme.Gradients.backgroundGradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Model selector
                        VStack(alignment: .leading, spacing: 8) {
                            Text("SELECT MODEL")
                                .font(.system(size: 14, weight: .bold))
                                .textCase(.uppercase)
                                .kerning(1.2)
                                .foregroundColor(CyberpunkTheme.Colors.cyberGold)

                            if isLoadingModels {
                                HStack {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .tint(CyberpunkTheme.Colors.cyberCyan)
                                    Text("LOADING MODELS...")
                                        .font(.system(size: 12, weight: .medium))
                                        .textCase(.uppercase)
                                        .kerning(0.8)
                                        .foregroundColor(CyberpunkTheme.Colors.cyberCyan)
                                }
                                .padding(.vertical, 8)
                            } else if downloadedModels.isEmpty {
                                Text("NO DOWNLOADED MODELS AVAILABLE")
                                    .font(.system(size: 11, weight: .medium))
                                    .textCase(.uppercase)
                                    .kerning(0.8)
                                    .foregroundColor(CyberpunkTheme.Colors.cyberMagenta)
                                    .padding(.vertical, 8)
                            } else {
                                Picker("Model", selection: $selectedModelCode) {
                                    Text("DEFAULT MODEL").tag(nil as String?)
                                    ForEach(downloadedModels, id: \.code) { model in
                                        Text(model.name.uppercased()).tag(model.code as String?)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(CyberpunkTheme.Colors.cyberCyan)
                                .padding(.vertical, 4)
                                .padding(.horizontal, 12)
                                .background(CyberpunkTheme.Colors.cyberPanel)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(CyberpunkTheme.Colors.cyberCyan.opacity(0.3), lineWidth: 1)
                                )
                                .onChange(of: selectedModelCode) { _ in
                                    // Recount tokens when model changes
                                    if !tokenCounter.currentText.isEmpty {
                                        tokenCounter.textChanged(tokenCounter.currentText, modelCode: selectedModelCode, client: freeTokenClient.client)
                                    }
                                }
                            }
                        }
                        .padding()
                        .cyberPanel()

                        Text("ENTER TEXT TO COUNT TOKENS")
                            .font(.system(size: 14, weight: .bold))
                            .textCase(.uppercase)
                            .kerning(1.2)
                            .foregroundColor(CyberpunkTheme.Colors.cyberGold)
                            .padding(.horizontal)

                        // Completely isolated text editor
                        IsolatedTextEditor(
                            onTextChange: { newText in
                                tokenCounter.textChanged(newText, modelCode: selectedModelCode, client: freeTokenClient.client)
                            },
                            shouldClear: $shouldClearText
                        )
                        .padding(.horizontal)

                        // Token count display - isolated to prevent TextEditor re-renders
                        TokenCountDisplay(
                            tokenCount: tokenCounter.tokenCount,
                            isCounting: tokenCounter.isCounting,
                            errorMessage: tokenCounter.errorMessage,
                            inputText: tokenCounter.currentText,
                            selectedModelCode: selectedModelCode
                        )
                        .padding(.horizontal)

                        // Clear button
                        if !tokenCounter.currentText.isEmpty {
                            Button(action: {
                                shouldClearText = true
                                tokenCounter.clearText()
                            }) {
                                Label("CLEAR TEXT", systemImage: "trash")
                                    .font(.system(size: 14, weight: .bold))
                                    .textCase(.uppercase)
                                    .kerning(1.2)
                                    .frame(maxWidth: .infinity)
                            }
                            .cyberButton()
                            .padding(.horizontal)
                        }

                        Spacer()
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("TOKEN COUNTER")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(CyberpunkTheme.Colors.cyberPanel, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("DONE") {
                        isPresented = false
                    }
                    .font(.system(size: 14, weight: .bold))
                    .textCase(.uppercase)
                    .kerning(1.2)
                    .foregroundColor(CyberpunkTheme.Colors.cyberGreen)
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
                        .tint(CyberpunkTheme.Colors.cyberCyan)
                }

                if tokenCount > 0 || !inputText.isEmpty {
                    Text("\(tokenCount) TOKENS")
                        .font(.system(size: 16, weight: .bold))
                        .textCase(.uppercase)
                        .kerning(1.5)
                        .foregroundColor(CyberpunkTheme.Colors.cyberCyan)
                        .neonGlow(color: CyberpunkTheme.Colors.cyberCyan, radius: 2)
                } else {
                    Text("START TYPING TO COUNT TOKENS")
                        .font(.system(size: 14, weight: .medium))
                        .textCase(.uppercase)
                        .kerning(1)
                        .foregroundColor(CyberpunkTheme.Colors.cyberBlueLight)
                }

                Spacer()

                if let modelCode = selectedModelCode {
                    Text("(\(modelCode.uppercased()))")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(CyberpunkTheme.Colors.cyberGold)
                }
            }
            .padding()
            .cyberPanel()

            if let error = errorMessage {
                Text(error.uppercased())
                    .font(.system(size: 11, weight: .medium))
                    .textCase(.uppercase)
                    .kerning(0.8)
                    .foregroundColor(.red)
                    .neonGlow(color: .red, radius: 2)
                    .padding()
                    .cyberPanel()
            }
        }
    }
}