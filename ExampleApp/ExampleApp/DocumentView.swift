import SwiftUI

struct DocumentView: View {
    private var freeTokenClient: FreeTokenClient
    @StateObject private var documentLoader: DocumentViewModel
    @State private var statusMessage: String = ""
    @State private var navigationPath = NavigationPath()

    init(freeTokenClient: FreeTokenClient) {
        self.freeTokenClient = freeTokenClient
        _documentLoader = StateObject(wrappedValue: DocumentViewModel(freeTokenClient: freeTokenClient))
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView {
                VStack(spacing: 28) {
                    VStack(alignment: .leading, spacing: 14) {
                        Label {
                            Text("Create new documents, search by document ID, or search for document chunks using a query. Choose an option below to get started.")
                        } icon: {
                            Image(systemName: "doc.text.magnifyingglass")
                                .foregroundColor(.accentColor)
                        }
                        .font(.body)
                        .foregroundColor(.primary)
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

                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        NavigationLink {
                            DocumentCreateView(
                                freeTokenClient: freeTokenClient,
                                documentLoader: documentLoader
                            )
                        } label: {
                            VStack(spacing: 12) {
                                Image(systemName: "plus.square.fill")
                                    .font(.system(size: 36))
                                    .foregroundColor(.accentColor)

                                Text("Create Document")
                                    .font(.headline)
                                    .foregroundColor(.primary)

                                Text("Add a new document to your vector store")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, minHeight: 160)
                            .background(Color(.systemBackground))
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.accentColor.opacity(0.2), lineWidth: 1)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())

                        NavigationLink {
                            CreatePrivateDocumentStoreView(
                                freeTokenClient: freeTokenClient,
                                documentLoader: documentLoader
                            )
                        } label: {
                            VStack(spacing: 12) {
                                Image(systemName: "lock.shield.fill")
                                    .font(.system(size: 36))
                                    .foregroundColor(.green)

                                Text("Private Store")
                                    .font(.headline)
                                    .foregroundColor(.primary)

                                Text("Create a secure private document store")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, minHeight: 160)
                            .background(Color(.systemBackground))
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.green.opacity(0.2), lineWidth: 1)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())

                        NavigationLink {
                            DocumentSearchByIDView(
                                freeTokenClient: freeTokenClient,
                                documentLoader: documentLoader
                            )
                        } label: {
                            VStack(spacing: 12) {
                                Image(systemName: "number.square")
                                    .font(.system(size: 36))
                                    .foregroundColor(.orange)

                                Text("Get by ID")
                                    .font(.headline)
                                    .foregroundColor(.primary)

                                Text("Find a specific document using its ID")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, minHeight: 160)
                            .background(Color(.systemBackground))
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())

                        NavigationLink {
                            DocumentSearchByQueryView(
                                freeTokenClient: freeTokenClient,
                                documentLoader: documentLoader
                            )
                        } label: {
                            VStack(spacing: 12) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 36))
                                    .foregroundColor(.blue)

                                Text("Search Documents")
                                    .font(.headline)
                                    .foregroundColor(.primary)

                                Text("Query document chunks with semantic search")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, minHeight: 160)
                            .background(Color(.systemBackground))
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }

                    if !statusMessage.isEmpty {
                        Text(statusMessage)
                            .foregroundColor(.gray)
                            .padding(.top, 8)
                    }
                }
                .padding()
            }
            .navigationTitle("Documents")
        }
    }
}
