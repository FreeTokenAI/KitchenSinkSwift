import SwiftUI
import FreeToken
import CryptoKit

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

    var freeTokenClient: FreeTokenClient
    private(set) var messageThreadID: String?
    private var currentMessageThread: FreeToken.MessageThread?
    private var runIdentifier: String = UUID().uuidString

    init(freeTokenClient: FreeTokenClient) {
        self.freeTokenClient = freeTokenClient

        // If already registered, use the existing thread ID
        if freeTokenClient.registered && freeTokenClient.messageThreadID != nil {
            self.messageThreadID = freeTokenClient.messageThreadID
        }
    }

    // Prewarm the AI model for this chat session
    func prewarmChat() async {
        // Skip prewarming for cloud-only models
        if let code = selectedModelCode,
           let model = availableModels.first(where: { $0.code == code }),
           model.cloudOnly {
            ExampleAppLogger.shared.log("☁️ Skipping prewarm for cloud-only model: \(code)")
            return
        }

        let modelDescription = selectedModelCode ?? "Default Model"

        // Use thread-specific prewarm if we have an existing thread
        if let threadID = messageThreadID {
            ExampleAppLogger.shared.log("🔥 Prewarming AI for existing thread with model: \(modelDescription)", threadID: threadID)

            await freeTokenClient.client.prewarmAIForMessageThread(
                messageThreadID: threadID,
                modelCode: selectedModelCode,
                success: {
                    ExampleAppLogger.shared.log("✅ Successfully prewarmed AI for thread with model: \(modelDescription)", threadID: threadID)
                },
                error: { error in
                    ExampleAppLogger.shared.log("⚠️ Failed to prewarm AI for thread: \(error.message)", threadID: threadID)
                }
            )
        } else {
            ExampleAppLogger.shared.log("🔥 Prewarming AI for chat with runIdentifier: \(runIdentifier), model: \(modelDescription)")

            await freeTokenClient.client.prewarmAIFor(
                runIdentifier: runIdentifier,
                modelCode: selectedModelCode,
                success: {
                    ExampleAppLogger.shared.log("✅ Successfully prewarmed AI for chat with model: \(modelDescription)")
                },
                error: { error in
                    ExampleAppLogger.shared.log("⚠️ Failed to prewarm AI: \(error.message)")
                }
            )
        }
    }

    // Prewarm the AI model with specific model code
    func prewarmChatWithModel(modelCode: String?) async {
        // Skip prewarming for cloud-only models
        if let code = modelCode,
           let model = availableModels.first(where: { $0.code == code }),
           model.cloudOnly {
            ExampleAppLogger.shared.log("☁️ Skipping prewarm for cloud-only model: \(code)")
            return
        }

        let modelName = modelCode ?? "Default"

        // Use thread-specific prewarm if we have an existing thread (e.g., switching models mid-conversation)
        if let threadID = messageThreadID {
            ExampleAppLogger.shared.log("🔥 Prewarming AI for existing thread with model: \(modelName)", threadID: threadID)

            await freeTokenClient.client.prewarmAIForMessageThread(
                messageThreadID: threadID,
                modelCode: modelCode,
                success: {
                    ExampleAppLogger.shared.log("✅ Successfully prewarmed AI for thread with model: \(modelName)", threadID: threadID)
                },
                error: { error in
                    ExampleAppLogger.shared.log("⚠️ Failed to prewarm AI for thread with model \(modelName): \(error.message)", threadID: threadID)
                }
            )
        } else {
            ExampleAppLogger.shared.log("🔥 Prewarming AI for model: \(modelName) with runIdentifier: \(runIdentifier)")

            await freeTokenClient.client.prewarmAIFor(
                runIdentifier: runIdentifier,
                modelCode: modelCode,
                success: {
                    ExampleAppLogger.shared.log("✅ Successfully prewarmed AI for model: \(modelName)")
                },
                error: { error in
                    ExampleAppLogger.shared.log("⚠️ Failed to prewarm AI for model \(modelName): \(error.message)")
                }
            )
        }
    }

    // Load available AI models
    func loadAIModels() async {
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

    func createMessageThread(newMessage: String? = nil) async -> FreeToken.MessageThread? {
        // Use the global message thread from FreeTokenClient if available AND we don't already have a different local thread
        if let existingThreadID = freeTokenClient.messageThreadID,
           self.messageThreadID == nil {
            self.messageThreadID = existingThreadID
            ExampleAppLogger.shared.log("✅ Using existing FreeToken thread", threadID: self.messageThreadID)
            // Load all messages from the existing thread
            await loadMessagesFromThread(threadID: existingThreadID)
            return nil // Return nil as we're using existing thread
        }

        // If we already have a thread ID, don't create a new one
        if self.messageThreadID != nil {
            ExampleAppLogger.shared.log("✅ Already have a thread ID", threadID: self.messageThreadID)
            return nil
        }

        // Otherwise create a new thread
        return await withCheckedContinuation { continuation in
            Task {
                await freeTokenClient.client.createMessageThread(
                    success: { messageThread in
                        Task { @MainActor in
                            self.messageThreadID = messageThread.id
                            self.currentMessageThread = messageThread
                            self.messages = messageThread.messages
                            // Also update FreeTokenClient's thread ID
                            self.freeTokenClient.setMessageThreadID(messageThread.id)
                            self.isLoading = false
                        }
                        ExampleAppLogger.shared.log("✅ Successfully created FreeToken thread", threadID: messageThread.id)
                        continuation.resume(returning: messageThread)
                    },
                    error: { error in
                        ExampleAppLogger.shared.log("❌ Failed to create FreeToken thread with Error: \(error.message)", threadID: self.messageThreadID)
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
    func sendMessage(message: String, isThreadFirstMessage: Bool) async {
        guard let threadID = messageThreadID else {
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

    private func runThread() async {
        guard let threadID = messageThreadID else { return }

        await MainActor.run {
            responseStatus = .streamingTokens
            streamedResponse = ""
        }

        await freeTokenClient.client.runMessageThread(
            id: threadID,
            runIdentifier: runIdentifier,
            modelCode: selectedModelCode,
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
                default:
                    break
                }
            }
        )
    }

    func fetchMessages() async {
        // Messages are stored locally in the messages array
        // No need to fetch from API as they're updated when we add/run
        ExampleAppLogger.shared.log("📚 Current message count: \(messages.count)", threadID: messageThreadID)
    }

    // Load all messages from a thread (including system messages)
    private func loadMessagesFromThread(threadID: String) async {
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

    func deleteThread() async {
        guard let threadId = messageThreadID else { return }

        await MainActor.run { isLoading = true }

        freeTokenClient.client.deleteMessageThread(
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
                    // Clear the global thread ID in FreeTokenClient
                    self?.freeTokenClient.clearMessageThreadID()
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
    func deleteMessageThread(threadID: String?) async -> Bool {
        guard let threadId = threadID else { return false }

        return await withCheckedContinuation { continuation in
            freeTokenClient.client.deleteMessageThread(
                id: threadId,
                success: { _ in
                    ExampleAppLogger.shared.log("✅ Successfully deleted thread", threadID: threadId)
                    // Clear the thread ID from both ChatViewModel and FreeTokenClient
                    if threadId == self.messageThreadID {
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
                    // Always clear the global thread ID if it matches
                    if threadId == self.freeTokenClient.messageThreadID {
                        self.freeTokenClient.clearMessageThreadID()
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
    func addMessageToThread(newMessage: String) async -> FreeToken.Message? {
        guard let threadID = messageThreadID else { return nil }

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
    func runMessageThread(id: String?) async -> FreeToken.Message? {
        guard let threadId = id ?? messageThreadID else { return nil }

        return await withCheckedContinuation { continuation in
            Task {
                await freeTokenClient.client.runMessageThread(
                    id: threadId,
                    runIdentifier: runIdentifier,
                    modelCode: selectedModelCode,
                    success: { message in
                        await MainActor.run {
                            self.messages.append(message)
                            // Capture token usage stats if available
                            self.lastTokenUsage = message.tokenUsage
                        }
                        continuation.resume(returning: message)
                    },
                    error: { error in
                        ExampleAppLogger.shared.log("❌ Failed to run thread: \(error.message)", threadID: threadId)
                        continuation.resume(returning: nil)
                    }
                )
            }
        }
    }

    // Set the last error message
    func setLastError(_ error: String) {
        Task { @MainActor in
            self.lastError = error
        }
    }

    // Clear the message thread ID (used by ChatView when resetting)
    func clearMessageThreadID() {
        self.messageThreadID = nil
        self.currentMessageThread = nil
        // Also clear the global thread ID
        self.freeTokenClient.clearMessageThreadID()
    }

    // Generate a title for the chat thread using local completion
    func generateLocalCompletion(userMessage: String) async -> String? {
        // For now, return a simple title based on the first message
        // In a real implementation, this would use the AI model to generate a title
        let words = userMessage.split(separator: " ").prefix(5).joined(separator: " ")
        return words.isEmpty ? nil : String(words)
    }
}
