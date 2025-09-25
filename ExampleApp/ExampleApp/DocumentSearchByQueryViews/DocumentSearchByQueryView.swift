import SwiftUI
import FreeToken

struct DocumentSearchByQueryView: View {
    @EnvironmentObject var freeTokenClient: FreeTokenClient
    @StateObject private var documentLoader: DocumentViewModel
    @State private var documentQuery: String = ""
    @State private var documentSearchScope: String = ""
    @State private var privateDocumentStoreIds: String = ""
    @State private var documentMaxResultsString: String = ""
    @State private var statusMessage: String = ""
    @State private var searchResults: [FreeToken.DocumentChunk] = []
    @State private var documentStatus: DocumentStatus = .loading
    @Environment(\.dismiss) private var dismiss

    init(freeTokenClient: FreeTokenClient, documentLoader: DocumentViewModel) {
        _documentLoader = StateObject(wrappedValue: DocumentViewModel(freeTokenClient: freeTokenClient))
    }

    private var trimmedQuery: String {
        documentQuery.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isInputValid: Bool {
        !trimmedQuery.isEmpty
    }
    
    private var canClear: Bool {
        !documentQuery.isEmpty ||
        !documentSearchScope.isEmpty ||
        !privateDocumentStoreIds.isEmpty ||
        !documentMaxResultsString.isEmpty ||
        !searchResults.isEmpty ||
        !statusMessage.isEmpty
    }
    
    // Logic for  loading and search results
    private var searchResultsDisplayView: some View {
        Group {
            if !searchResults.isEmpty {
                VStack(spacing: 12) {
                    ForEach(searchResults, id: \.documentID) { chunk in
                        DocumentSearchByQueryResultView(chunk: chunk)
                    }
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else if !statusMessage.isEmpty {
                DocumentStatusView(message: statusMessage, status: documentStatus)
            }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Enter a query to search for document chunks in your app's vector store. Optionally, specify a search scope, private store IDs, and max results.")
                            .font(.callout)
                            .foregroundColor(.secondary)

                        Text("Note: Leave Private Store IDs empty to search only public documents.")
                            .font(.caption)
                            .foregroundColor(.orange)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(8)
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
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.accentColor.opacity(0.3), lineWidth: 1.5))
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
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.accentColor.opacity(0.3), lineWidth: 1.5))
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Private Document Store IDs (optional, comma-separated)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            TextField("store-id-1, store-id-2", text: $privateDocumentStoreIds)
                                .padding(8)
                                .background(Color.clear)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.green.opacity(0.3), lineWidth: 1.5))
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
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.accentColor.opacity(0.3), lineWidth: 1.5))
                                .keyboardType(.numberPad)
                        }
                        
                        FormActionsView(
                            primaryLabel: "Search",
                            canPrimary: isInputValid,
                            showValidationError: !isInputValid && !documentQuery.isEmpty,
                            validationErrorMessage: "Query cannot be empty or whitespace.",
                            showClear: canClear,
                            clearLabel: "Clear",
                            onPrimary: {
                                Task { await searchDocument() }
                            },
                            onClear: {
                                clearFields()
                            }
                        )

                        searchResultsDisplayView
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

        documentStatus = .loading
        statusMessage = "Searching..."
        let maxResults = Int(documentMaxResultsString) ?? 10

        // Parse comma-separated store IDs
        let storeIds: [String]? = privateDocumentStoreIds.isEmpty ? nil :
            privateDocumentStoreIds.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }

        await documentLoader.searchDocuments(
            query: trimmed,
            searchScope: documentSearchScope,
            privateDocumentStoreIds: storeIds,
            maxResults: maxResults
        ) { result in
            switch result {
            case .success(let chunks):
                searchResults = chunks
                if chunks.count > 0 {
                    statusMessage = ""
                } else {
                    statusMessage = "No results found."
                }
                documentStatus = .success
            case .failure(let error):
                searchResults = []
                statusMessage = "Error: \(error.localizedDescription)"
                documentStatus = .error
            }
        }
    }
    
    private func clearFields() {
        documentQuery = ""
        documentSearchScope = ""
        privateDocumentStoreIds = ""
        documentMaxResultsString = ""
        searchResults = []
        statusMessage = ""
    }
}
