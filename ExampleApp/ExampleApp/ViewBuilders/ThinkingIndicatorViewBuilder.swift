//
//  ThinkingIndicatorViewBuilder.swift
//  ExampleApp
//
//  Created by Ashley Luhrs on 7/1/25.
//

import SwiftUI

struct ThinkingIndicatorView: View {
    let responseStatus: ResponseStatus
    
    var body: some View {
        HStack {
            switch responseStatus {
            case .failed, .streamEnded, .waiting:
                EmptyView()
            case .starting:
                Text("🏁 Starting...")
                    .foregroundColor(.secondary)
            case .checkingForToolCalls, .evaluatingToolCalls:
                Text("🧐 Reviewing all the information...")
                    .foregroundColor(.secondary)
            case .handingOffToolCalls:
                Text("⚙️ Requesting more information...")
                    .foregroundColor(.secondary)
            case .sendingToLocalAI, .sendingToCloudAI:
                Text("🧠 Thinking...")
                    .foregroundColor(.secondary)
            case .streamingTokens:
                Text("⌨️ Typing response...")
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .id(responseStatus)
        .padding(.horizontal)
    }
}
