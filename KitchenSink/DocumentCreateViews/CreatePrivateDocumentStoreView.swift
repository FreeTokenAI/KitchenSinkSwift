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
            ZStack {
                // Cyberpunk background
                CyberpunkTheme.Gradients.backgroundGradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 28) {
                        VStack(alignment: .leading, spacing: 16) {
                            VStack(alignment: .leading, spacing: 12) {
                                Label {
                                    Text("CREATE A PRIVATE DOCUMENT STORE TO KEEP YOUR DOCUMENTS SECURE. ONLY YOU WILL HAVE ACCESS TO DOCUMENTS IN THIS STORE.")
                                        .font(.system(size: 12, weight: .medium))
                                        .textCase(.uppercase)
                                        .kerning(0.8)
                                } icon: {
                                    Image(systemName: "lock.shield")
                                        .foregroundColor(CyberpunkTheme.Colors.cyberGreen)
                                        .neonGlow(color: CyberpunkTheme.Colors.cyberGreen, radius: 2)
                                }
                                .foregroundColor(CyberpunkTheme.Colors.cyberBlueLight)

                                Text("IMPORTANT: THE STORE ID WILL ONLY BE SHOWN ONCE AFTER CREATION. MAKE SURE TO SAVE IT SECURELY.")
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

                            VStack(alignment: .leading, spacing: 8) {
                                Text("STORE NAME")
                                    .font(.system(size: 12, weight: .semibold))
                                    .textCase(.uppercase)
                                    .kerning(0.8)
                                    .foregroundColor(CyberpunkTheme.Colors.cyberGold)

                                TextField("MY PRIVATE DOCUMENTS", text: $storeName)
                                    .font(.system(size: 13, weight: .regular, design: .monospaced))
                                    .foregroundColor(CyberpunkTheme.Colors.cyberCyan)
                                    .padding(10)
                                    .background(CyberpunkTheme.Colors.cyberPanel)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(CyberpunkTheme.Colors.cyberCyan.opacity(0.3), lineWidth: 1)
                                    )
                                    .disabled(showStoreCreated)
                            }

                            if !showStoreCreated {
                                Button(action: createStore) {
                                    HStack {
                                        if isCreating {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: CyberpunkTheme.Colors.cyberCyan))
                                                .scaleEffect(0.8)
                                        } else {
                                            Image(systemName: "plus.circle.fill")
                                        }
                                        Text(isCreating ? "CREATING..." : "CREATE STORE")
                                            .font(.system(size: 14, weight: .bold))
                                            .textCase(.uppercase)
                                            .kerning(1.2)
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                                .cyberButton()
                                .disabled(storeName.isEmpty || isCreating)
                            }

                            if let error = errorMessage {
                                Text(error.uppercased())
                                    .font(.system(size: 11, weight: .medium))
                                    .textCase(.uppercase)
                                    .kerning(0.6)
                                    .foregroundColor(.red)
                                    .neonGlow(color: .red, radius: 2)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.red.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.red.opacity(0.3), lineWidth: 1)
                                    )
                            }

                            if showStoreCreated {
                                VStack(alignment: .leading, spacing: 16) {
                                    VStack(alignment: .leading, spacing: 12) {
                                        Label {
                                            Text("STORE CREATED SUCCESSFULLY!")
                                                .font(.system(size: 14, weight: .bold))
                                                .textCase(.uppercase)
                                                .kerning(1.2)
                                        } icon: {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(CyberpunkTheme.Colors.cyberGreen)
                                                .neonGlow(color: CyberpunkTheme.Colors.cyberGreen, radius: 2)
                                        }
                                        .foregroundColor(CyberpunkTheme.Colors.cyberGreen)

                                        VStack(alignment: .leading, spacing: 8) {
                                            Text("STORE ID (SAVE THIS!):")
                                                .font(.system(size: 12, weight: .semibold))
                                                .textCase(.uppercase)
                                                .kerning(0.8)
                                                .foregroundColor(CyberpunkTheme.Colors.cyberGold)

                                            HStack {
                                                Text(createdStoreId)
                                                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                                                    .foregroundColor(CyberpunkTheme.Colors.cyberCyan)
                                                    .padding(8)
                                                    .background(CyberpunkTheme.Colors.cyberPanel)
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 8)
                                                            .stroke(CyberpunkTheme.Colors.cyberCyan.opacity(0.3), lineWidth: 1)
                                                    )
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
                                                        .foregroundColor(CyberpunkTheme.Colors.cyberCyan)
                                                        .neonGlow(color: CyberpunkTheme.Colors.cyberCyan, radius: 2)
                                                }
                                                .buttonStyle(BorderlessButtonStyle())
                                            }
                                        }
                                    }
                                    .padding()
                                    .background(CyberpunkTheme.Colors.cyberGreen.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(CyberpunkTheme.Colors.cyberGreen.opacity(0.3), lineWidth: 1)
                                    )

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
                                                Text("ADD DOCUMENT TO THIS STORE")
                                                    .font(.system(size: 14, weight: .bold))
                                                    .textCase(.uppercase)
                                                    .kerning(1.2)
                                            }
                                            .frame(maxWidth: .infinity)
                                        }
                                        .cyberButton()
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
            }
            .navigationTitle("PRIVATE DOCUMENT STORE")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(CyberpunkTheme.Colors.cyberPanel, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
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
        ZStack {
            // Cyberpunk background
            CyberpunkTheme.Gradients.backgroundGradient
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Label {
                                Text("ADDING DOCUMENT TO PRIVATE STORE")
                                    .font(.system(size: 14, weight: .bold))
                                    .textCase(.uppercase)
                                    .kerning(1.2)
                            } icon: {
                                Image(systemName: "lock.doc")
                                    .foregroundColor(CyberpunkTheme.Colors.cyberGreen)
                                    .neonGlow(color: CyberpunkTheme.Colors.cyberGreen, radius: 2)
                            }
                            .foregroundColor(CyberpunkTheme.Colors.cyberGreen)

                            Text("STORE ID: \(privateDocumentStoreId)")
                                .font(.system(size: 11, weight: .regular, design: .monospaced))
                                .foregroundColor(CyberpunkTheme.Colors.cyberCyan)
                                .padding(6)
                                .background(CyberpunkTheme.Colors.cyberPanel)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(CyberpunkTheme.Colors.cyberCyan.opacity(0.3), lineWidth: 1)
                                )
                        }
                        .padding()
                        .background(CyberpunkTheme.Colors.cyberGreen.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(CyberpunkTheme.Colors.cyberGreen.opacity(0.3), lineWidth: 1)
                        )

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
                    .cyberPanel()
                    .shadow(color: CyberpunkTheme.Colors.cyberMagenta.opacity(0.2), radius: 10)
                }
                .padding()
            }
        }
        .navigationTitle("CREATE PRIVATE DOCUMENT")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(CyberpunkTheme.Colors.cyberPanel, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
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