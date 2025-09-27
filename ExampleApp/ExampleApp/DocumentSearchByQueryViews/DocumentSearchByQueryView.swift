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
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else if !statusMessage.isEmpty {
                DocumentStatusView(message: statusMessage, status: documentStatus)
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Cyberpunk background
                CyberpunkTheme.Gradients.backgroundGradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 28) {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("ENTER A QUERY TO SEARCH FOR DOCUMENT CHUNKS IN YOUR APP'S VECTOR STORE. OPTIONALLY, SPECIFY A SEARCH SCOPE, PRIVATE STORE IDS, AND MAX RESULTS.")
                                .font(.system(size: 12, weight: .medium))
                                .textCase(.uppercase)
                                .kerning(0.8)
                                .foregroundColor(CyberpunkTheme.Colors.cyberBlueLight)

                            Text("NOTE: LEAVE PRIVATE STORE IDS EMPTY TO SEARCH ONLY PUBLIC DOCUMENTS.")
                                .font(.system(size: 10, weight: .medium))
                                .textCase(.uppercase)
                                .kerning(0.6)
                                .foregroundColor(CyberpunkTheme.Colors.cyberOrange)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .background(CyberpunkTheme.Colors.cyberOrange.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(CyberpunkTheme.Colors.cyberOrange.opacity(0.3), lineWidth: 1)
                                )
                        }
                        .padding()
                        .cyberPanel()
                        .shadow(color: CyberpunkTheme.Colors.cyberMagenta.opacity(0.2), radius: 8)

                        VStack(spacing: 18) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("DOCUMENT QUERY")
                                    .font(.system(size: 12, weight: .semibold))
                                    .textCase(.uppercase)
                                    .kerning(0.8)
                                    .foregroundColor(CyberpunkTheme.Colors.cyberGold)
                                TextField("ENTER DOCUMENT QUERY", text: $documentQuery)
                                    .font(.system(size: 13, weight: .regular, design: .monospaced))
                                    .foregroundColor(CyberpunkTheme.Colors.cyberCyan)
                                    .padding(8)
                                    .background(Color.clear)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(CyberpunkTheme.Colors.cyberCyan.opacity(0.3), lineWidth: 1)
                                    )
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                            }
                            if !isInputValid && !documentQuery.isEmpty {
                                Text("QUERY CANNOT BE EMPTY OR WHITESPACE.")
                                    .font(.system(size: 10, weight: .medium))
                                    .textCase(.uppercase)
                                    .kerning(0.6)
                                    .foregroundColor(.red)
                                    .neonGlow(color: .red, radius: 2)
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                Text("SEARCH SCOPE (OPTIONAL)")
                                    .font(.system(size: 12, weight: .semibold))
                                    .textCase(.uppercase)
                                    .kerning(0.8)
                                    .foregroundColor(CyberpunkTheme.Colors.cyberGold)
                                TextField("BLOG-POSTS", text: $documentSearchScope)
                                    .font(.system(size: 13, weight: .regular, design: .monospaced))
                                    .foregroundColor(CyberpunkTheme.Colors.cyberCyan)
                                    .padding(8)
                                    .background(Color.clear)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(CyberpunkTheme.Colors.cyberCyan.opacity(0.3), lineWidth: 1)
                                    )
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                Text("PRIVATE DOCUMENT STORE IDS (OPTIONAL, COMMA-SEPARATED)")
                                    .font(.system(size: 12, weight: .semibold))
                                    .textCase(.uppercase)
                                    .kerning(0.8)
                                    .foregroundColor(CyberpunkTheme.Colors.cyberGold)
                                TextField("STORE-ID-1, STORE-ID-2", text: $privateDocumentStoreIds)
                                    .font(.system(size: 13, weight: .regular, design: .monospaced))
                                    .foregroundColor(CyberpunkTheme.Colors.cyberCyan)
                                    .padding(8)
                                    .background(Color.clear)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(CyberpunkTheme.Colors.cyberGreen.opacity(0.3), lineWidth: 1)
                                    )
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                Text("NUMBER OF MAX RESULTS (OPTIONAL)")
                                    .font(.system(size: 12, weight: .semibold))
                                    .textCase(.uppercase)
                                    .kerning(0.8)
                                    .foregroundColor(CyberpunkTheme.Colors.cyberGold)
                                TextField("10", text: $documentMaxResultsString)
                                    .font(.system(size: 13, weight: .regular, design: .monospaced))
                                    .foregroundColor(CyberpunkTheme.Colors.cyberCyan)
                                    .padding(8)
                                    .background(Color.clear)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(CyberpunkTheme.Colors.cyberCyan.opacity(0.3), lineWidth: 1)
                                    )
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
                        .cyberPanel()
                        .shadow(color: CyberpunkTheme.Colors.cyberMagenta.opacity(0.2), radius: 8)
                    }
                    .padding()
                }
            }
            .navigationTitle("SEARCH BY QUERY")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(CyberpunkTheme.Colors.cyberPanel, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
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