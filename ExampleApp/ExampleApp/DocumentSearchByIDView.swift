import SwiftUI
import FreeToken

struct DocumentSearchByIdView: View {
    @EnvironmentObject var freeTokenClient: FreeTokenClient
    @StateObject private var documentLoader: DocumentViewModel
    @State private var documentId: String = ""
    @State private var statusMessage: String = ""
    @State private var searchResult: FreeToken.Document? = nil
    @Environment(\.dismiss) private var dismiss

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
                VStack(spacing: 28) {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Search Document by ID")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("Enter a document ID to retrieve its content from your app’s vector store.")
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
                            Text("Document ID")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            TextField("Enter Document ID", text: $documentId)
                                .padding(8)
                                .background(Color.clear)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.accentColor.opacity(0.3), lineWidth: 1))
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        }
                        if !isInputValid && !documentId.isEmpty {
                                                    Text("Document ID cannot be empty or whitespace.")
                                                        .font(.footnote)
                                                        .foregroundColor(.red)
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

                        if let result = searchResult {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Search Result")
                                    .font(.headline)
                                Text("ID: \(result.id)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text("Content: \(result.content)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .lineLimit(3)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
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
            .navigationTitle("Search by ID")
        }
    }

    private func searchDocument() async {
        let trimmedId = documentId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedId.isEmpty else {
            statusMessage = "Please enter a valid document ID."
            searchResult = nil
            return
        }

        statusMessage = "Searching..."
        searchResult = nil

        await documentLoader.getDocument(byID: trimmedId) { result in
            switch result {
            case .success(let document):
                searchResult = document
                statusMessage = ""
            case .failure(let error):
                searchResult = nil
                statusMessage = "Error: \(error.localizedDescription)"
            }
        }
    }
}
