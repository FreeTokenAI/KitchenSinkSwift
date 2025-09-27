//
//  ChatThread.swift
//  ExampleApp
//
//  Created by Ashley Luhrs on 6/11/25.
//

import Foundation
import SwiftData

@Model
final class ChatThread {
    var id: UUID
    var title: String
    var createdAt: Date
    var updatedAt: Date
    var freeTokenThreadId: String?
    var previewContent: String? = nil
    
    init(id: UUID = UUID(), title: String = "New Chat", createdAt: Date = Date(), updatedAt: Date = Date(), freeTokenThreadId: String? = nil) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.freeTokenThreadId = freeTokenThreadId
    }
}
