import SwiftUI
import FreeToken

struct DocumentSearchByQueryView: View {
    @EnvironmentObject var freeTokenClient: FreeTokenClient
    @StateObject private var documentLoader: DocumentViewModel
    @State private var documentQuery: String = ""
    @State private var documentSearchScope: String = ""
    @State private var documentMaxResultsString: String = ""
    @State private var statusMessage: String = ""
    @State private var searchResults: [FreeToken.DocumentChunk] = []
    @Environment(\.dismiss) private var dismiss

    init(freeTokenClient: FreeTokenClient, documentLoader: DocumentViewModel) {
        _documentLoader = StateObject(wrappedValue: DocumentViewModel(freeTokenClient: freeTokenClient))
    }

    var trimmedQuery: String {
        documentQuery.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isInputValid: Bool {
        !trimmedQuery.isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Search Documents by Query")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("Enter a query to search for document chunks in your app’s vector store. Optionally, specify a search scope and max results.")
                            .font(.callout)
                            .foregroundColor(.secondary)
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

                    VStack(spacing: 18) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Document Query")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            TextField("Enter Document Query", text: $documentQuery)
                                .padding(8)
                                .background(Color.clear)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.accentColor.opacity(0.3), lineWidth: 1))
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        }
                        if !isInputValid && !documentQuery.isEmpty {
                            Text("Query cannot be empty or whitespace.")
                                .font(.footnote)
                                .foregroundColor(.red)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Search Scope (optional)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            TextField("blog-posts", text: $documentSearchScope)
                                .padding(8)
                                .background(Color.clear)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.accentColor.opacity(0.3), lineWidth: 1))
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Number of Max Results (optional)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            TextField("10", text: $documentMaxResultsString)
                                .padding(8)
                                .background(Color.clear)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.accentColor.opacity(0.3), lineWidth: 1))
                                .keyboardType(.numberPad)
                        }

                        Button("Search") {
                            Task { await searchDocument() }
                        }
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
                        .buttonStyle(PlainButtonStyle())
                        .disabled(!isInputValid)

                        if !searchResults.isEmpty {
                            VStack(spacing: 12) {
                                ForEach(searchResults, id: \.documentID) { chunk in
                                    VStack(alignment: .leading) {
                                        Text("Document ID: \(chunk.documentID)")
                                        Text("Metadata: \(chunk.documentMetadata)")
                                        Text("Content: \(chunk.contentChunk)")
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        } else if !statusMessage.isEmpty {
                            Text(statusMessage)
                                .font(.subheadline)
                                .foregroundColor(.red)
                        }
                    }
                    .padding()
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color(.systemBackground), Color(.systemGray6)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(14)
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 1)
                }
                .padding()
            }
            .navigationTitle("Search by Query")
        }
    }

    private func searchDocument() async {
        let trimmed = documentQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            statusMessage = "Please enter a valid document query."
            searchResults = []
            return
        }

        statusMessage = "Searching..."
        let maxResults = Int(documentMaxResultsString) ?? 10
        
        await documentLoader.searchDocuments(query: trimmed, searchScope: documentSearchScope, maxResults: maxResults) { result in
            switch result {
            case .success(let chunks):
                searchResults = chunks
                if chunks.count > 0 {
                    statusMessage = ""
                } else {
                    statusMessage = "No results found."
                }
            case .failure(let error):
                searchResults = []
                statusMessage = "Error: \(error.localizedDescription)"
            }
        }
    }
}
