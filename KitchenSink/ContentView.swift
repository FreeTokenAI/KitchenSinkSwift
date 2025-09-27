import SwiftUI

struct ContentView: View {
    @EnvironmentObject var freeTokenClient: FreeTokenClient
    @StateObject private var chatLoader: ChatViewModel
    
    init(freeTokenClient: FreeTokenClient) {
        _chatLoader = StateObject(wrappedValue: ChatViewModel(freeTokenClient: freeTokenClient))
    }
    
    var body: some View {
        NavigationStack {
            ChatView(chatLoader: chatLoader)
        }
    }
}
