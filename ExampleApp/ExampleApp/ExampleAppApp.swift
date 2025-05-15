import SwiftUI

@main
struct ExampleAppApp: App {
    @StateObject var freeTokenClient = FreeTokenClient()
    
    var body: some Scene {
        WindowGroup {
            TabView {
                ContentView(freeTokenClient: freeTokenClient)
                    .tabItem {
                        Label("ChatLoader", systemImage: "bubble.left.and.bubble.right")
                    }
                DocumentLoaderView(freeTokenClient: freeTokenClient)
                    .environmentObject(freeTokenClient)
                    .tabItem {
                        Label("DocumentLoader", systemImage: "doc.text")
                    }
            }
        }
    }
}
