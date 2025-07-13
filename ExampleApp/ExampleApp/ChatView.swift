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
        if !chatLoader.freeTokenClient.registered {
            return "Setting up FreeToken AI connection..."
        }
        
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
                chatContentView()
                Divider()
                InputMessageView(
                    inputMessage: $inputMessage,
                    isLoading: chatLoader.isLoading,
                    disabledMessage: disabledInputMessage,
                ) {
                    Task {
                        await sendMessage()
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
            .onReceive(chatLoader.freeTokenClient.$registered) { isRegistered in
                handleRegistrationChange(isRegistered)
            }
            .onDisappear {
                handleOnDisappear()
            }
            if isCreatingThread {
                Color.black.opacity(0.2)
                    .ignoresSafeArea()
                ProgressView("Creating new chat...")
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)))
                    .shadow(radius: 10)
            }
        }
    }
    
    // Internal Extracted Views & View Helpers
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
        if !chatLoader.freeTokenClient.registered && chatThread?.freeTokenThreadId == nil {
            
            if let registrationError = chatLoader.deviceRegistrationError {
                renderContentUnavailableView(label: "Error Registering Device", systemImage: "person.crop.circle.badge.exclamationmark.fill", text: "There was an error when registering the device. View logs for additional information. Error: \(registrationError)")
            } else {
                renderContentUnavailableView(label: "Setting up chat...", systemImage: "gear", text: "Initializing FreeToken AI connection")
            }
        } else {
            renderContentUnavailableView(label: "No Messages", systemImage: "bubble.left", text: "Start a conversation with FreeToken AI")
        }
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
                            .foregroundColor(.black)
                    }
                }
                Button(action: { ExampleAppLogger.shared.dumpAllLogs() }) {
                    Image(systemName: "ladybug")
                        .font(.system(size: 17))
                        .foregroundColor(.black)
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
    
    // Called when the view appears. Handles thread initialization and device registration state
    private func handleOnAppear() {
        if let thread = chatThread {
            ExampleAppLogger.shared.log("💬 ChatView.onAppear: chatLoader.freeTokenClient.registered = \(chatLoader.freeTokenClient.registered)", threadID: thread.freeTokenThreadId)
            
            if thread.freeTokenThreadId == nil {
                ExampleAppLogger.shared.log("💬 ChatView.onAppear: No FreeToken thread ID found")
                if chatLoader.freeTokenClient.registered {
                    ExampleAppLogger.shared.log("💬 ChatView.onAppear: Device is registered, creating thread immediately...")
                    createFreeTokenThread()
                } else {
                    ExampleAppLogger.shared.log("💬 ChatView.onAppear: Device not yet registered, will wait...")
                    chatLoader.isLoading = true
                }
            } else {
                ExampleAppLogger.shared.log("💬 ChatView.onAppear: Found existing FreeToken thread ID.", threadID: thread.freeTokenThreadId)
            }
        } else {
            ExampleAppLogger.shared.log("💬 ChatView.onAppear for new chat (no thread yet) and chatLoader.freeTokenClient.registered = \(chatLoader.freeTokenClient.registered)")
        }
    }
    
    // Handles changes in device registration state and triggers thread creation if needed
    private func handleRegistrationChange(_ isRegistered: Bool) {
        ExampleAppLogger.shared.log("💬 ChatView.onReceive: Device registration state changed to: \(isRegistered) and isLoading: \(chatLoader.isLoading)", threadID: chatThread?.freeTokenThreadId)
        
        if isRegistered && chatThread == nil {
            ExampleAppLogger.shared.log("💬 ChatView.onReceive: Device registered and no thread exists, creating thread...")
            createFreeTokenThread()
        }
        
        if isRegistered && chatThread != nil && chatThread?.freeTokenThreadId == nil {
            ExampleAppLogger.shared.log("💬 ChatView.onReceive: Device registered and no thread ID exists, creating thread...")
            createFreeTokenThread()
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
        if chatThread != nil {
            Task { await MainActor.run { completion?() } }
            return
        }
        
        ExampleAppLogger.shared.log("💬 createFreeTokenThread: Starting thread creation and Device registered: \(chatLoader.freeTokenClient.registered)")
        
        let newThread = ChatThread()
        modelContext.insert(newThread)
        self.chatThread = newThread
        
        Task {
            if let thread = await chatLoader.createMessageThread() {
                chatThread?.freeTokenThreadId = thread.id
                chatThread?.updatedAt = Date()
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
    private func sendMessage() async {
        let userMessageContent = inputMessage
        inputMessage = ""
        
        // force waiting for the thread to finish before moving on to running the thread
        _ = await self.chatLoader.addMessageToThread(newMessage: userMessageContent)
        _ = await runThread()
        
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
        
        // Clear current thread and messages
        withAnimation {
            chatThread = nil
            chatLoader.messages.removeAll()
            chatLoader.lastError = nil
            chatLoader.responseStatus = .starting
            inputMessage = ""
        }
        
        // Create new thread in the backend
        createFreeTokenThread {
             withAnimation { isCreatingThread = false }
            
             ExampleAppLogger.shared.log("✅ Successfully reset message thread", threadID: chatThread?.freeTokenThreadId)
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
