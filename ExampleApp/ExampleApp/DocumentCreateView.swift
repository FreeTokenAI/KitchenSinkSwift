import SwiftUI

struct DocumentCreateView: View {
    @StateObject private var documentLoader: DocumentViewModel
    @State private var documentMetadata: String = ""
    @State private var documentBody: String = ""
    @State private var searchScope: String = ""
    @State private var statusMessage: String = ""
    @State private var showValidationError: Bool = false
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

                    VStack(spacing: 18) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("User Defined Metadata (optional)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            ZStack(alignment: .topLeading) {
                                if documentMetadata.isEmpty {
                                    Text("Title: My Doc, URL: www.example.com")
                                        .foregroundStyle(Color.gray.opacity(0.5))
                                        .padding(8)
                                }
                                TextEditor(text: $documentMetadata)
                                    .frame(height: 60)
                                    .padding(8)
                                    .background(Color.clear)
                                    .foregroundColor(.primary)
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.accentColor.opacity(0.3), lineWidth: 1))
                                    .scrollContentBackground(.hidden)
                            }
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Text-only Content of the Document")
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
                                    .padding(8)
                                    .background(Color.clear)
                                    .foregroundColor(.primary)
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.accentColor.opacity(0.3), lineWidth: 1))
                                    .scrollContentBackground(.hidden)
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

                        Button(action: {
                            if canSubmit {
                                showValidationError = false
                                Task {
                                    await documentLoader.createDocument(
                                        body: documentBody,
                                        searchScope: searchScope,
                                        metadata: documentMetadata
                                    ) { success, message in
                                        statusMessage = message
                                    }
                                }
                            } else {
                                showValidationError = true
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
                        .disabled(!canSubmit)

                        if showValidationError {
                            Text("Body and scope are required.")
                                .foregroundColor(.red)
                                .font(.footnote)
                        }

                        if !statusMessage.isEmpty {
                            Text(statusMessage)
                                .foregroundColor(.gray)
                                .padding(.top, 8)
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
            .navigationTitle("Create Document")
        }
    }
}
