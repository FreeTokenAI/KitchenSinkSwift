import SwiftUI
import FreeToken
import CryptoKit

@MainActor
class ChatViewModel: ObservableObject, @unchecked Sendable {
    @Published var streamedResponse = ""
    @Published var responseStatus: ResponseStatus = .waiting
    @Published var messages: [FreeToken.Message] = []
    @Published var isLoading: Bool = false
    @Published var lastError: String?
    @Published var temporaryUserMessage: String? = nil
    @Published var currentChatStatus: String? = nil
    @Published var selectedModelCode: String? = nil
    @Published var availableModels: [FreeToken.AIModel] = []
    @Published var modelDownloadStates: [String: FreeToken.ModelDownloadState] = [:]
    @Published var lastTokenUsage: FreeToken.TokenUsage? = nil
    @Published var toolsEnabled: Bool = false
    @Published var pendingToolCall: FreeToken.ToolCall? = nil
    @Published var showToolResponseModal: Bool = false
    @Published var aiRunConfigEnabled: Bool = false
    @Published var maxGenerationTokens: Int = 2048
    @Published var contextWindowSize: Int = 4096
    @Published var topK: Int = 40
    @Published var topP: Float = 0.95
    @Published var temperature: Float = 0.7
    @Published var documentSearchScope: String = ""
    @Published var privateDocumentStoreIds: String = ""
    @Published var additionalContext: String = ""

    var freeTokenClient: FreeTokenClient
    private(set) var messageThreadID: String?
    private var currentMessageThread: FreeToken.MessageThread?
    private var runIdentifier: String = UUID().uuidString
    private var toolResponseContinuation: CheckedContinuation<String, Never>?
    private var shouldCancelGeneration: Bool = false

    var currentAIRunConfig: FreeToken.AIRunConfig? {
        guard aiRunConfigEnabled else { return nil }
        return FreeToken.AIRunConfig(
            maxGenerationTokens: maxGenerationTokens,
            contentWindowSize: contextWindowSize,
            topK: topK,
            topP: topP,
            temperature: temperature
        )
    }

    init(freeTokenClient: FreeTokenClient) {
        self.freeTokenClient = freeTokenClient

        // Don't automatically inherit thread ID - each chat should start fresh
        // The thread will be created when the user sends their first message
    }

    // Unified prewarm method for AI model - handles all cases
    nonisolated func prewarmChat(overrideModelCode: String? = nil) async {
        // Get values from MainActor
        let (selectedCode, models, threadID, runId, runConfig, toolsEnabled) = await MainActor.run {
            (selectedModelCode, availableModels, messageThreadID, runIdentifier, currentAIRunConfig, self.toolsEnabled)
        }

        // Use override model code if provided, otherwise use selected model
        let modelCode = overrideModelCode ?? selectedCode

        // Skip prewarming for cloud-only models
        if let code = modelCode,
           let model = models.first(where: { $0.code == code }),
           model.cloudOnly {
            ExampleAppLogger.shared.log("☁️ Skipping prewarm for cloud-only model: \(code)")
            return
        }

        let modelDescription = modelCode ?? "Default Model"

        // Set toolAccess based on toolsEnabled state
        let toolAccess: [FreeToken.ToolRunMask] = toolsEnabled ? [.allowAll] : [.denyAll]

        // Use thread-specific prewarm if we have an existing thread
        if let threadID = threadID {
            ExampleAppLogger.shared.log("🔥 Prewarming AI for existing thread with model: \(modelDescription), tools: \(toolsEnabled ? "allowAll" : "denyAll"), config: \(runConfig != nil ? "custom" : "default")", threadID: threadID)

            await freeTokenClient.client.prewarmAIForMessageThread(
                messageThreadID: threadID,
                modelCode: modelCode,
                runConfig: runConfig,
                success: {
                    ExampleAppLogger.shared.log("✅ Successfully prewarmed AI for thread with model: \(modelDescription)", threadID: threadID)
                },
                error: { error in
                    ExampleAppLogger.shared.log("⚠️ Failed to prewarm AI for thread: \(error.message)", threadID: threadID)
                }
            )
        } else {
            ExampleAppLogger.shared.log("🔥 Prewarming AI for chat with runIdentifier: \(runId), model: \(modelDescription), tools: \(toolsEnabled ? "allowAll" : "denyAll"), config: \(runConfig != nil ? "custom" : "default")")

            await freeTokenClient.client.prewarmAIFor(
                runIdentifier: runId,
                modelCode: modelCode,
                runConfig: runConfig,
                toolAccess: toolAccess,
                success: {
                    ExampleAppLogger.shared.log("✅ Successfully prewarmed AI for chat with model: \(modelDescription)")
                },
                error: { error in
                    ExampleAppLogger.shared.log("⚠️ Failed to prewarm AI: \(error.message)")
                }
            )
        }
    }

