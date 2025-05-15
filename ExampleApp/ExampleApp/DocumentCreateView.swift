import SwiftUI

struct DocumentCreateView: View {
    @EnvironmentObject var freeTokenClient: FreeTokenClient
    @StateObject private var documentLoader: DocumentLoader
    @State private var documentMetadata: String = ""
    @State private var documentBody: String = ""
    @State private var searchScope: String = ""
    @State private var statusMessage: String = ""
    @Environment(\.dismiss) private var dismiss
    
    init(freeTokenClient: FreeTokenClient, documentLoader: DocumentLoader) {
        _documentLoader = StateObject(wrappedValue: DocumentLoader(freeTokenClient: freeTokenClient))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Label {
                            Text("Any document stored in your app’s vector store should be public data. It is not secure or protected from other users’ access.")
                        } icon: {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                        }
                        .font(.callout)
                        .foregroundColor(.red)
                        
                        Label {
                            Text("It is not recommended that you use the document store as a persistence store in your app. Only use it for context to be provided to an AI.")
                        } icon: {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.orange)
                        }
                        .font(.callout)
                        .foregroundColor(.orange)
                        
                        Label {
                            Text("For large documents, break them into chunks. Large documents may hit an upload error.")
                        } icon: {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(.blue)
                        }
                        .font(.callout)
                        .foregroundColor(.blue)
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
                }
                
                Section(header: Text("Document Info").font(.headline)) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("User defined metadata")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        ZStack(alignment: .topLeading) {
                            if documentMetadata.isEmpty {
                                Text("Title: My Doc, URL: www.example.com")
                                    .foregroundStyle(Color.gray.opacity(0.5))
                                    .padding(4)
                            }
                            TextEditor(text: $documentMetadata)
                                .frame(height: 60)
                                .padding(4)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.accentColor.opacity(0.3), lineWidth: 1))
                        }
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Text-only content of the document")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        ZStack(alignment: .topLeading) {
                            if documentBody.isEmpty {
                                Text("Hello, world!")
                                    .foregroundStyle(Color.gray.opacity(0.5))
                                    .padding(8)
                            }
                            TextEditor(text: $documentBody)
                                .frame(height: 180)
                                .padding(4)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.accentColor.opacity(0.3), lineWidth: 1))
                        }
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text("String scope to use when looking up documents in Agents or via the API")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        TextField("blog-posts", text: $searchScope)
                            .padding(8)
                            .background(Color.clear)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.accentColor.opacity(0.3), lineWidth: 1))
                    }
                }
                
                Section {
                    Button(action: {
                        documentLoader.createDocument(
                            metadata: documentMetadata,
                            body: documentBody,
                            searchScope: searchScope
                        ) { success, message in
                            statusMessage = message
                        }
                    }) {
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
                    
                    if !statusMessage.isEmpty {
                        Text(statusMessage)
                            .foregroundColor(.gray)
                            .padding(.top, 8)
                    }
                }
            }
            .navigationTitle("Create Document")
            .scrollContentBackground(.hidden)
        }
    }
}
