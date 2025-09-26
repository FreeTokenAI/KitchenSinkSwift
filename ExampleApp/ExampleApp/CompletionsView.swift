import SwiftUI
import FreeToken

struct CompletionsView: View {
    @ObservedObject var freeTokenClient: FreeTokenClient

    // Main text input
    @State private var inputText = ""

    // Model selection
    @State private var selectedModelCode: String? = nil
    @State private var availableModels: [FreeToken.AIModel] = []
    @State private var modelDownloadStates: [String: FreeToken.ModelDownloadState] = [:]
    @State private var isLoadingModels = false

    // AIRunConfig
    @State private var aiRunConfigEnabled = false
    @State private var maxGenerationTokens = 2048
    @State private var contextWindowSize = 4096
    @State private var temperature: Float = 0.7
    @State private var topK = 40
    @State private var topP: Float = 0.95
    @State private var documentSearchScope = ""
    @State private var privateDocumentStoreIds = ""
    @State private var additionalContext = ""

    // Generation state
    @State private var isGenerating = false
    @State private var showingCompletionModal = false
    @State private var completionText = ""
    @State private var streamedTokens = ""
    @State private var tokenUsageStats: TokenUsage?
    @State private var generationStartTime: Date?
    @State private var currentTokenCount = 0

    // Focus state
    @FocusState private var focusedConfigField: ConfigField?

    private enum ConfigField {
        case maxTokens, contextSize, temperature, topK, topP, documentSearch, privateStores, additionalContext
    }

    // Token usage tracking
    private struct TokenUsage {
        let totalTokens: Int
        let tokensPerSecond: Double
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Model selector
                modelSelectorView()

                Divider()

