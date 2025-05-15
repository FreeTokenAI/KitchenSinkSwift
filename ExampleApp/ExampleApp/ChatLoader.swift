import SwiftUI
import FreeToken
import CryptoKit

class ChatLoader: ObservableObject, @unchecked Sendable {
    @Published var textData: String = ""
    @Published var statusData: String = ""
    @Published var downloadProgress: Double = 0.0
    private var freeTokenClient: FreeTokenClient
    
    init(freeTokenClient: FreeTokenClient) {
        self.freeTokenClient = freeTokenClient
    }

    var messageThreadID: String?
    
    var textResponse = ""
    var statusResponse = ""
    var errorState = false
    
    func resetText() {
        textResponse = ""
        statusResponse = ""
        errorState = false
        setMessage()
    }
    
    func loadData() async {  
        // Don't reload if already registered
        if freeTokenClient.registered { return }      

        // Setup FreeToken
        self.registerDevice()
    }
    
    func registerDevice() {
        if errorState { return }
        
        freeTokenClient.client.registerDeviceSession(scope: "example-app-device") {
            Task {
//                try! await self.client.resetAIModelCache()
//                try! self.client.resetEmbeddingModelCache()
                await self.downloadModel()
            }
        } error: { error in
            self.errorState = true
            self.textResponse = error.message ?? error.localizedDescription
            self.setMessage()
        }
    }
    
    func downloadModel() async {
        await freeTokenClient.client.downloadAIModel { _ in
            self.loadModel()
        } error: { error in
            self.textResponse = error.message ?? error.localizedDescription
            self.setMessage()
        } progressPercent: { progressPercent in
            self.setDownloadPercent(progressPercent)
        }

    }
    
    func loadModel() {
        freeTokenClient.client.loadModel { _ in
            self.createMessageThread()
            self.freeTokenClient.registered = true
        } error: { error in
            self.textResponse = error.message ?? error.localizedDescription
            self.setMessage()
        }
    }
    
    func createMessageThread() {
        if errorState { return }
        
        freeTokenClient.client.createMessageThread { messageThread in
            self.messageThreadID = messageThread.id
            self.addMessageToThread()
        } error: { error in
            self.errorState = true
            self.textResponse = error.message!
            self.setMessage()
        }
    }
    
    func addMessageToThread(newMessage: Optional<String> = nil) {
        if errorState { return }
        var content = ""
        
        if newMessage != nil {
            content = newMessage!
        } else {
            content = "What is the weather in New York City?"
        }
        
        freeTokenClient.client.addMessageToThread(messageThreadID: self.messageThreadID!, role: "user", content: content) { message in
            print("Successfully added message to thread")
            self.runMessageThread()
//                self.generateLocalCompletion()
        } error: { error in
            self.errorState = true
            self.textResponse = error.message ?? error.localizedDescription
            self.setMessage()
        }
    }
    
    func runMessageThread() {
        if errorState { return }
        
        freeTokenClient.client.runMessageThread(id: self.messageThreadID!) { messageThreadRun in
            // Nothing to do here
            self.textResponse += "\n\n"
            self.setMessage()
        } error: { error in
            self.errorState = true
            self.textResponse = error.message!
            self.setMessage()
        } chatStatusStream: { token, status in
            if token != nil {
                self.textResponse += token!
            }
            
            self.statusResponse = status
            self.setMessage()
        } toolCallback: { functionCalls in
            var results = ""
            functionCalls.forEach { functionCall in
                print("Processing function call: \(functionCall.name)")
                if functionCall.name == "get_current_weather" {
                    if let location = functionCall.arguments["location"] {
                        let randomTemperature = Int.random(in: -20...90)
                        results += "The following is the realtime current weather for \(location): \(randomTemperature)F\n\n"
                    } else {
                        results += "A location was not specified with the function call, please try again."
                    }
                }
            }
            return results
        }
    }
    
    func generateLocalCompletion() async {
        await freeTokenClient.client.generateCompletion(prompt: "A supernova is") { completion in
            self.textResponse = completion.response
            self.setMessage()
        } error: { error in
            self.errorState = true
            self.textResponse = error.message ?? error.localizedDescription
            self.setMessage()
        }
    }
    
    func setMessage() {
        DispatchQueue.main.async {
            self.textData = self.textResponse
            self.statusData = self.statusResponse
        }
    }
    
    func setDownloadPercent(_ value: Double) {
        DispatchQueue.main.async {
            self.downloadProgress = value
        }
    }
}
