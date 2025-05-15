import SwiftUI

struct DocumentLoaderView: View {
    @EnvironmentObject var freeTokenClient: FreeTokenClient
    @StateObject private var documentLoader: DocumentLoader
    @State private var statusMessage: String = ""
    @State private var showCreateView = false

    init(freeTokenClient: FreeTokenClient) {
        _documentLoader = StateObject(wrappedValue: DocumentLoader(freeTokenClient: freeTokenClient))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    VStack(alignment: .leading, spacing: 14) {
                        Label {
                            Text("Create new documents, search by document ID, or search for document chunks using a query. Choose an option below to get started.")
                        } icon: {
                            Image(systemName: "doc.text.magnifyingglass")
                                .foregroundColor(.accentColor)
                        }
                        .font(.body)
                        .foregroundColor(.primary)
                    }
                    .padding()
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color(.systemGray6), Color(.systemGray5)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(14)
                    .shadow(color: Color.black.opacity(0.07), radius: 6, x: 0, y: 2)

                    VStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Create a document to be searched in your App’s vector store.", systemImage: "plus.square.fill")
                                .font(.callout)
                                .foregroundColor(.accentColor)
                            NavigationLink(
                                destination: DocumentCreateView(
                                    freeTokenClient: freeTokenClient,
                                    documentLoader: documentLoader
                                ),
                                isActive: $showCreateView
                            ) {
                                Button(action: { showCreateView = true }) {
                                    Text("Create Document")
                                        .fontWeight(.semibold)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(
                                            LinearGradient(
                                                gradient: Gradient(colors: [Color.accentColor, Color.accentColor.opacity(0.7)]),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .foregroundColor(.white)
                                        .cornerRadius(12)
                                        .shadow(color: Color.accentColor.opacity(0.15), radius: 4, x: 0, y: 2)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Label("Search for a document by ID.", systemImage: "number.square")
                                .font(.callout)
                                .foregroundColor(.secondary)
                            Button(action: {
                                // TODO: Implement getting document by ID
                            }) {
                                Text("TODO: Get Document by ID")
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.15)]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .foregroundColor(.primary)
                                    .cornerRadius(12)
                                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Label("Search for document chunks with a query.", systemImage: "magnifyingglass")
                                .font(.callout)
                                .foregroundColor(.secondary)
                            Button(action: {
                                // TODO: Implement searching documents
                            }) {
                                Text("TODO: Search Documents")
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.blue.opacity(0.5)]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                                    .shadow(color: Color.blue.opacity(0.10), radius: 3, x: 0, y: 1)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }

                    if !statusMessage.isEmpty {
                        Text(statusMessage)
                            .foregroundColor(.gray)
                            .padding(.top, 8)
                    }
                }
                .padding()
            }
            .navigationTitle("Document Loader")
        }
    }
}
