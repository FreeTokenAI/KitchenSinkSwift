//
//  MessageListView.swift
//  ExampleApp
//
//  Created by Ashley Luhrs on 7/1/25.
//

import SwiftUI

struct MessageListView: View {
    @ObservedObject var chatLoader: ChatViewModel
    @Binding var lastMessageId: String?
    @Binding var shouldScrollToBottom: Bool
    @Binding var chatThread: ChatThread?
    
    var body: some View {
        ScrollViewReader { scrollProxy in
            ZStack {
                ScrollView {
                    LazyVStack(spacing: 12, pinnedViews: []) {
                        ForEach(chatLoader.messages, id: \.id) { message in
                            MessageBubble(message: message)
                            // Ensure stable IDs for better performance
                                .id(message.id)
                                .background(
                                    GeometryReader { geo in
                                        Color.clear
                                            .preference(
                                                key: ScrollViewOffsetPreferenceKey.self,
                                                value: geo.frame(in: .global).minY > 0 && geo.frame(in: .global).maxY < UIScreen.main.bounds.height ? message.id : nil
                                            )
                                    }
                                )
                        }
                        
                        // Show temporary user message if available
                        if let temporaryMessage = chatLoader.temporaryUserMessage {
                            TemporaryUserMessageBubble(content: temporaryMessage)
                        }
                        
                        // Display thinking indicator between messages when appropriate
                        if chatLoader.responseStatus != .waiting {
                            ThinkingIndicatorView(responseStatus: chatLoader.responseStatus)
                        }
                        
                        if !chatLoader.streamedResponse.isEmpty {
                            TemporaryAgentMessageBubble(content: chatLoader.streamedResponse)
                        }
                        
                        if let errorMessage = chatLoader.lastError, errorMessage != "" {
                            errorView(errorMessage)
                        }
                        
                        // Invisible marker for scroll position
                        Color.clear
                            .frame(height: 20)
                            .id("MessageEnd")
                    }
                    .padding()
                }
                .scrollDismissesKeyboard(.interactively)
                
                .onChange(of: chatLoader.lastError) { _, _ in
                    ExampleAppLogger.shared.log("onChange(of: chatLoader.lastError) - About to scroll to the bottom")
                    withAnimation {
                        scrollProxy.scrollTo("MessageEnd", anchor: .bottom)
                    }
                }
                // Track scroll position by visible message IDs
                .onPreferenceChange(ScrollViewOffsetPreferenceKey.self) { value in
                    if let visibleId = value {
                        self.lastMessageId = visibleId
                    }
                }
                .onChange(of: chatLoader.streamedResponse) { _, newValue in
                    guard !newValue.isEmpty else { return }
                    
                    if let lastId = chatLoader.messages.last?.id, lastId == lastMessageId {
                        withAnimation {
                            scrollProxy.scrollTo("MessageEnd", anchor: .bottom)
                        }
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardDidShowNotification)) { _ in
                    ExampleAppLogger.shared.log("onReceive(NotificationCenter.default.publisher - About to scroll to the bottom")
                    withAnimation {
                        scrollProxy.scrollTo("MessageEnd", anchor: .bottom)
                    }
                }
                .onChange(of: shouldScrollToBottom) { _, newValue in
                    if newValue {
                        ExampleAppLogger.shared.log("💬 onChange shouldScrollToBottom: Attempting to scroll to bottom", threadID: chatThread?.freeTokenThreadId)
                        withAnimation {
                            scrollProxy.scrollTo("MessageEnd", anchor: .bottom)
                        }
                        
                        DispatchQueue.main.async {
                            self.shouldScrollToBottom = false
                            ExampleAppLogger.shared.log("💬 onChange(of: shouldScrollToBottom) - Setting shouldScrollToBottom to: \(shouldScrollToBottom))")
                        }
                    }
                }
                .onChange(of: chatLoader.messages.count) { oldCount, newCount in
                    ExampleAppLogger.shared.log("💬 onChange messages.count: \(oldCount) -> \(newCount)", threadID: chatThread?.freeTokenThreadId)
                    
                    if oldCount == 0 && newCount > 0 {
                        ExampleAppLogger.shared.log("💬 onChange messages.count: Initial load detected, scrolling to bottom", threadID: chatThread?.freeTokenThreadId)
                        withAnimation {
                            scrollProxy.scrollTo("MessageEnd", anchor: .bottom)
                        }
                    }
                }
                
                // Floating scroll to bottom button
                if let lastId = chatLoader.messages.last?.id, lastId != lastMessageId, !chatLoader.messages.isEmpty {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button(action: {
                                withAnimation {
                                    scrollProxy.scrollTo("MessageEnd", anchor: .bottom)
                                    // Add a small delay to ensure the scroll completes
                                    scrollProxy.scrollTo("MessageEnd", anchor: .bottom)
                                }
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(Color(.systemBackground))
                                        .frame(width: 50, height: 50)
                                        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                                    
                                    Image(systemName: "arrow.down")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(.trailing, 20)
                            .padding(.bottom, 20)
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .animation(.easeInOut(duration: 0.2), value: lastMessageId)
                }
            }
        }
    }
    
    // Helper functions
    private func errorView(_ errorMessage: String) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(errorMessage)
                    .padding(10)
                    .background(Color.red.opacity(0.2))
                    .foregroundColor(.red)
                    .cornerRadius(16)
                Button { Task { await retryLastMessage() }
                    } label: {
                        Label("Retry Message", systemImage: "arrow.counterclockwise")
                            .foregroundColor(.blue)
                    }
                    .padding(10)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(16)
            }
            Spacer()
        }
        .padding(.horizontal)
    }
    
    private func retryLastMessage() async {
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
                shouldScrollToBottom = true
                ExampleAppLogger.shared.log("💬 retryLastMessage()runThreadWith() - Setting shouldScrollToBottom to: \(shouldScrollToBottom))")
            }
        )
    }
}

struct ScrollViewOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: String? = nil
    
    static func reduce(value: inout String?, nextValue: () -> String?) {
        value = nextValue() ?? value
    }
}
