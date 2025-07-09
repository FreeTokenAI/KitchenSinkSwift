//
//  ChatViewExtensions.swift
//  ExampleApp
//
//  Created by Ashley Luhrs on 7/1/25.
//

import Foundation

func runThreadWith(
    chatLoader: ChatViewModel,
    threadID: String?,
    onUpdate: @escaping (_ content: String, _ date: Date?) -> Void,
    onError: @escaping (_ error: String) -> Void,
    onScroll: @escaping () -> Void
) async {
    if let message = await chatLoader.runMessageThread(id: threadID) {
        onUpdate(message.content, message.createdAt)
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        onScroll()
    }
}
