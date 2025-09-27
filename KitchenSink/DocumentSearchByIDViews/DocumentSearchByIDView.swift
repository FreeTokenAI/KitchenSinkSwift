import SwiftUI
import FreeToken

struct DocumentSearchByIDView: View {
    @EnvironmentObject var freeTokenClient: FreeTokenClient
    @StateObject private var documentLoader: DocumentViewModel
    @State private var documentId: String = ""
    @State private var statusMessage: String = ""
    @State private var searchResult: FreeToken.Document? = nil
    @State private var isLoading: Bool = false
    @State private var documentStatus: DocumentStatus = .loading
    @Environment(\.dismiss) private var dismiss

    // Accessibility
    @AccessibilityFocusState private var isErrorFocused: Bool
    @AccessibilityFocusState private var isStatusFocused: Bool

    init(freeTokenClient: FreeTokenClient, documentLoader: DocumentViewModel) {
        _documentLoader = StateObject(wrappedValue: DocumentViewModel(freeTokenClient: freeTokenClient))
    }

    var trimmedDocumentId: String {
        documentId.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isInputValid: Bool {
        !trimmedDocumentId.isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Cyberpunk background
                CyberpunkTheme.Gradients.backgroundGradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 18) {
                        DocumentSearchByIDHeaderView()
                            .padding(.top, 18)
                            .accessibilityElement()
                            .accessibilityLabel("Search documents by ID header")
                            .accessibilityAddTraits(.isHeader)
                        DocumentSearchByIDCardView
                            .padding()
                            .accessibilityElement(children: .contain)
                            .accessibilityLabel("Document search card")
                    }
                }
            }
            .navigationTitle("SEARCH BY ID")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(CyberpunkTheme.Colors.cyberPanel, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }

    private var DocumentSearchByIDCardView: some View {
        VStack(spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text("DOCUMENT ID")
                    .font(.system(size: 12, weight: .semibold))
                    .textCase(.uppercase)
                    .kerning(0.8)
                    .foregroundColor(CyberpunkTheme.Colors.cyberGold)
                    .accessibilityLabel("Document ID input label")
                HStack {
                    TextField("ENTER DOCUMENT ID", text: $documentId)
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
                        .onSubmit {
                            Task { await searchDocument() }
                        }
                        .accessibilityLabel("Document ID input field")
                        .accessibilityHint("Enter the document ID to search")
                    if !documentId.isEmpty {
                        Button {
                            documentId = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(CyberpunkTheme.Colors.cyberMagenta)
                        }
                        .accessibilityLabel("Clear document ID")
                        .accessibilityHint("Clears the entered document ID")
                    }
                }
            }
            if !isInputValid && !documentId.isEmpty {
                Text("DOCUMENT ID CANNOT BE EMPTY OR WHITESPACE.")
                    .font(.system(size: 10, weight: .medium))
                    .textCase(.uppercase)
                    .kerning(0.6)
                    .foregroundColor(.red)
                    .neonGlow(color: .red, radius: 2)
                    .accessibilityLabel("Input error: Document ID cannot be empty or whitespace.")
                    .accessibilityAddTraits(.isStaticText)
                    .accessibilityHint("Please enter a valid document ID to continue.")
                    .accessibilityFocused($isErrorFocused)
                    .accessibilitySortPriority(3)
            }

            Button {
                Task { await searchDocument() }
            } label: {
                Text("SEARCH")
                    .font(.system(size: 14, weight: .bold))
                    .textCase(.uppercase)
                    .kerning(1.2)
                    .frame(maxWidth: .infinity)
            }
            .cyberButton()
            .disabled(!isInputValid)
            .accessibilityLabel("Search for document by ID")
            .accessibilityHint("Starts a search for the entered document ID")
            .accessibilityAddTraits(.isButton)
            .accessibilitySortPriority(2)

            if let result = searchResult {
                DocumentSearchByIDResultView(document: result)
                    .accessibilityElement(children: .contain)
                    .accessibilityLabel("Document found. Displaying details for ID \(result.id)")
                    .accessibilityHint("Shows the details of the found document")
                    .accessibilitySortPriority(1)
            } else if !statusMessage.isEmpty {
                DocumentStatusView(
                    message: statusMessage,
                    status: documentStatus
                )
                .accessibilityAddTraits(.isStaticText)
                .accessibilityHint("Status message for document search")
                .accessibilityFocused($isStatusFocused)
                .accessibilityElement(children: .contain)
                .accessibilitySortPriority(4)
            }

            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: CyberpunkTheme.Colors.cyberCyan))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .accessibilityLabel("Searching for document. Please wait.")
                    .accessibilityAddTraits(.updatesFrequently)
                    .accessibilityHint("The search is in progress and results will appear soon.")
                    .accessibilitySortPriority(5)
            }
        }
        .padding()
        .cyberPanel()
        .shadow(color: CyberpunkTheme.Colors.cyberMagenta.opacity(0.2), radius: 8)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Document search card")
        .accessibilityHint("Enter a document ID and search for details")
    }

    private func searchDocument() async {
        let trimmedId = documentId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedId.isEmpty else {
            statusMessage = "Please enter a valid document ID."
            searchResult = nil
            isLoading = false
            isErrorFocused = true
            isStatusFocused = false
            return
        }

        documentStatus = .loading
        statusMessage = "Searching..."
        searchResult = nil
        isLoading = true
        isErrorFocused = false
        isStatusFocused = true

        await documentLoader.getDocument(byID: trimmedId) { result in
            isLoading = false
            switch result {
            case .success(let document):
                searchResult = document
                statusMessage = ""
                documentStatus = .success
                isErrorFocused = false
                isStatusFocused = false
            case .failure(let error):
                searchResult = nil
                statusMessage = "Error: \(error.localizedDescription)"
                documentStatus = .error
                isErrorFocused = false
                isStatusFocused = true
            }
        }
    }
}