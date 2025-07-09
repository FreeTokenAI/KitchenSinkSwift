import SwiftUI
import FreeToken
import CryptoKit

class ChatViewModel: ObservableObject, @unchecked Sendable {
    @Published var streamedResponse = ""
    @Published var responseStatus: ResponseStatus = .waiting
    @Published var messages: [FreeToken.Message] = []
    @Published var deviceRegistrationError: String?
    @Published var isLoading: Bool = false
    @Published var lastError: String?
    @Published var temporaryUserMessage: String? = nil
    
    var freeTokenClient: FreeTokenClient
    private(set) var messageThreadID: String?
    
    init(freeTokenClient: FreeTokenClient) {
        self.freeTokenClient = freeTokenClient
        Task { await loadData() }
    }
    
    func loadData() async {  
        // Don't reload if already registered
        if freeTokenClient.registered { return }

        await registerDevice()
    }
    
    func registerDevice() async {
        await freeTokenClient.client.registerDeviceSession(scope: "example-app-device") {
            Task { await self.downloadModel() }
        }
        error: { error in
            ExampleAppLogger.shared.log("❌ Device registration failed: \(error)", level: .error)
            Task {
                await MainActor.run {
                    self.deviceRegistrationError = error.message
                    self.lastError = "Device registration failed: \(error)"
                    self.isLoading = false
                }
            }
        }
    }
    
    func downloadModel() async {
        await freeTokenClient.client.downloadAIModel { _ in
            Task {
                await self.loadModel()
            }
        } error: { error in
            ExampleAppLogger.shared.log("⚠️ Model download failed - continuing with cloud inference: \(error)", level: .warning)
            self.lastError = error.message
        } progressPercent: { progressPercent in
            ExampleAppLogger.shared.log("📥 Model download progress: \(progressPercent)%")
        }
    }
    
    func loadModel() async {
        await freeTokenClient.client.loadModel { _ in
            Task {
                _ = await self.createMessageThread()
                await MainActor.run { self.freeTokenClient.registered = true }
                ExampleAppLogger.shared.log("✅ Successfully registered device and set freeTokenClient.registered to: \(self.freeTokenClient.registered)")
            }
        } error: { error in
            ExampleAppLogger.shared.log("⚠️ Error loading model into memory - 📱 Continuing with cloud inference: \(error)", level: .warning)
        }
    }
    
    func createMessageThread(newMessage: String? = nil) async -> FreeToken.MessageThread? {
        return await withCheckedContinuation { continuation in
            Task {
                await freeTokenClient.client.createMessageThread { messageThread in
                    self.messageThreadID = messageThread.id
                    ExampleAppLogger.shared.log("✅ createFreeTokenThread:  Successfully created FreeToken thread", threadID: self.messageThreadID)
                    continuation.resume(returning: messageThread)
                    await MainActor.run { self.isLoading = false }
                } error: { error in
                    ExampleAppLogger.shared.log("❌ createFreeTokenThread: Failed to create FreeToken with Error: \(error.message)", threadID: self.messageThreadID)
                    Task {
                        await MainActor.run {
                            self.lastError = error.message
                            self.isLoading = false
                        }
                        continuation.resume(returning: nil)
                    }
                }
            }
        }
    }
        
    func addMessageToThread(newMessage: String) async {
        await MainActor.run {
            self.responseStatus = .starting
            self.isLoading = true
            self.lastError = nil
            self.temporaryUserMessage = newMessage
        }
        
        guard let messageThreadID = await validateMessagThreadID() else { return }
        
        let userMessage = FreeToken.Message(role: .user, content: newMessage)
        
        await freeTokenClient.client.addMessageToThread(id: messageThreadID, message: userMessage) { message in
            ExampleAppLogger.shared.log("✅ Successfully added message to thread", threadID: self.messageThreadID)
            Task {
                await MainActor.run {
                    self.temporaryUserMessage = nil
                    // message is the user message
                    self.messages.append(message)
                    self.isLoading = false
                }
            }
        } error: { error in
            ExampleAppLogger.shared.log("❌ Failed to add message to the thread", level: .error, threadID: self.messageThreadID)
            Task {
                await MainActor.run {
                    self.temporaryUserMessage = nil
                    self.lastError = error.message
                    self.isLoading = false
                }
            }
        }
    }
    
    func runMessageThread(id: String? = nil) async -> FreeToken.Message? {
        await MainActor.run {
            self.isLoading = true
            self.lastError = nil
            self.responseStatus = .starting
        }
        
        guard let messageThreadID = await validateMessagThreadID(id) else { return nil }
        
        return await withCheckedContinuation { continuation in
            Task {
                await freeTokenClient.client.runMessageThread(id: messageThreadID) { message in
                    Task {
                        ExampleAppLogger.shared.log("✅ Successfully ran message thread", threadID: self.messageThreadID)
                        await MainActor.run {
                            self.isLoading = false
                            
                            if !self.messages.contains(where: { $0.id == message.id }) {
                                self.messages.append(message)
                            }
                            
                            guard message.content != "[]" else {
                                self.lastError = "Error parsing response from AI. Refer to logs for more details."
                                return
                            }
                        }
                    }
                    continuation.resume(returning: message)
                } error: { error in
                    Task {
                        ExampleAppLogger.shared.log("❌ Failed to run message thread", level: .error, threadID: self.messageThreadID)
                        await MainActor.run { self.lastError = error.message }
                        continuation.resume(returning: nil)
                    }
                } chatStatusStream: { token, status in
                    Task {
                        ExampleAppLogger.shared.log("✅ Successfully streaming", threadID: self.messageThreadID)
                        await MainActor.run {
                            self.responseStatus = ResponseStatus(rawValue: status.rawValue) ?? .starting
                            if let token = token {
                                self.streamedResponse += token
                            }
                        }
                    }
                }
                // TODO: implement toolCallback
            }
        }
    }
    
    private func validateMessagThreadID(_ id: String? = nil) async -> String? {
        let messageThreadID = id ?? self.messageThreadID
        
        guard let messageThreadID else {
            ExampleAppLogger.shared.log("❌ Failed to add message to the thread - missing messageThreadID", level: .error)
            await MainActor.run {
                self.isLoading = false
                self.lastError = "Failed to add message to the thread - missing messageThreadID"
            }
            return nil
        }
        
        return messageThreadID
    }
    
    func setLastError(_ error: String?) {
        self.lastError = error
    }
    
    func generateLocalCompletion(userMessage: String) async -> String? {
        let prompt = """
            INSTRUCTIONS: Generate a ~3 word title for a chat thread based on the user message. Feel free to use emojis if appropriate. Do not include any other text in your response.
            USER MESSAGE: \(userMessage)
            TITLE:
        """
            
        return await withCheckedContinuation { continuation in
            Task {
                await freeTokenClient.client.generateCompletion(prompt: prompt) { result in
                    ExampleAppLogger.shared.log("✅ Successfully ran local completion", threadID: self.messageThreadID)
                    continuation.resume(returning: result.response)
                } error: { error in
                    ExampleAppLogger.shared.log("❌ Error generating title: \(error.message)", level: .error, threadID: self.messageThreadID)
                    continuation.resume(returning: nil)
                }
            }
        }
    }
}
