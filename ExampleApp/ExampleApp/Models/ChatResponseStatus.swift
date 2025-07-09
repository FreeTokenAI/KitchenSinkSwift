//
//  ChatResponseStatus.swift
//  
//
//  Created by Ashley Luhrs on 6/4/25.
//

import Foundation

enum ResponseStatus: String, Equatable {
    case waiting = "waiting"
    case starting = "starting"
    case failed = "failed"
    case evaluatingToolCalls = "evaluating_tool_calls"
    case checkingForToolCalls = "checking_for_tool_calls"
    case handingOffToolCalls = "handing_off_tool_calls"
    case sendingToLocalAI = "sending_to_local_ai"
    case sendingToCloudAI = "sending_to_cloud_ai"
    case streamingTokens = "streaming_tokens"
    case streamEnded = "stream_ended"
}