                ScrollView {
                    VStack(spacing: 16) {
                        // Input text area
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Enter text to complete:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            TextEditor(text: $inputText)
                                .font(.body)
                                .frame(minHeight: 150, maxHeight: 300)
                                .padding(8)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color(.systemGray4), lineWidth: 0.5)
                                )
                                .overlay(
                                    Group {
                                        if inputText.isEmpty {
                                            Text("Hybrid AI is...")
                                                .foregroundColor(.gray.opacity(0.5))
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 16)
                                                .allowsHitTesting(false)
                                        }
                                    },
                                    alignment: .topLeading
                                )
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)

                        // AIRunConfig section
                        aiRunConfigSection()

                        // Complete button
                        Button(action: {
                            Task {
                                await performCompletion()
                            }
                        }) {
                            HStack {
                                Image(systemName: "sparkles")
                                Text("Complete Text")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(inputText.isEmpty || isGenerating ? Color.gray : Color.blue)
                            .cornerRadius(12)
                        }
                        .disabled(inputText.isEmpty || isGenerating)
                        .padding(.horizontal)
                        .padding(.bottom)
                    }
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("Completions")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                Task {
                    await loadModels()
                }
            }
        }
        .sheet(isPresented: $showingCompletionModal) {
            completionModalView()
        }
    }

    // MARK: - Model Selector View
    @ViewBuilder
    private func modelSelectorView() -> some View {
        HStack {
            Menu {
                Button("Default Agent Model") {
                    selectedModelCode = nil
                }

                Divider()

                ForEach(availableModels, id: \.code) { model in
                    Button(action: {
                        selectedModelCode = model.code
                    }) {
                        HStack {
                            Text(model.name)
                            if !model.cloudOnly && modelDownloadStates[model.code] == .downloaded {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            } else if model.cloudOnly {
                                Image(systemName: "cloud.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    if let code = selectedModelCode,
                       let model = availableModels.first(where: { $0.code == code }) {
                        if !model.cloudOnly && modelDownloadStates[model.code] == .downloaded {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.system(size: 12))
                        } else if model.cloudOnly {
                            Image(systemName: "cloud.fill")
                                .foregroundColor(.blue)
                                .font(.system(size: 12))
                        }
                    }

                    Text(selectedModelCode != nil ?
                         availableModels.first(where: { $0.code == selectedModelCode })?.name ?? "Unknown Model" :
                         "Default Agent Model")
                        .font(.subheadline)
                        .lineLimit(1)

                    Image(systemName: "chevron.down")
                        .font(.caption)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
            .disabled(isGenerating || isLoadingModels)

            if isLoadingModels {
                ProgressView()
                    .scaleEffect(0.7)
            }

            Spacer()
        }
        .padding()
    }

    // MARK: - AIRunConfig Section
    @ViewBuilder
    private func aiRunConfigSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("AI Run Config:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Toggle(isOn: $aiRunConfigEnabled) {
                    Text(aiRunConfigEnabled ? "Custom" : "Default")
                        .font(.subheadline)
                        .foregroundColor(aiRunConfigEnabled ? .blue : .secondary)
                }
                .toggleStyle(SwitchToggleStyle(tint: .accentColor))

                Spacer()
            }

            if aiRunConfigEnabled {
                VStack(alignment: .leading, spacing: 10) {
                    // Max Generation Tokens
                    HStack {
                        Text("Max Tokens:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 100, alignment: .leading)

                        TextField("2048", value: $maxGenerationTokens, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .font(.caption)
                            .frame(width: 80)
                            .focused($focusedConfigField, equals: .maxTokens)

                        Text("(128-8192)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    // Context Window Size
                    HStack {
                        Text("Context Size:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 100, alignment: .leading)

                        TextField("4096", value: $contextWindowSize, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .font(.caption)
                            .frame(width: 80)
                            .focused($focusedConfigField, equals: .contextSize)

                        Text("(512-32768)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    // Temperature
                    HStack {
                        Text("Temperature:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 100, alignment: .leading)

                        TextField("0.7", value: $temperature, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .font(.caption)
                            .frame(width: 80)
                            .focused($focusedConfigField, equals: .temperature)

                        Text("(0.0-2.0)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    // Top-K
                    HStack {
                        Text("Top-K:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 100, alignment: .leading)

                        TextField("40", value: $topK, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .font(.caption)
                            .frame(width: 80)
                            .focused($focusedConfigField, equals: .topK)

                        Text("(1-100)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    // Top-P
                    HStack {
                        Text("Top-P:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 100, alignment: .leading)

                        TextField("0.95", value: $topP, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .font(.caption)
                            .frame(width: 80)
                            .focused($focusedConfigField, equals: .topP)

                        Text("(0.0-1.0)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    // Document Search Scope
                    HStack {
                        Text("Document Search:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 100, alignment: .leading)

                        TextField("Search scope...", text: $documentSearchScope)
                            .textFieldStyle(.roundedBorder)
                            .font(.caption)
                            .focused($focusedConfigField, equals: .documentSearch)
                    }

                    // Private Document Store IDs
                    HStack {
                        Text("Private Stores:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 100, alignment: .leading)

                        TextField("Store IDs (comma-separated)...", text: $privateDocumentStoreIds)
                            .textFieldStyle(.roundedBorder)
                            .font(.caption)
                            .focused($focusedConfigField, equals: .privateStores)
                    }

                    // Additional Context
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Additional Context:")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        TextEditor(text: $additionalContext)
                            .font(.caption)
                            .frame(minHeight: 60, maxHeight: 100)
                            .padding(4)
                            .background(Color(.systemGray6))
                            .cornerRadius(4)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color(.systemGray4), lineWidth: 0.5)
                            )
                            .focused($focusedConfigField, equals: .additionalContext)
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color(.systemGray6).opacity(0.5))
                .cornerRadius(8)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Completion Modal View
    @ViewBuilder
    private func completionModalView() -> some View {
        NavigationStack {
            VStack {
                // Streamed text display
                ScrollViewReader { scrollProxy in
                    ScrollView {
                        Text(streamedTokens)
                            .font(.body)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .id("completionText")
                    }
                    .onChange(of: streamedTokens) { _, _ in
                        withAnimation {
                            scrollProxy.scrollTo("completionText", anchor: .bottom)
                        }
                    }
                }

                Divider()

                // Token stats - show during generation and after
                if isGenerating || tokenUsageStats != nil {
                    HStack(spacing: 16) {
                        if let stats = tokenUsageStats {
                            HStack(spacing: 4) {
                                Image(systemName: "speedometer")
                                    .font(.system(size: 14))
                                    .foregroundColor(.blue)
                                Text("\(String(format: "%.1f", stats.tokensPerSecond)) tokens/sec")
                                    .font(.system(size: 14, weight: .medium))
                            }

                            Spacer()

                            HStack(spacing: 4) {
                                Image(systemName: "number.square")
                                    .font(.system(size: 14))
                                    .foregroundColor(.green)
                                Text("Total: \(stats.totalTokens)")
                                    .font(.system(size: 14, weight: .medium))
                            }
                        } else if isGenerating {
                            // Show loading state while waiting for first token
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Starting generation...")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                }

                // Cancel/Clear button
                Button(action: {
                    if isGenerating {
                        // Cancel generation
                        isGenerating = false
                    } else {
                        // Clear and close
                        streamedTokens = ""
                        tokenUsageStats = nil
                        currentTokenCount = 0
                        generationStartTime = nil
                        showingCompletionModal = false
                    }
                }) {
                    HStack {
                        Image(systemName: isGenerating ? "xmark.circle" : "trash")
                        Text(isGenerating ? "Cancel Generation" : "Clear")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isGenerating ? Color.red : Color.blue)
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("Text Completion")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showingCompletionModal = false
                        streamedTokens = ""
                        tokenUsageStats = nil
                        currentTokenCount = 0
                        generationStartTime = nil
                    }
                }
            }
        }
    }

    // MARK: - Helper Methods
    private func loadModels() async {
        isLoadingModels = true

        await freeTokenClient.client.listAIModels(
            success: { models in
                await MainActor.run {
                    self.availableModels = models
                    self.isLoadingModels = false
                }
                await self.checkModelDownloadStates(for: models)
            },
            error: { error in
                ExampleAppLogger.shared.log("Error loading AI models: \(error)", level: .error)
                await MainActor.run {
                    self.isLoadingModels = false
                }
            }
        )
    }

    private func performCompletion() async {
        guard !inputText.isEmpty else { return }

        streamedTokens = ""
        tokenUsageStats = nil
        currentTokenCount = 0
        generationStartTime = Date()
        isGenerating = true
        showingCompletionModal = true

        // Build AIRunConfig if enabled
        var config: FreeToken.AIRunConfig? = nil
        if aiRunConfigEnabled {
            config = FreeToken.AIRunConfig(
                maxGenerationTokens: maxGenerationTokens,
                contentWindowSize: contextWindowSize,
                topK: topK,
                topP: topP,
                temperature: temperature
            )
        }

        // Note: Document search scope, private document stores, and additional context
        // are not part of AIRunConfig - they are parameters to generateCompletion
        // For now, we won't use these in the completions API as they're specific to chat

        await freeTokenClient.client.generateCompletion(
            prompt: inputText,
            modelCode: selectedModelCode,
            aiRunConfig: config,
            tokenStream: { token in
                guard self.isGenerating else { return }

                await MainActor.run {
                    self.streamedTokens += token
                    self.currentTokenCount += 1

                    // Update stats live during generation
                    if let startTime = self.generationStartTime {
                        let elapsedTime = Date().timeIntervalSince(startTime)
                        if elapsedTime > 0 {
                            let tokensPerSecond = Double(self.currentTokenCount) / elapsedTime
                            self.tokenUsageStats = TokenUsage(
                                totalTokens: self.currentTokenCount,
                                tokensPerSecond: tokensPerSecond
                            )
                        }
                    }
                }
            },
            success: { completion in
                await MainActor.run {
                    // Update final stats if needed
                    if let startTime = self.generationStartTime {
                        let elapsedTime = Date().timeIntervalSince(startTime)
                        if elapsedTime > 0 {
                            let tokensPerSecond = Double(self.currentTokenCount) / elapsedTime
                            self.tokenUsageStats = TokenUsage(
                                totalTokens: self.currentTokenCount,
                                tokensPerSecond: tokensPerSecond
                            )
                        }
                    }
                    self.isGenerating = false
                    self.completionText = completion.response
                }
            },
            error: { error in
                ExampleAppLogger.shared.log("Error generating completion: \(error)", level: .error)
                await MainActor.run {
                    self.isGenerating = false
                    self.streamedTokens = "Error: \(error.message)"
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
                        modelDownloadStates[model.code] = state
                    }
                } catch {
                    // Ignore error and continue
                }
            }
        }
    }
}