import SwiftUI
import SwiftData
import MarkdownUI
import FreeToken

struct ChatView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var inputMessage = ""
    @State private var showDeleteResetDialog = false
    @State private var chatThread: ChatThread? = nil
    @ObservedObject var chatLoader: ChatViewModel
    @State private var isCreatingThread = false
    @State private var showConfigControls = true
    @FocusState private var focusedConfigField: ConfigField?

    private enum ConfigField {
        case maxTokens, contextSize, temperature, topK, topP, documentSearch, privateStores, additionalContext
    }
    
    private struct ScrollState {
        var shouldScrollToBottom: Bool = false
        var lastMessageId: String? = nil
    }

    @State private var scrollState = ScrollState()
    
    private var disabledInputMessage: String {
        if chatThread != nil && chatThread?.freeTokenThreadId == nil {
            return "Initializing chat thread..."
        }

        return ""
    }
    
    init(chatLoader: ChatViewModel) {
        self.chatLoader = chatLoader
    }
    
    var body: some View {
        ZStack {
            VStack {
                // Model selector at the top
                modelSelectorView()
                Divider()
                chatContentView()
                Divider()

                // Status display
                if let status = chatLoader.currentChatStatus {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text(status)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .animation(.easeInOut(duration: 0.2), value: status)
                }

                // Token usage stats display - single line with horizontal scroll
                if let tokenUsage = chatLoader.lastTokenUsage {
                    HStack(spacing: 0) {
                        Text("Stats")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                            .padding(.leading, 16)
                            .padding(.trailing, 8)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                // Tokens per second
                                if tokenUsage.tokensPerSecond > 0 {
                                    HStack(spacing: 3) {
                                        Image(systemName: "speedometer")
                                            .font(.caption2)
                                        Text("Speed:")
                                            .font(.caption2)
                                        Text("\(String(format: "%.1f", tokenUsage.tokensPerSecond)) t/s")
                                            .font(.caption2)
                                            .fontWeight(.medium)
                                    }
                                }

                                // Total tokens
                                if tokenUsage.totalTokens > 0 {
                                    HStack(spacing: 3) {
                                        Image(systemName: "number.square")
                                            .font(.caption2)
                                        Text("Total:")
                                            .font(.caption2)
                                        Text("\(tokenUsage.totalTokens)")
                                            .font(.caption2)
                                            .fontWeight(.medium)
                                    }
                                }

                                // Input tokens
                                if tokenUsage.inputTokens > 0 {
                                    HStack(spacing: 3) {
                                        Image(systemName: "arrow.down.square")
                                            .font(.caption2)
                                        Text("In:")
                                            .font(.caption2)
                                        Text("\(tokenUsage.inputTokens)")
                                            .font(.caption2)
                                            .fontWeight(.medium)
                                    }
                                }

                                // Output tokens
                                if tokenUsage.outputTokens > 0 {
                                    HStack(spacing: 3) {
                                        Image(systemName: "arrow.up.square")
                                            .font(.caption2)
                                        Text("Out:")
                                            .font(.caption2)
                                        Text("\(tokenUsage.outputTokens)")
                                            .font(.caption2)
                                            .fontWeight(.medium)
                                    }
                                }

                                // Model code
                                if !tokenUsage.modelCode.isEmpty {
                                    HStack(spacing: 3) {
                                        Image(systemName: "cpu")
                                            .font(.caption2)
                                        Text("Model:")
                                            .font(.caption2)
                                        Text(tokenUsage.modelCode)
                                            .font(.caption2)
                                            .fontWeight(.medium)
                                    }
                                }

                                // Confidence
                                if let confidence = tokenUsage.confidence {
                                    HStack(spacing: 3) {
                                        Image(systemName: "checkmark.shield")
                                            .font(.caption2)
                                        Text("Conf:")
                                            .font(.caption2)
                                        Text("\(String(format: "%.1f%%", confidence * 100))")
                                            .font(.caption2)
                                            .fontWeight(.medium)
                                    }
                                }

                                // Perplexity
                                if let perplexity = tokenUsage.perplexity {
                                    HStack(spacing: 3) {
                                        Image(systemName: "chart.line.uptrend.xyaxis")
                                            .font(.caption2)
                                        Text("Perp:")
                                            .font(.caption2)
                                        Text("\(String(format: "%.2f", perplexity))")
                                            .font(.caption2)
                                            .fontWeight(.medium)
                                    }
                                }
                            }
                            .padding(.trailing, 16)
                        }
                    }
                    .frame(height: 36)
                    .foregroundColor(.secondary)
                    .background(Color(.systemGray6).opacity(0.5))
                    .transition(.opacity.combined(with: .scale))
                }

                InputMessageView(
                    inputMessage: $inputMessage,
                    isLoading: chatLoader.responseStatus == .streamingTokens || chatLoader.currentChatStatus != nil,
                    disabledMessage: disabledInputMessage,
                    sendMessage: {
                        let message = inputMessage
                        inputMessage = ""  // Clear immediately
                        Task {
                            await sendMessage(message)
                        }
                    },
                    cancelGeneration: {
                        chatLoader.cancelGeneration()
                    }
                )
            }
            .navigationTitle("AI Chat")
            .toolbar { toolbarContent }
            .confirmationDialog("Resetting Chat Options", isPresented: $showDeleteResetDialog, titleVisibility: .visible) {
                confirmationDialogContent()
            }
            .sheet(isPresented: $chatLoader.showToolResponseModal) {
                if let toolCall = chatLoader.pendingToolCall {
                    ToolCallResponseView(
                        toolCall: toolCall,
                        isPresented: $chatLoader.showToolResponseModal,
                        onSubmit: { response in
                            chatLoader.submitToolResponse(response)
                        }
                    )
                }
            }
            .onAppear {
                handleOnAppear()
            }
            .onDisappear {
                handleOnDisappear()
            }
            if isCreatingThread {
                Color.black.opacity(0.2)
                    .ignoresSafeArea()
                ProgressView("Creating new chat...")
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(.white)))
                    .shadow(radius: 10)
            }
        }
    }

    // Internal Extracted Views & View Helpers
    @ViewBuilder
    private func modelSelectorView() -> some View {
        let isGenerating = chatLoader.responseStatus == .streamingTokens || chatLoader.isLoading || chatLoader.currentChatStatus != nil

        // Auto-hide controls when generation starts, show for new chats
        let _ = {
            if isGenerating && showConfigControls {
                DispatchQueue.main.async {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showConfigControls = false
                    }
                }
            }
        }()

        VStack(spacing: 12) {
            HStack {
                Text("AI Model:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Menu {
                Button(action: {
                    chatLoader.selectedModelCode = nil
                    // Regenerate UUID and prewarm for default model
                    chatLoader.resetRunIdentifier()
                    Task {
                        // Tool masking will be applied during prewarmChat based on toolsEnabled
                        await chatLoader.prewarmChat()
                    }
                }) {
                    Label("Default Agent Model", systemImage: chatLoader.selectedModelCode == nil ? "checkmark" : "")
                }

                Divider()

                // Add ScrollViewReader for better control on small screens
                Section {
                    ForEach(chatLoader.availableModels, id: \.code) { model in
                        Button(action: {
                            chatLoader.selectedModelCode = model.code
                            // Regenerate UUID and prewarm with new model (skip for cloud-only models)
                            chatLoader.resetRunIdentifier()
                            if !model.cloudOnly {
                                Task {
                                    // Tool masking will be applied during prewarmChat based on toolsEnabled
                                    await chatLoader.prewarmChat(overrideModelCode: model.code)
                                }
                            }
                        }) {
                            HStack {
                                // Download status icon
                                Group {
                                    if chatLoader.modelDownloadStates[model.code] == .downloaded {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                            .font(.system(size: 14))
                                    } else if model.cloudOnly {
                                        Image(systemName: "cloud.fill")
                                            .foregroundColor(.blue)
                                            .font(.system(size: 14))
                                    }
                                }

                                // Model name
                                Text(model.name)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8) // Allow text to scale down if needed

                                Spacer()

                                // Selection checkmark
                                if chatLoader.selectedModelCode == model.code {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 14))
                                        .foregroundColor(.primary)
                                }
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    // Show icon for selected model's download status
                    if let selectedModel = chatLoader.availableModels.first(where: { $0.code == chatLoader.selectedModelCode }) {
                        if chatLoader.modelDownloadStates[selectedModel.code] == .downloaded {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.system(size: 12))
                        } else if selectedModel.cloudOnly {
                            Image(systemName: "cloud.fill")
                                .foregroundColor(.blue)
                                .font(.system(size: 12))
                        }
                    }

                    Text(chatLoader.selectedModelCode != nil ?
                         chatLoader.availableModels.first(where: { $0.code == chatLoader.selectedModelCode })?.name ?? "Unknown Model" :
                         "Default Agent Model")
                        .font(.subheadline)
                        .lineLimit(1)
                    Image(systemName: "chevron.down")
                        .font(.caption)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
            .menuStyle(DefaultMenuStyle()) // Ensure proper menu presentation on iOS
            .disabled(isGenerating)
            .opacity(isGenerating ? 0.6 : 1.0)

            if isGenerating {
                ProgressView()
                    .scaleEffect(0.7)
                    .padding(.leading, 4)
            }

            Spacer()

            // Toggle button for config controls - always visible
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showConfigControls.toggle()
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: showConfigControls ? "chevron.up.circle" : "chevron.down.circle")
                        .font(.system(size: 16))
                    Text(showConfigControls ? "Hide Config" : "Show Config")
                        .font(.caption)
                }
                .foregroundColor(.accentColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(.systemGray6).opacity(0.5))
                .cornerRadius(6)
            }
            .buttonStyle(PlainButtonStyle())
        }

        // Document Search and Context Settings - always visible when showConfigControls is true
        if showConfigControls {
            VStack(alignment: .leading, spacing: 8) {
                // Document Search Scope
                HStack {
                    Text("Document Search Scope:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 160, alignment: .leading)
                    TextField("Search scope...", text: $chatLoader.documentSearchScope)
                        .textFieldStyle(.roundedBorder)
                        .font(.caption)
                        .focused($focusedConfigField, equals: .documentSearch)
                }

                // Private Document Store IDs
                HStack {
                    Text("Private Document Store IDs:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 160, alignment: .leading)
                    TextField("Store IDs (comma-separated)...", text: $chatLoader.privateDocumentStoreIds)
                        .textFieldStyle(.roundedBorder)
                        .font(.caption)
                        .focused($focusedConfigField, equals: .privateStores)
                }

                // Additional Context
                VStack(alignment: .leading, spacing: 4) {
                    Text("Additional Context:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextEditor(text: $chatLoader.additionalContext)
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
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(Color(.systemGray6).opacity(0.3))
            .cornerRadius(8)
            .transition(.asymmetric(
                insertion: .move(edge: .top).combined(with: .opacity),
                removal: .move(edge: .top).combined(with: .opacity)
            ))
        }

        // Tools Toggle - show when config controls are visible and no thread exists
        if showConfigControls && chatThread?.freeTokenThreadId == nil {
            HStack {
                Text("Tools:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Toggle(isOn: $chatLoader.toolsEnabled) {
                    Text(chatLoader.toolsEnabled ? "Enabled" : "Disabled")
                        .font(.subheadline)
                        .foregroundColor(chatLoader.toolsEnabled ? .green : .secondary)
                }
                .toggleStyle(SwitchToggleStyle(tint: .accentColor))
                .onChange(of: chatLoader.toolsEnabled) { oldValue, newValue in
                    Task {
                        await chatLoader.toggleTools()
                    }
                }

                Spacer()

                if chatLoader.toolsEnabled {
                    HStack(spacing: 4) {
                        Image(systemName: "wrench.and.screwdriver.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.orange)
                        Text("fetch_weather")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .transition(.asymmetric(
                insertion: .move(edge: .top).combined(with: .opacity),
                removal: .move(edge: .top).combined(with: .opacity)
            ))

            // AIRunConfig Toggle and Settings - show when config controls are visible and no thread exists
            if showConfigControls && chatThread?.freeTokenThreadId == nil {
                VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("AI Run Config:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Toggle(isOn: $chatLoader.aiRunConfigEnabled) {
                        Text(chatLoader.aiRunConfigEnabled ? "Custom" : "Default")
                            .font(.subheadline)
                            .foregroundColor(chatLoader.aiRunConfigEnabled ? .blue : .secondary)
                    }
                    .toggleStyle(SwitchToggleStyle(tint: .accentColor))
                    .onChange(of: chatLoader.aiRunConfigEnabled) { oldValue, newValue in
                        Task {
                            await chatLoader.aiRunConfigChanged()
                        }
                    }

                    Spacer()
                }

                // Show config options when enabled
                if chatLoader.aiRunConfigEnabled {
                    VStack(alignment: .leading, spacing: 8) {
                        // Max Generation Tokens
                        HStack {
                            Text("Max Tokens:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(width: 100, alignment: .leading)
                            TextField("2048", value: $chatLoader.maxGenerationTokens, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .font(.caption)
                                .frame(width: 80)
                                .focused($focusedConfigField, equals: .maxTokens)
                                .onSubmit {
                                    Task { await chatLoader.aiRunConfigChanged() }
                                }
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
                            TextField("4096", value: $chatLoader.contextWindowSize, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .font(.caption)
                                .frame(width: 80)
                                .focused($focusedConfigField, equals: .contextSize)
                                .onSubmit {
                                    Task { await chatLoader.aiRunConfigChanged() }
                                }
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
                            TextField("0.7", value: $chatLoader.temperature, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .font(.caption)
                                .frame(width: 80)
                                .focused($focusedConfigField, equals: .temperature)
                                .onSubmit {
                                    Task { await chatLoader.aiRunConfigChanged() }
                                }
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
                            TextField("40", value: $chatLoader.topK, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .font(.caption)
                                .frame(width: 80)
                                .focused($focusedConfigField, equals: .topK)
                                .onSubmit {
                                    Task { await chatLoader.aiRunConfigChanged() }
                                }
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
                            TextField("0.95", value: $chatLoader.topP, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .font(.caption)
                                .frame(width: 80)
                                .focused($focusedConfigField, equals: .topP)
                                .onSubmit {
                                    Task { await chatLoader.aiRunConfigChanged() }
                                }
                            Text("(0.0-1.0)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(Color(.systemGray6).opacity(0.5))
                    .cornerRadius(8)
                }
            }
            .onChange(of: focusedConfigField) { oldField, newField in
                // Only trigger aiRunConfigChanged for AI Run Config fields, not document fields
                let aiConfigFields: Set<ConfigField> = [.maxTokens, .contextSize, .temperature, .topK, .topP]

                // When focus changes from an AI config field to nil or another field, trigger update
                if let oldField = oldField, aiConfigFields.contains(oldField) && oldField != newField {
                    Task { await chatLoader.aiRunConfigChanged() }
                }
            }
            .transition(.asymmetric(
                insertion: .move(edge: .top).combined(with: .opacity),
                removal: .move(edge: .top).combined(with: .opacity)
            ))
            }
        }
    }
    .padding(.horizontal)
    .padding(.vertical, 8)
    }

    @ViewBuilder
    private func chatContentView() -> some View {
        if chatLoader.messages.isEmpty {
            emptyViewState()
        } else {
            MessageListView(
                chatLoader: chatLoader,
                lastMessageId: $scrollState.lastMessageId,
                shouldScrollToBottom: $scrollState.shouldScrollToBottom,
                chatThread: $chatThread
            )
        }
    }
    
    @ViewBuilder
    private func emptyViewState() -> some View {
        renderContentUnavailableView(label: "No Messages", systemImage: "bubble.left", text: "Start a conversation with FreeToken AI")
    }
    
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            HStack(spacing: 20) {
                if !chatLoader.messages.isEmpty {
                    Button(action: {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        showDeleteResetDialog = true
                    }) {
                        Image(systemName: "trash")
                            .font(.system(size: 17))
                            .foregroundColor(.primary)
                    }
                }
                Button(action: { ExampleAppLogger.shared.dumpAllLogs() }) {
                    Image(systemName: "ladybug")
                        .font(.system(size: 17))
                        .foregroundColor(.primary)
                }
            }
        }
    }
    
    @ViewBuilder
    private func confirmationDialogContent() -> some View {
        Button("Reset Chat", role: .none) {
            resetChat()
        }
        Button("Delete and Reset Chat", role: .destructive) {
            deleteChat()
        }
        Button("Cancel", role: .cancel) { }
    }
    
    // Called when the view appears. Handles thread initialization
    private func handleOnAppear() {
        // Set initial state of config controls based on whether chat is empty
        showConfigControls = chatLoader.messages.isEmpty

        // Prewarm the AI model for this chat session
        Task {
            // Always register the weather tool when view loads
            // Tool masking will control whether it's actually used
            await chatLoader.registerWeatherTool()
            await chatLoader.prewarmChat()
            // Load available AI models
            await chatLoader.loadAIModels()
        }

        if let thread = chatThread {
            ExampleAppLogger.shared.log("💬 ChatView.onAppear", threadID: thread.freeTokenThreadId)

            if thread.freeTokenThreadId == nil {
                ExampleAppLogger.shared.log("💬 ChatView.onAppear: No FreeToken thread ID found, will create when user sends first message")
                // Don't create thread automatically - wait for first message
            } else {
                ExampleAppLogger.shared.log("💬 ChatView.onAppear: Found existing FreeToken thread ID.", threadID: thread.freeTokenThreadId)
            }
        } else {
            ExampleAppLogger.shared.log("💬 ChatView.onAppear for new chat (no thread yet)")
        }
    }
    
    private func handleOnDisappear() {
        if let thread = chatThread {
            ExampleAppLogger.shared.log("💬 ChatView.onDisappear: Leaving chat thread \(thread.id)", threadID: chatThread?.freeTokenThreadId)
        } else {
            ExampleAppLogger.shared.log("💬 ChatView.onDisappear: Leaving new chat (no thread created)")
        }
    }
    
    // Helper functions
    // Creates a new FreeToken chat thread and updates the local model
    private func createFreeTokenThread(completion: (() -> Void)? = nil) {
        // Check if thread already exists AND has a FreeToken ID
        if chatThread != nil && chatThread?.freeTokenThreadId != nil {
            Task { await MainActor.run { completion?() } }
            return
        }

        ExampleAppLogger.shared.log("💬 createFreeTokenThread: Starting thread creation")

        // Only create new thread if it doesn't exist
        if chatThread == nil {
            let newThread = ChatThread()
            modelContext.insert(newThread)
            self.chatThread = newThread
        }

        Task {
            let thread = await chatLoader.createMessageThread()
            await MainActor.run {
                if let thread = thread {
                    // New thread was created
                    self.chatThread?.freeTokenThreadId = thread.id
                    self.chatThread?.updatedAt = Date()
                } else if let existingThreadID = chatLoader.messageThreadID {
                    // Using existing thread from FreeTokenClient
                    self.chatThread?.freeTokenThreadId = existingThreadID
                    self.chatThread?.updatedAt = Date()
                }
            }

            await MainActor.run { completion?() }
        }
    }
    
    private func renderContentUnavailableView(label: String, systemImage: String, text: String) -> some View {
        ContentUnavailableView {
            Label(label, systemImage: systemImage)
        } description: { Text(text) }
        .frame(maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
    
    // Sends the user's message, ensuring a thread exists, and triggers AI response
    private func sendMessage(_ userMessageContent: String) async {

        // Ensure thread exists before sending
        if chatThread?.freeTokenThreadId == nil {
            await withCheckedContinuation { continuation in
                createFreeTokenThread {
                    continuation.resume()
                }
            }
        }

        // Send the message using the corrected API
        let isFirstMessage = chatLoader.messages.isEmpty
        await chatLoader.sendMessage(message: userMessageContent, isThreadFirstMessage: isFirstMessage)

        // Update thread preview after message is sent
        if let thread = chatThread {
            thread.previewContent = chatLoader.streamedResponse.isEmpty ? userMessageContent : chatLoader.streamedResponse
            thread.updatedAt = Date()
        }

    }
    
    // Runs the message thread, updates preview content, and handles scrolling and errors
    private func runThread() async {
        await runThreadWith(chatLoader: chatLoader,
                            threadID: chatThread?.freeTokenThreadId,
                            onUpdate: { content, date in
            if let thread = chatThread {
                thread.previewContent = content
                thread.updatedAt = date ?? Date()
            }
        },
                            onError: { error in
            chatLoader.setLastError(error)
        },
                            onScroll: {
            scrollState.shouldScrollToBottom = true
            ExampleAppLogger.shared.log("💬 runThread()runThreadWith() - Setting shouldScrollToBottom to: \(scrollState.shouldScrollToBottom))")
        }
        )
    }
    
    
    private func resetChat() {
        ExampleAppLogger.shared.log("💬 About to reset thread", threadID: chatThread?.freeTokenThreadId)
        isCreatingThread = true

        // Reset runIdentifier for the new chat session
        chatLoader.resetRunIdentifier()

        // Store selected model, tools state, and AIRunConfig before clearing
        let selectedModel = chatLoader.selectedModelCode
        let toolsEnabled = chatLoader.toolsEnabled
        let aiRunConfigEnabled = chatLoader.aiRunConfigEnabled
        let maxTokens = chatLoader.maxGenerationTokens
        let contextSize = chatLoader.contextWindowSize
        let topK = chatLoader.topK
        let topP = chatLoader.topP
        let temperature = chatLoader.temperature
        let docSearchScope = chatLoader.documentSearchScope
        let privateDocStoreIds = chatLoader.privateDocumentStoreIds
        let additionalCtx = chatLoader.additionalContext

        // Clear current thread and messages
        withAnimation(.easeInOut(duration: 0.6)) {
            chatThread = nil
            chatLoader.messages.removeAll()
            chatLoader.lastError = nil
            chatLoader.lastTokenUsage = nil
            chatLoader.responseStatus = .starting
            chatLoader.currentChatStatus = nil
            inputMessage = ""
            // Clear the thread IDs to ensure a new thread is created
            chatLoader.clearMessageThreadID()
            // Restore selected model, tools state, and AIRunConfig
            chatLoader.selectedModelCode = selectedModel
            chatLoader.toolsEnabled = toolsEnabled
            chatLoader.aiRunConfigEnabled = aiRunConfigEnabled
            chatLoader.maxGenerationTokens = maxTokens
            chatLoader.contextWindowSize = contextSize
            chatLoader.topK = topK
            chatLoader.topP = topP
            chatLoader.temperature = temperature
            chatLoader.documentSearchScope = docSearchScope
            chatLoader.privateDocumentStoreIds = privateDocStoreIds
            chatLoader.additionalContext = additionalCtx
            // Show config controls for new chat
            showConfigControls = true
        }

        // Don't create a thread immediately - wait for first message
        // This allows the tools toggle to remain visible
        withAnimation(.easeInOut(duration: 0.6)) { isCreatingThread = false }

        ExampleAppLogger.shared.log("✅ Successfully reset chat", threadID: nil)

        // Prewarm the AI for the new chat session (will use tool masking based on toolsEnabled)
        Task {
            // Tool masking will be applied during prewarmChat based on toolsEnabled
            await chatLoader.prewarmChat()
        }
    }
    
    private func deleteChat() {
        ExampleAppLogger.shared.log("💬 About to delete all chats from thread", threadID: chatThread?.freeTokenThreadId)
        let threadID = chatThread?.freeTokenThreadId
        
        Task {
            let deletion = await chatLoader.deleteMessageThread(threadID: threadID)
            if deletion {
                await MainActor.run { resetChat() }
            } else {
                ExampleAppLogger.shared.log("❌ Failed to delete message thread", threadID: threadID)
            }
        }
        
    }
}