    // Load available AI models
    nonisolated func loadAIModels() async {
        await freeTokenClient.client.listAIModels(
            success: { models in
                await MainActor.run {
                    self.availableModels = models
                }
                // Check download state for each model
                for model in models where !model.cloudOnly {
                    do {
                        let state = try await self.freeTokenClient.client.getAIModelDownloadState(modelCode: model.code)
                        await MainActor.run {
                            self.modelDownloadStates[model.code] = state
                        }
                    } catch {
                        ExampleAppLogger.shared.log("Failed to check download state for model \(model.code): \(error)")
                    }
                }
            },
            error: { error in
                ExampleAppLogger.shared.log("❌ Failed to load AI models: \(error.message)")
            }
        )
    }

    // Generate a new runIdentifier for a new chat session
    func resetRunIdentifier() {
        runIdentifier = UUID().uuidString
        ExampleAppLogger.shared.log("🔄 Reset runIdentifier to: \(runIdentifier)")
    }

    // Toggle tools and re-prewarm with proper tool access
    func toggleTools() async {
        // Note: toolsEnabled is already toggled by the Toggle UI control
        // We just need to handle the side effects

        // Tool is always registered, we just use masking to control access
        // No need to register/unregister tools anymore

        // Reset run identifier for new session
        resetRunIdentifier()

        // Re-prewarm with updated tool access (will use allowAll or denyAll based on toolsEnabled)
        await prewarmChat()
    }

    // Handle AIRunConfig changes and re-prewarm
    func aiRunConfigChanged() async {
        // Reset run identifier for new session
        resetRunIdentifier()

        // Re-prewarm with updated config
        await prewarmChat()
    }

    // Register the fetch_weather tool
    nonisolated func registerWeatherTool() async {
        let weatherToolDefinition = """
        {
            "type": "function",
            "function": {
                "name": "fetch_weather",
                "description": "Get the current weather for a specific location",
                "parameters": {
                    "type": "object",
                    "properties": {
                        "location": {
                            "type": "string",
                            "description": "The city and state, e.g. San Francisco, CA"
                        },
                        "unit": {
                            "type": "string",
                            "enum": ["celsius", "fahrenheit"],
                            "description": "The temperature unit to use"
                        }
                    },
                    "required": ["location"]
                }
            }
        }
        """

        await freeTokenClient.client.addToolDefinition(name: "fetch_weather", definitionJSON: weatherToolDefinition)
        ExampleAppLogger.shared.log("🔧 Registered fetch_weather tool")
    }


    // Handle tool calls from the AI
    nonisolated func handleToolCalls(_ toolCalls: [FreeToken.ToolCall]) async -> String {
        var results: [String] = []

        for toolCall in toolCalls {
            ExampleAppLogger.shared.log("🔧 Processing tool call: \(toolCall.name)")

            // Show modal and wait for user response
            let response = await withCheckedContinuation { continuation in
                Task { @MainActor in
                    self.toolResponseContinuation = continuation
                    self.pendingToolCall = toolCall
                    self.showToolResponseModal = true
                }
            }

            results.append(response)
        }

        return results.joined(separator: "\n\n")
    }

    // Submit tool response from modal
    func submitToolResponse(_ response: String) {
        toolResponseContinuation?.resume(returning: response)
        toolResponseContinuation = nil
        pendingToolCall = nil
        showToolResponseModal = false
    }

