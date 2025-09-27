//
//  ChatStatus.swift
//  ExampleApp
//
//  Created by Ashley Luhrs on 6/9/25.
//

import Foundation

enum ChatStatus: String, Codable {
    case waiting
    case starting
    case running
    case finished
    case error
}
