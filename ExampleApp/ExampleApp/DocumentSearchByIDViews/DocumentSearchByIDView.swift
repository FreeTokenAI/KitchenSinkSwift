
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
                .navigationTitle("Search by ID")
            }
        }
    }
        
    private var DocumentSearchByIDCardView: some View {
        VStack(spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Document ID")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Document ID input label")
                HStack {
                    TextField("Enter Document ID", text: $documentId)
                        .padding(8)
                        .background(Color.clear)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.accentColor.opacity(0.3), lineWidth: 1.5))
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
                                .foregroundColor(.secondary)
                        }
                        .accessibilityLabel("Clear document ID")
                        .accessibilityHint("Clears the entered document ID")
                    }
                }
            }
            if !isInputValid && !documentId.isEmpty {
                Text("Document ID cannot be empty or whitespace.")
                    .font(.footnote)
                    .foregroundColor(.red)
                    .accessibilityLabel("Input error: Document ID cannot be empty or whitespace.")
                    .accessibilityAddTraits(.isStaticText)
                    .accessibilityHint("Please enter a valid document ID to continue.")
                    .accessibilityFocused($isErrorFocused)
                    .accessibilitySortPriority(3)
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
                    .frame(maxWidth: .infinity)
                    .padding()
                    .accessibilityLabel("Searching for document. Please wait.")
                    .accessibilityAddTraits(.updatesFrequently)
                    .accessibilityHint("The search is in progress and results will appear soon.")
                    .accessibilitySortPriority(5)
            }
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
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 1)
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
