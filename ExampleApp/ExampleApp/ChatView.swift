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

                // Token usage stats display
                if let tokenUsage = chatLoader.lastTokenUsage {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Stats")
                                .font(.caption)
                                .fontWeight(.semibold)
                            Spacer()
                        }

                        // Use a wrapping horizontal layout
                        FlowLayout(spacing: 12) {
                            // Tokens per second
                            if tokenUsage.tokensPerSecond > 0 {
                                HStack(spacing: 4) {
                                    Image(systemName: "speedometer")
                                        .font(.caption)
                                    Text("Speed:")
                                        .font(.caption)
                                    Text("\(String(format: "%.1f", tokenUsage.tokensPerSecond)) tokens/sec")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                                .fixedSize() // Prevent breaking within the stat
                            }

                            // Total tokens
                            if tokenUsage.totalTokens > 0 {
                                HStack(spacing: 4) {
                                    Image(systemName: "number.square")
                                        .font(.caption)
                                    Text("Total:")
                                        .font(.caption)
                                    Text("\(tokenUsage.totalTokens)")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                                .fixedSize()
                            }

                            // Input tokens
                            if tokenUsage.inputTokens > 0 {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.down.square")
                                        .font(.caption)
                                    Text("Input:")
                                        .font(.caption)
                                    Text("\(tokenUsage.inputTokens)")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                                .fixedSize()
                            }

                            // Output tokens
                            if tokenUsage.outputTokens > 0 {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.up.square")
                                        .font(.caption)
                                    Text("Output:")
                                        .font(.caption)
                                    Text("\(tokenUsage.outputTokens)")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                                .fixedSize()
                            }

                            // Model code
                            if !tokenUsage.modelCode.isEmpty {
                                HStack(spacing: 4) {
                                    Image(systemName: "cpu")
                                        .font(.caption)
                                    Text("Model:")
                                        .font(.caption)
                                    Text(tokenUsage.modelCode)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                                .fixedSize()
                            }

                            // Confidence
                            if let confidence = tokenUsage.confidence {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.shield")
                                        .font(.caption)
                                    Text("Confidence:")
                                        .font(.caption)
                                    Text("\(String(format: "%.1f%%", confidence * 100))")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                                .fixedSize()
                            }

                            // Perplexity
                            if let perplexity = tokenUsage.perplexity {
                                HStack(spacing: 4) {
                                    Image(systemName: "chart.line.uptrend.xyaxis")
                                        .font(.caption)
                                    Text("Perplexity:")
                                        .font(.caption)
                                    Text("\(String(format: "%.2f", perplexity))")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                                .fixedSize()
                            }
                        }
                    }
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                    .background(Color(.systemGray6).opacity(0.5))
                    .transition(.opacity.combined(with: .scale))
                }

                InputMessageView(
                    inputMessage: $inputMessage,
                    isLoading: chatLoader.isLoading,
                    disabledMessage: disabledInputMessage,
                ) {
                    let message = inputMessage
                    inputMessage = ""  // Clear immediately
                    Task {
                        await sendMessage(message)
                    }
                }
            }
            .navigationTitle(chatThread?.title ?? "New Chat")
            .toolbar { toolbarContent }
            .confirmationDialog("Resetting Chat Options", isPresented: $showDeleteResetDialog, titleVisibility: .visible) {
                confirmationDialogContent()
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
                        await chatLoader.prewarmChatWithModel(modelCode: nil)
                    }
                }) {
                    Label("Default Agent Model", systemImage: chatLoader.selectedModelCode == nil ? "checkmark" : "")
                }

                Divider()

                ForEach(chatLoader.availableModels, id: \.code) { model in
                    Button(action: {
                        chatLoader.selectedModelCode = model.code
                        // Regenerate UUID and prewarm with new model (skip for cloud-only models)
                        chatLoader.resetRunIdentifier()
                        if !model.cloudOnly {
                            Task {
                                await chatLoader.prewarmChatWithModel(modelCode: model.code)
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
            .disabled(isGenerating)
            .opacity(isGenerating ? 0.6 : 1.0)

            if isGenerating {
                ProgressView()
                    .scaleEffect(0.7)
                    .padding(.leading, 4)
            }

            Spacer()
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
        // Prewarm the AI model for this chat session
        Task {
            await chatLoader.prewarmChat()
            // Load available AI models
            await chatLoader.loadAIModels()
        }

        if let thread = chatThread {
            ExampleAppLogger.shared.log("💬 ChatView.onAppear", threadID: thread.freeTokenThreadId)

            if thread.freeTokenThreadId == nil {
                ExampleAppLogger.shared.log("💬 ChatView.onAppear: No FreeToken thread ID found, creating thread...")
                createFreeTokenThread()
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

        generateTitleIfNeeded(userMessage: userMessageContent)
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
    
    private func generateTitleIfNeeded(userMessage: String) {
        if chatThread?.title == "New Chat" {
            Task {
                let title = await chatLoader.generateLocalCompletion(userMessage: userMessage) ?? "New Chat"
                DispatchQueue.main.async {
                    self.chatThread?.title = title
                }
            }
        }
    }
    
    private func resetChat() {
        ExampleAppLogger.shared.log("💬 About to reset thread", threadID: chatThread?.freeTokenThreadId)
        isCreatingThread = true

        // Reset runIdentifier for the new chat session
        chatLoader.resetRunIdentifier()

        // Store selected model before clearing
        let selectedModel = chatLoader.selectedModelCode

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
            // Restore selected model
            chatLoader.selectedModelCode = selectedModel
        }

        // Create new thread in the backend
        createFreeTokenThread {
             withAnimation(.easeInOut(duration: 0.6)) { isCreatingThread = false }

             ExampleAppLogger.shared.log("✅ Successfully reset message thread", threadID: chatThread?.freeTokenThreadId)

             // Prewarm the AI for the new chat session
             Task {
                 await chatLoader.prewarmChat()
             }
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
