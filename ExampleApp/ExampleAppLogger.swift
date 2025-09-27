import Foundation
import FreeToken

class ExampleAppLogger {
    public static let shared = ExampleAppLogger()
    private var logs: [LogEntry] = []
    private let queue = DispatchQueue(label: "com.freetoken.diagnostics", attributes: .concurrent)
    
    struct LogEntry {
        let timestamp: Date
        let message: String
        let threadId: String?
        let category: String
    }
    
    private init() {}
    
    public func log(_ message: String, level: FreeToken.FreeTokenLogger.LogLevel? = .info, category: String? = "ExampleApp", threadID: String? = nil) {
        
        let categoryName = category ?? "ExampleApp"
        
        queue.async(flags: .barrier) {
            let entry = LogEntry(timestamp: Date(), message: message, threadId: threadID, category: categoryName)
            self.logs.append(entry)
        }
        
        print("🔍 [\(Date())[\(categoryName)] [\(threadID ?? "no-thread")] \(message)")
    }
    
    func dumpAllLogs() {
        queue.sync {
            print("\n📋 === DIAGNOSTIC LOG DUMP ===")
            for entry in logs {
                let formatter = DateFormatter()
                formatter.dateFormat = "HH:mm:ss.SSS"
                let time = formatter.string(from: entry.timestamp)
                let thread = entry.threadId ?? "no-thread"
                print("[\(time)] [\(entry.category)] [\(thread)] \(entry.message)")
            }
            print("📋 === END LOG DUMP ===\n")
        }
    }
}
