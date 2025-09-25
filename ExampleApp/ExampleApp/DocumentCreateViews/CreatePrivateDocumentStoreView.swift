import SwiftUI
import FreeToken

struct CreatePrivateDocumentStoreView: View {
    @State private var storeName: String = ""
    @State private var showStoreCreated = false
    @State private var createdStoreId: String = ""
    @State private var isCreating = false
    @State private var errorMessage: String?
    @State private var navigateToCreateDocument = false
    @Environment(\.dismiss) private var dismiss

    private let freeTokenClient: FreeTokenClient
    private let documentLoader: DocumentViewModel

    init(freeTokenClient: FreeTokenClient, documentLoader: DocumentViewModel) {
        self.freeTokenClient = freeTokenClient
        self.documentLoader = documentLoader
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 12) {
                            Label {
                                Text("Create a private document store to keep your documents secure. Only you will have access to documents in this store.")
                            } icon: {
                                Image(systemName: "lock.shield")
                                    .foregroundColor(.green)
                            }
                            .font(.body)
                            .foregroundColor(.primary)

                            Text("Important: The store ID will only be shown once after creation. Make sure to save it securely.")
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

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Store Name")
                                .font(.headline)
                                .foregroundColor(.primary)

                            TextField("My Private Documents", text: $storeName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .disabled(showStoreCreated)
                        }

                        if !showStoreCreated {
                            Button(action: createStore) {
                                HStack {
                                    if isCreating {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle())
                                            .scaleEffect(0.8)
                                    } else {
                                        Image(systemName: "plus.circle.fill")
                                    }
                                    Text(isCreating ? "Creating..." : "Create Store")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(storeName.isEmpty ? Color.gray : Color.accentColor)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                            .disabled(storeName.isEmpty || isCreating)
                        }

                        if let error = errorMessage {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.caption)
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(8)
                        }

                        if showStoreCreated {
                            VStack(alignment: .leading, spacing: 16) {
                                VStack(alignment: .leading, spacing: 12) {
                                    Label {
                                        Text("Store Created Successfully!")
                                    } icon: {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                    }
                                    .font(.headline)
                                    .foregroundColor(.green)

                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Store ID (Save this!):")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)

                                        HStack {
                                            Text(createdStoreId)
                                                .font(.system(.body, design: .monospaced))
                                                .foregroundColor(.primary)
                                                .padding(8)
                                                .background(Color(.systemGray6))
                                                .cornerRadius(8)
                                                .textSelection(.enabled)

                                            Button(action: {
                                                #if os(macOS)
                                                NSPasteboard.general.clearContents()
                                                NSPasteboard.general.setString(createdStoreId, forType: .string)
                                                #else
                                                UIPasteboard.general.string = createdStoreId
                                                #endif
                                            }) {
                                                Image(systemName: "doc.on.doc")
                                                    .foregroundColor(.accentColor)
                                            }
                                            .buttonStyle(BorderlessButtonStyle())
                                        }
                                    }
                                }
                                .padding()
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(12)

                                NavigationLink(
                                    destination: DocumentCreateViewWithStore(
                                        freeTokenClient: freeTokenClient,
                                        documentLoader: documentLoader,
                                        privateDocumentStoreId: createdStoreId
                                    ),
                                    isActive: $navigateToCreateDocument
                                ) {
                                    Button(action: {
                                        navigateToCreateDocument = true
                                    }) {
                                        HStack {
                                            Image(systemName: "doc.badge.plus")
                                            Text("Add Document to This Store")
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(12)
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .transition(.move(edge: .top).combined(with: .opacity))
                            .animation(.spring(), value: showStoreCreated)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Create Private Document Store")
        }
    }

    private func createStore() {
        isCreating = true
        errorMessage = nil

        Task {
            await freeTokenClient.client.createPrivateDocumentStore(
                name: storeName,
                success: { store in
                    DispatchQueue.main.async {
                        self.createdStoreId = store.id
                        self.showStoreCreated = true
                        self.isCreating = false
                    }
                },
                error: { error in
                    DispatchQueue.main.async {
                        self.errorMessage = error.localizedDescription
                        self.isCreating = false
                    }
                }
            )
        }
    }
}

struct DocumentCreateViewWithStore: View {
    @StateObject private var documentLoader: DocumentViewModel
    @State private var documentMetadata: String = ""
    @State private var documentBody: String = ""
    @State private var searchScope: String = ""
    @State private var statusMessage: String = ""
    @State private var showValidationError: Bool = false
    @State private var documentStatus: DocumentStatus = .loading
    @State private var createdDocument: FreeToken.Document? = nil
    @Environment(\.dismiss) private var dismiss

    private let privateDocumentStoreId: String
    private let freeTokenClient: FreeTokenClient

    init(freeTokenClient: FreeTokenClient, documentLoader: DocumentViewModel, privateDocumentStoreId: String) {
        self.freeTokenClient = freeTokenClient
        _documentLoader = StateObject(wrappedValue: documentLoader)
        self.privateDocumentStoreId = privateDocumentStoreId
    }

    private var canSubmit: Bool {
        !documentBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !searchScope.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Label {
                            Text("Adding document to private store")
                        } icon: {
                            Image(systemName: "lock.doc")
                                .foregroundColor(.green)
                        }
                        .font(.headline)

                        Text("Store ID: \(privateDocumentStoreId)")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.secondary)
                            .padding(6)
                            .background(Color(.systemGray6))
                            .cornerRadius(6)
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)

                    DocumentCreateFieldView(
                        title: "User Defined Metadata (optional)",
                        placeholder: "Title: My Doc, URL: www.example.com",
                        text: $documentMetadata,
                        height: 60,
                        isMultiline: true
                    )

                    DocumentCreateFieldView(
                        title: "Text-only Content of the Document",
                        placeholder: "Hello, world!",
                        text: $documentBody,
                        height: 180,
                        isMultiline: true
                    )

                    DocumentCreateFieldView(
                        title: "String scope to use when looking up documents in Agents or via the API",
                        placeholder: "blog-posts",
                        text: $searchScope,
                        height: 180,
                        isMultiline: false
                    )

                    FormActionsView(
                        primaryLabel: "Create Document in Private Store",
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
                            statusMessage = ""
                            showValidationError = false
                            documentStatus = .loading
                            createdDocument = nil
                        }
                    )

                    if let document = createdDocument {
                        DocumentCreateResultView(document: document)
                            .padding(.top, 8)
                            .transition(.move(edge: .top).combined(with: .opacity))
                            .animation(.spring(), value: createdDocument != nil)
                    } else if !statusMessage.isEmpty {
                        DocumentStatusView(message: statusMessage, status: documentStatus)
                            .transition(.opacity)
                            .animation(.easeInOut, value: statusMessage)
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
        .navigationTitle("Create Private Document")
    }

    private func createDocument() {
        documentStatus = .loading
        statusMessage = "Creating Document in Private Store..."

        Task {
            do {
                try await freeTokenClient.client.createDocument(
                    content: documentBody,
                    metadata: documentMetadata.isEmpty ? nil : documentMetadata,
                    searchScope: searchScope,
                    privateDocumentStoreID: privateDocumentStoreId,
                    success: { document in
                        DispatchQueue.main.async {
                            self.createdDocument = document
                            self.statusMessage = "Document created successfully in private store!"
                            self.documentStatus = .success
                        }
                    },
                    error: { error in
                        DispatchQueue.main.async {
                            self.createdDocument = nil
                            self.statusMessage = "Error: \(error.localizedDescription)"
                            self.documentStatus = .error
                        }
                    }
                )
            } catch {
                DispatchQueue.main.async {
                    self.statusMessage = "Failed to create document"
                    self.documentStatus = .error
                }
            }
        }
    }
}