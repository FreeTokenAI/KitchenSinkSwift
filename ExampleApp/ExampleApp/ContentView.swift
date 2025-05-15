import SwiftUI

struct ContentView: View {
    @EnvironmentObject var freeTokenClient: FreeTokenClient
    @StateObject private var dataLoader: ChatLoader
    @State private var userInput: String = ""
    
    init(freeTokenClient: FreeTokenClient) {
        _dataLoader = StateObject(wrappedValue: ChatLoader(freeTokenClient: freeTokenClient))
    }
    
    var body: some View {
        ScrollView {
            VStack {
                if dataLoader.textData.isEmpty {
                    Text("Model Download:").padding()
                    ProgressView(value: dataLoader.downloadProgress, total: 1.0)
                        .progressViewStyle(LinearProgressViewStyle())
                        .padding()
                } else {
                    Text(dataLoader.textData)
                        .padding()
                    Text(dataLoader.statusData).padding()
                    
                    Button(action: {
                        Task {
                            dataLoader.resetText()
                            dataLoader.createMessageThread()
                        }
                    }) {
                        Text("Restart Chat")
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    TextField("New Message...", text: $userInput)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                    Button(action: {
                        dataLoader.addMessageToThread(newMessage: userInput)
                    }) {
                        Text("Add Message")
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
            }
            .task {
                await dataLoader.loadData()
            }
            .padding()
        }
    }
}