    nonisolated func createMessageThread(newMessage: String? = nil) async -> FreeToken.MessageThread? {
        // Get values from MainActor
        let (client, toolsEnabled) = await MainActor.run {
            (freeTokenClient, self.toolsEnabled)
        }

        // Set toolAccess based on toolsEnabled state
        let toolAccess: [FreeToken.ToolRunMask] = toolsEnabled ? [.allowAll] : [.denyAll]

        // Otherwise create a new thread
        return await withCheckedContinuation { continuation in
            Task {
                await client.client.createMessageThread(
                    toolAccess: toolAccess,
                    success: { messageThread in
                        Task { @MainActor in
                            self.messageThreadID = messageThread.id
                            self.currentMessageThread = messageThread
                            self.messages = messageThread.messages
                            // Also update FreeTokenClient's thread ID
                            self.isLoading = false
                        }
                        ExampleAppLogger.shared.log("✅ Successfully created FreeToken thread with toolAccess: \(toolsEnabled ? "allowAll" : "denyAll")", threadID: messageThread.id)
                        continuation.resume(returning: messageThread)
                    },
                    error: { error in
                        Task {
                            await MainActor.run {
                                self.lastError = "Failed to create thread: \(error.message)"
                                self.isLoading = false
                            }
                        }
                        continuation.resume(returning: nil)
                    }
                )
            }
        }
    }

    // Add message and run thread to get AI response
    nonisolated func sendMessage(message: String, isThreadFirstMessage: Bool) async {
        let threadID = await MainActor.run { messageThreadID }

        guard let threadID = threadID else {
            await MainActor.run {
                self.lastError = "No thread ID available"
            }
            return
        }

        ExampleAppLogger.shared.log("📤 Adding message to thread", threadID: threadID)

        await MainActor.run {
            temporaryUserMessage = message
            responseStatus = .waiting
            streamedResponse = ""
            currentChatStatus = nil // Clear any previous status
        }

        // First add the message to the thread
        await freeTokenClient.client.addMessageToThread(
            id: threadID,
            message: FreeToken.Message(role: .user, content: message),
            success: { addedMessage in
                ExampleAppLogger.shared.log("✅ Message added to thread", threadID: threadID)

                // For first message, load all messages from thread (including system messages)
                if isThreadFirstMessage {
                    await self.loadMessagesFromThread(threadID: threadID)
                } else {
                    // For subsequent messages, just append the new one
                    await MainActor.run {
                        self.messages.append(addedMessage)
                    }
                }

                await MainActor.run {
                    self.temporaryUserMessage = nil
                }

                // Now run the thread to get AI response
                await self.runThread()
            },
            error: { error in
                ExampleAppLogger.shared.log("❌ Failed to add message: \(error.message)", threadID: threadID)
                await MainActor.run {
                    self.lastError = "Failed to add message: \(error.message)"
                    self.responseStatus = .failed
                    self.temporaryUserMessage = nil
                }
            }
        )
    }

