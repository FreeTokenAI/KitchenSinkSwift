//
//  MessageBubbleViewBuilders.swift
//  ExampleApp
//
//  Created by Ashley Luhrs on 7/1/25.
//

import SwiftUI
import MarkdownUI
import FreeToken

struct TemporaryUserMessageBubble: View {
    let content: String
    
    var body: some View {
        HStack {
            Spacer()
            VStack(alignment: .trailing) {
                Markdown(content)
                    .markdownTheme(.bubbleTheme(isUser: true))
                    .padding(10)
                    .background(Color.blue)
                    .cornerRadius(16)
                    .textSelection(.enabled)
                
                Text(Date().formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
    }
}

struct TemporaryAgentMessageBubble: View {
    let content: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Markdown(content)
                    .markdownTheme(.bubbleTheme(isUser: false))
                    .padding(10)
                    .background(Color(.systemGray5))
                    .cornerRadius(16)
                    .textSelection(.enabled)
                
                Text(Date().formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            Spacer()
        }
    }
}

struct MessageBubble: View {
    let message: FreeToken.Message

    var body: some View {
        // Display all messages including system and tool messages
        if !message.content.isEmpty {
            HStack {
                if message.role == .user {
                    Spacer()
                }
                VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                    // Show role label for system and tool messages
                    if message.role == .system || message.role == .tool {
                        Text(message.role == .system ? "System" : "Tool")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(messageRoleColor(for: message.role))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(messageRoleColor(for: message.role).opacity(0.2))
                            .cornerRadius(8)
                    }

                    Markdown(message.content)
                        .markdownTheme(.bubbleTheme(isUser: message.role == .user))
                        .padding(10)
                        .background(messageBackgroundColor(for: message.role))
                        .cornerRadius(16)
                        .textSelection(.enabled)

                    if let createdAt = message.createdAt {
                        Text(createdAt.formatted(date: .omitted, time: .shortened))
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
                if message.role != .user {
                    Spacer()
                }
            }
            .id(message.id)
        } else {
            // Return an empty view for messages with no content
            EmptyView()
        }
    }

    private func messageBackgroundColor(for role: FreeToken.MessageRole) -> Color {
        switch role {
        case .user:
            return Color.blue
        case .assistant:
            return Color(.systemGray5)
        case .system:
            return Color.orange.opacity(0.2)
        case .tool:
            return Color.purple.opacity(0.2)
        }
    }

    private func messageRoleColor(for role: FreeToken.MessageRole) -> Color {
        switch role {
        case .system:
            return Color.orange
        case .tool:
            return Color.purple
        default:
            return Color.primary
        }
    }
}

struct InputMessageView: View {
    @Binding var inputMessage: String
    let isLoading: Bool
    let disabledMessage: String
    let sendMessage: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            // Show disabled message if there's any AI operation active
            if !disabledMessage.isEmpty {
                Text(disabledMessage)
                    .font(.caption)
                    .foregroundColor(.orange)
                    .padding(.horizontal)
            }
            
            HStack {
                TextField("Type a message...", text: $inputMessage, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disabled(isLoading)
                
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .resizable()
                        .frame(width: 30, height: 30)
                        .foregroundColor(inputMessage.isEmpty || isLoading ? .gray : .blue)
                }
                .disabled(inputMessage.isEmpty || isLoading)
            }
            .padding()
        }
    }
}

// MARK: - Markdown Theme Extension
extension MarkdownUI.Theme {
    static func bubbleTheme(isUser: Bool) -> MarkdownUI.Theme {
        var theme = MarkdownUI.Theme.basic
        
        // Set color based on whether it's a user message or assistant message
        let textColor = isUser ? Color.white : Color.primary
        
        // Apply text color to all text elements
        theme = theme.text {
            ForegroundColor(textColor)
        }
        .paragraph { config in
            config.label.foregroundColor(textColor)
        }
        .code {
            ForegroundColor(textColor)
            BackgroundColor(isUser ? Color.blue.opacity(0.3) : Color.gray.opacity(0.2))
        }
        .strong {
            ForegroundColor(textColor)
            FontWeight(.bold)
        }
        .emphasis {
            ForegroundColor(textColor)
            FontStyle(.italic)
        }
        .strikethrough {
            ForegroundColor(textColor)
            StrikethroughStyle(.single)
        }
        .link {
            ForegroundColor(isUser ? Color.white.opacity(0.9) : Color.blue)
        }
        // Apply text color to all headings
        .heading1 { config in
            config.label.foregroundColor(textColor)
        }
        .heading2 { config in
            config.label.foregroundColor(textColor)
        }
        .heading3 { config in
            config.label.foregroundColor(textColor)
        }
        .heading4 { config in
            config.label.foregroundColor(textColor)
        }
        .heading5 { config in
            config.label.foregroundColor(textColor)
        }
        .heading6 { config in
            config.label.foregroundColor(textColor)
        }
        .listItem { config in
            config.label.foregroundColor(textColor)
        }
        
        // Add the appropriate block and text styles for the bubbles
        theme = theme.codeBlock { config in
            ScrollView(.horizontal) {
                config.label
                    .foregroundColor(textColor)
                    .font(.system(.footnote, design: .monospaced))
                    .padding(10)
                    .background(isUser ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        
        return theme
    }
}
