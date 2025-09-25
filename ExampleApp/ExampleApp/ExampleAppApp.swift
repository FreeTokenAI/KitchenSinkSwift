import SwiftUI

@main
struct ExampleAppApp: App {
    @StateObject var freeTokenClient = FreeTokenClient()

    var body: some Scene {
        WindowGroup {
            if !freeTokenClient.registered {
                TokenSetupView(freeTokenClient: freeTokenClient)
                    .animation(.easeInOut, value: freeTokenClient.registered)
            } else {
                TabView {
                    ContentView(freeTokenClient: freeTokenClient)
                        .tabItem {
                            Label("AI Messaging", systemImage: "bubble.left.and.bubble.right")
                        }
                    DocumentView(freeTokenClient: freeTokenClient)
                        .tabItem {
                            Label("Documents", systemImage: "doc.text")
                        }
                    AIModelsView(freeTokenClient: freeTokenClient)
                        .tabItem {
                            Label("AI Models", systemImage: "cpu.fill")
                        }
                }
                .animation(.easeInOut, value: freeTokenClient.registered)
            }
        }
    }
}