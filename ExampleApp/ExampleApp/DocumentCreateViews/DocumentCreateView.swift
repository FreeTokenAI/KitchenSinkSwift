import SwiftUI
import FreeToken

struct DocumentCreateView: View {
    @StateObject private var documentLoader: DocumentViewModel
    @State private var documentMetadata: String = ""
    @State private var documentBody: String = ""
    @State private var searchScope: String = ""
    @State private var privateDocumentStoreId: String = ""
    @State private var statusMessage: String = ""
    @State private var showValidationError: Bool = false
    @State private var documentStatus: DocumentStatus = .loading
    @State private var createdDocument: FreeToken.Document? = nil
    @Environment(\.dismiss) private var dismiss

    init(freeTokenClient: FreeTokenClient, documentLoader: DocumentViewModel) {
        _documentLoader = StateObject(wrappedValue: DocumentViewModel(freeTokenClient: freeTokenClient))
    }

    private var canSubmit: Bool {
        !documentBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !searchScope.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 12) {
                            DocumentCreateInfoView()
                                .accessibilityLabel("Document creation information")
                                .accessibilityAddTraits(.isHeader)

                            Text("Note: Documents created without a Private Document Store ID are public and can be accessed by anyone.")
                                .font(.caption)
                                .foregroundColor(.orange)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .background(Color.orange.opacity(0.1))
                                .cornerRadius(8)
                        }

                        DocumentCreateFieldView(
                            title: "User Defined Metadata (optional)",
                            placeholder: "Title: My Doc, URL: www.example.com",
                            text: $documentMetadata,
                            height: 60,
                            isMultiline: true
                        )
                        .accessibilityLabel("Metadata field")
                        .accessibilityHint("Enter optional metadata for your document")

                        DocumentCreateFieldView(
                            title: "Text-only Content of the Document",
                            placeholder: "Hello, world!",
                            text: $documentBody,
                            height: 180,
                            isMultiline: true
                        )
                        .accessibilityLabel("Document body field")
                        .accessibilityHint("Enter the main content of your document")
                        
                        DocumentCreateFieldView(
                            title: "String scope to use when looking up documents in Agents or via the API",
                            placeholder: "blog-posts",
                            text: $searchScope,
                            height: 180,
                            isMultiline: false
                        )
                        .accessibilityLabel("Document search scope description")
                        .accessibilityHint("Enter a scope string for document lookup")

                        DocumentCreateFieldView(
                            title: "Private Document Store ID (optional - leave empty for public document)",
                            placeholder: "Enter private store ID if you have one",
                            text: $privateDocumentStoreId,
                            height: 60,
                            isMultiline: false
                        )
                        .accessibilityLabel("Private document store ID")
                        .accessibilityHint("Optional: Enter a private store ID to make this document private")
                        
                        FormActionsView(
                            primaryLabel: "Create Document",
                            canPrimary: canSubmit,
                            showValidationError: showValidationError,
                            validationErrorMessage: "Please fill in required fields.",
                            showClear: createdDocument != nil || !statusMessage.isEmpty,
                            clearLabel: "Clear",
                            onPrimary: {
                                if canSubmit {
                                    showValidationError = false
                                    createDocument()
                                } else {
                                    showValidationError = true
                                }
                            },
                            onClear: {
                                documentMetadata = ""
                                documentBody = ""
                                searchScope = ""
                                privateDocumentStoreId = ""
                                statusMessage = ""
                                showValidationError = false
                                documentStatus = .loading
                                createdDocument = nil
                            }
                        )
                        .accessibilityElement(children: .contain)
                        .accessibilityLabel("Document actions")
                        .accessibilityHint("Create or clear the document")

                        if let document = createdDocument {
                            DocumentCreateResultView(document: document)
                                .padding(.top, 8)
                                .transition(.move(edge: .top).combined(with: .opacity))
                                .animation(.spring(), value: createdDocument != nil)
                                .accessibilityLabel("Document created successfully")
                                .accessibilityHint("Shows the details of the created document")
                        } else if !statusMessage.isEmpty {
                            DocumentStatusView(message: statusMessage, status: documentStatus)
                                .transition(.opacity)
                                .animation(.easeInOut, value: statusMessage)
                                .accessibilityHint(statusMessage)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(LinearGradient(
                                gradient: Gradient(colors: [Color(.systemBackground), Color(.systemGray6)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                    )
                    .shadow(color: Color.black.opacity(0.07), radius: 6, x: 0, y: 2)
                }
                .padding()
            }
            .navigationTitle("Create Document")
            .accessibilityLabel("Create Document screen")
        }
    }

    private func createDocument() {
        documentStatus = .loading
        statusMessage = privateDocumentStoreId.isEmpty ? "Creating Public Document..." : "Creating Private Document..."

        Task {
            do {
                try await documentLoader.createDocument(
                    body: documentBody,
                    searchScope: searchScope,
                    metadata: documentMetadata,
                    privateDocumentStoreId: privateDocumentStoreId.isEmpty ? nil : privateDocumentStoreId
                ) { result in
                    switch result {
                    case .success(let document):
                        createdDocument = document
                        statusMessage = privateDocumentStoreId.isEmpty ? "Public document created successfully!" : "Private document created successfully!"
                        documentStatus = .success
                    case .failure(let error):
                        createdDocument = nil
                        statusMessage = "Error: \(error.localizedDescription)"
                        documentStatus = .error
                    }
                }
            } catch {
                statusMessage = "Failed to create document"
                documentStatus = .error
            }
        }
    }
}