    private nonisolated func runThread() async {
        let threadID = await MainActor.run { messageThreadID }

        guard let threadID = threadID else { return }

        await MainActor.run {
            responseStatus = .streamingTokens
            streamedResponse = ""
            shouldCancelGeneration = false // Reset cancellation flag
        }

        // Create tool callback if tools are enabled
        let (toolsEnabled, runId, modelCode, runConfig, docSearchScope, privateDocStoreIds, additionalCtx) = await MainActor.run {
            (self.toolsEnabled, self.runIdentifier, self.selectedModelCode, self.currentAIRunConfig,
             self.documentSearchScope.isEmpty ? nil : self.documentSearchScope,
             self.privateDocumentStoreIds.isEmpty ? nil : self.privateDocumentStoreIds.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespaces)) },
             self.additionalContext)
        }

        let toolCallback: (([FreeToken.ToolCall]) async -> String)? = toolsEnabled ? { toolCalls in
            await self.handleToolCalls(toolCalls)
        } : nil

        let toolAccess: [FreeToken.ToolRunMask] = toolsEnabled ? [.allowAll] : [.denyAll]

        await freeTokenClient.client.runMessageThread(
            id: threadID,
            runIdentifier: runId,
            documentSearchScope: docSearchScope,
            privateDocumentStoreIds: privateDocStoreIds,
            aiRunConfig: runConfig,
            modelCode: modelCode,
            toolAccess: toolAccess,
            additionalContext: additionalCtx,
            success: { message in
                ExampleAppLogger.shared.log("✅ Received AI response", threadID: threadID)
                await MainActor.run {
                    self.messages.append(message)
                    // Clear the streamed response to prevent duplicate display
                    self.streamedResponse = ""
                    // Capture token usage stats if available
                    self.lastTokenUsage = message.tokenUsage
                    self.responseStatus = .streamEnded
                    self.currentChatStatus = nil // Clear status when message is received
                }
            },
            error: { error in
                ExampleAppLogger.shared.log("❌ Failed to run thread: \(error.message)", threadID: threadID)
                await MainActor.run {
                    self.lastError = "Failed to get response: \(error.message)"
                    self.responseStatus = .failed
                    self.currentChatStatus = nil // Clear status on error
                }
            },
            chatStatusStream: { token, status in
                // Check if cancellation is requested and throw exception to cancel
                let shouldCancel = await MainActor.run { self.shouldCancelGeneration }
                if shouldCancel {
                    ExampleAppLogger.shared.log("🛑 Throwing cancellation exception", threadID: threadID)
                    struct CancellationError: Error {
                        let message = "User cancelled generation"
                    }
                    throw CancellationError()
                }

                // Handle streaming tokens
                if let token = token {
                    await MainActor.run {
                        self.streamedResponse += token
                    }
                }

                switch status {
                case .starting:
                    ExampleAppLogger.shared.log("🎬 Starting AI generation", threadID: threadID)
                    await MainActor.run {
                        self.currentChatStatus = "Starting AI generation..."
                    }
                case .evaluating_tool_calls:
                    await MainActor.run {
                        self.currentChatStatus = "Evaluating tool calls (evaluating_tool_calls)..."
                    }
                case .sending_to_local_ai:
                    await MainActor.run {
                        self.currentChatStatus = "Sending to local AI (sending_to_local_ai)..."
                    }
                case .sending_to_cloud_ai:
                    await MainActor.run {
                        self.currentChatStatus = "Sending to cloud AI (sending_to_cloud_ai)..."
                    }
                case .streaming_tokens:
                    await MainActor.run {
                        self.currentChatStatus = "Streaming tokens (streaming_tokens)..."
                    }
                case .stream_ended:
                    ExampleAppLogger.shared.log("✅ Stream ended", threadID: threadID)
                    await MainActor.run {
                        self.responseStatus = .streamEnded
                        self.currentChatStatus = nil // Clear status when stream ends
                    }
                case .failed:
                    ExampleAppLogger.shared.log("❌ Stream failed", threadID: threadID)
                    await MainActor.run {
                        self.responseStatus = .failed
                        self.currentChatStatus = nil // Clear status on failure
                    }
                case .new_message_created:
                    ExampleAppLogger.shared.log("📝 New message created - fetching updated thread", threadID: threadID)

                    // Clear the streamed response since it's now persisted
                    await MainActor.run {
                        self.streamedResponse = ""
                        self.currentChatStatus = "Loading messages..."
                    }

                    // Fetch the updated message thread to get all persisted messages with IDs
                    await self.freeTokenClient.client.getMessageThread(
                        id: threadID,
                        success: { messageThread in
                            await MainActor.run {
                                // Update messages with the complete thread including new message
                                self.messages = messageThread.messages
                                ExampleAppLogger.shared.log("✅ Loaded \(messageThread.messages.count) messages from updated thread", threadID: threadID)

                                // Update status to show we're continuing with a new message
                                self.currentChatStatus = "AI is continuing..."
                                self.responseStatus = .streamingTokens
                            }
                        },
                        error: { error in
                            ExampleAppLogger.shared.log("❌ Failed to load updated thread: \(error.message)", threadID: threadID)
                            await MainActor.run {
                                self.lastError = "Failed to load messages: \(error.message)"
                            }
                        }
                    )
                }
            },
            toolCallback: toolCallback
        )
    }

    nonisolated func fetchMessages() async {
        // Messages are stored locally in the messages array
        // No need to fetch from API as they're updated when we add/run
        let (count, threadID) = await MainActor.run {
            (messages.count, messageThreadID)
        }
        ExampleAppLogger.shared.log("📚 Current message count: \(count)", threadID: threadID)
    }

    // Load all messages from a thread (including system messages)
    nonisolated func loadMessagesFromThread(threadID: String) async {
        await freeTokenClient.client.getMessageThread(
            id: threadID,
            success: { messageThread in
                await MainActor.run {
                    self.messages = messageThread.messages
                    ExampleAppLogger.shared.log("📚 Loaded \(messageThread.messages.count) messages from thread", threadID: threadID)

                    // Log message types for debugging
                    for message in messageThread.messages {
                        ExampleAppLogger.shared.log("  - \(message.role.rawValue) message: \(String(message.content.prefix(50)))...", threadID: threadID)
                    }
                }
            },
            error: { error in
                ExampleAppLogger.shared.log("❌ Failed to load messages from thread: \(error.message)", threadID: threadID)
            }
        )
    }

    nonisolated func deleteThread() async {
        let (threadId, client) = await MainActor.run {
            (messageThreadID, freeTokenClient)
        }

        guard let threadId = threadId else { return }

        await MainActor.run { isLoading = true }

        client.client.deleteMessageThread(
            id: threadId,
            success: { _ in
                Task { @MainActor [weak self] in
                    ExampleAppLogger.shared.log("✅ Successfully deleted thread", threadID: threadId)
                    self?.messageThreadID = nil
                    self?.currentMessageThread = nil
                    self?.messages = []
                    self?.streamedResponse = ""
                    self?.lastTokenUsage = nil
                    self?.responseStatus = .waiting
                    self?.currentChatStatus = nil
                    self?.isLoading = false
                }
            },
            error: { error in
                Task { @MainActor [weak self] in
                    let errorMessage = "Failed to delete thread: \(error.message)"
                    self?.lastError = errorMessage
                    self?.isLoading = false
                    ExampleAppLogger.shared.log("❌ \(errorMessage)", threadID: threadId)
                }
            }
        )
    }

    // Helper method to delete a message thread by ID (used by ChatView)
    nonisolated func deleteMessageThread(threadID: String?) async -> Bool {
        guard let threadId = threadID else { return false }

        let (currentThreadID, client) = await MainActor.run {
            (self.messageThreadID, self.freeTokenClient)
        }

        return await withCheckedContinuation { continuation in
            client.client.deleteMessageThread(
                id: threadId,
                success: { _ in
                    ExampleAppLogger.shared.log("✅ Successfully deleted thread", threadID: threadId)
                    // Clear the thread ID from both ChatViewModel and FreeTokenClient
                    if threadId == currentThreadID {
                        Task { @MainActor in
                            self.messageThreadID = nil
                            self.currentMessageThread = nil
                            self.messages = []
                            self.streamedResponse = ""
                            self.lastTokenUsage = nil
                            self.responseStatus = .waiting
                            self.currentChatStatus = nil
                        }
                    }

                    continuation.resume(returning: true)
                },
                error: { error in
                    ExampleAppLogger.shared.log("❌ Failed to delete thread: \(error.message)", threadID: threadId)
                    continuation.resume(returning: false)
                }
            )
        }
    }

    // Add a message to the current thread (helper for ChatView compatibility)
    nonisolated func addMessageToThread(newMessage: String) async -> FreeToken.Message? {
        let threadID = await MainActor.run { messageThreadID }

        guard let threadID = threadID else { return nil }

        return await withCheckedContinuation { continuation in
            Task {
                await freeTokenClient.client.addMessageToThread(
                    id: threadID,
                    message: FreeToken.Message(role: .user, content: newMessage),
                    success: { message in
                        await MainActor.run {
                            self.messages.append(message)
                            self.temporaryUserMessage = newMessage
                        }
                        continuation.resume(returning: message)
                    },
                    error: { error in
                        ExampleAppLogger.shared.log("❌ Failed to add message: \(error.message)", threadID: threadID)
                        continuation.resume(returning: nil)
                    }
                )
            }
        }
    }

    // Run the message thread and return the response (helper for ChatView compatibility)
    nonisolated func runMessageThread(id: String?) async -> FreeToken.Message? {
        let (currentThreadID, toolsEnabled, runId, modelCode, runConfig, docSearchScope, privateDocStoreIds, additionalCtx) = await MainActor.run {
            (messageThreadID, self.toolsEnabled, runIdentifier, selectedModelCode, currentAIRunConfig,
             self.documentSearchScope.isEmpty ? nil : self.documentSearchScope,
             self.privateDocumentStoreIds.isEmpty ? nil : self.privateDocumentStoreIds.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespaces)) },
             self.additionalContext)
        }

        guard let threadId = id ?? currentThreadID else { return nil }

        // Reset streaming state for retry
        await MainActor.run {
            self.responseStatus = .streamingTokens
            self.streamedResponse = ""
            self.shouldCancelGeneration = false
        }

        // Create tool callback if tools are enabled
        let toolCallback: (([FreeToken.ToolCall]) async -> String)? = toolsEnabled ? { toolCalls in
            await self.handleToolCalls(toolCalls)
        } : nil

        let toolAccess: [FreeToken.ToolRunMask] = toolsEnabled ? [.allowAll] : [.denyAll]

        return await withCheckedContinuation { continuation in
            Task {
                await freeTokenClient.client.runMessageThread(
                    id: threadId,
                    runIdentifier: runId,
                    documentSearchScope: docSearchScope,
                    privateDocumentStoreIds: privateDocStoreIds,
                    aiRunConfig: runConfig,
                    modelCode: modelCode,
                    toolAccess: toolAccess,
                    additionalContext: additionalCtx,
                    success: { message in
                        await MainActor.run {
                            self.messages.append(message)
                            // Clear the streamed response to prevent duplicate display
                            self.streamedResponse = ""
                            // Capture token usage stats if available
                            self.lastTokenUsage = message.tokenUsage
                            self.responseStatus = .streamEnded
                        }
                        continuation.resume(returning: message)
                    },
                    error: { error in
                        ExampleAppLogger.shared.log("❌ Failed to run thread: \(error.message)", threadID: threadId)
                        await MainActor.run {
                            self.lastError = "Failed to get response: \(error.message)"
                            self.responseStatus = .failed
                        }
                        continuation.resume(returning: nil)
                    },
                    chatStatusStream: { token, status in
                        // Check if cancellation is requested
                        let shouldCancel = await MainActor.run { self.shouldCancelGeneration }
                        if shouldCancel {
                            ExampleAppLogger.shared.log("🛑 Throwing cancellation exception", threadID: threadId)
                            struct CancellationError: Error {
                                let message = "User cancelled generation"
                            }
                            throw CancellationError()
                        }

                        // Handle streaming tokens
                        if let token = token {
                            await MainActor.run {
                                self.streamedResponse += token
                            }
                        }

                        // Handle status updates
                        switch status {
                        case .starting:
                            ExampleAppLogger.shared.log("🎬 Starting AI generation", threadID: threadId)
                            await MainActor.run {
                                self.currentChatStatus = "Starting AI generation..."
                            }
                        case .streaming_tokens:
                            await MainActor.run {
                                self.currentChatStatus = nil
                                self.responseStatus = .streamingTokens
                            }
                        case .stream_ended:
                            ExampleAppLogger.shared.log("✅ Stream ended", threadID: threadId)
                            await MainActor.run {
                                self.responseStatus = .streamEnded
                            }
                        case .failed:
                            ExampleAppLogger.shared.log("❌ Stream failed", threadID: threadId)
                            await MainActor.run {
                                self.responseStatus = .failed
                            }
                        case .new_message_created:
                            ExampleAppLogger.shared.log("📝 New message created - fetching updated thread", threadID: threadId)
                            await MainActor.run {
                                self.streamedResponse = ""
                            }
                            // Fetch updated thread
                            await self.loadMessagesFromThread(threadID: threadId)
                        default:
                            break
                        }
                    },
                    toolCallback: toolCallback
                )
            }
        }
    }

    // Set the last error message
    func setLastError(_ error: String?) {
        Task { @MainActor in
            self.lastError = error
        }
    }

    // Clear the message thread ID (used by ChatView when resetting)
    func clearMessageThreadID() {
        self.messageThreadID = nil
        self.currentMessageThread = nil
    }

    // Cancel the current AI generation
    func cancelGeneration() {
        shouldCancelGeneration = true
        ExampleAppLogger.shared.log("🛑 Cancellation requested")
    }

    // Generate a title for the chat thread using local completion
    nonisolated func generateLocalCompletion(userMessage: String) async -> String? {
        // For now, return a simple title based on the first message
        // In a real implementation, this would use the AI model to generate a title
        let words = userMessage.split(separator: " ").prefix(5).joined(separator: " ")
        return words.isEmpty ? nil : String(words)
    }
}
