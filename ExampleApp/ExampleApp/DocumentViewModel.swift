import SwiftUI
import FreeToken

// MARK: - Document Management View Model
// Manages document creation, retrieval, and search for RAG (Retrieval-Augmented Generation)
// Documents are used to provide context to AI models for more accurate and contextual responses
// For complete RAG guide, see: https://docs.freetoken.ai/docs/guides/rag
class DocumentViewModel: ObservableObject {
    private var freeTokenClient: FreeTokenClient

    init(freeTokenClient: FreeTokenClient) {
        self.freeTokenClient = freeTokenClient
    }

    // MARK: - Document Creation
    // Creates a new document in the FreeToken document store for RAG
    // Documents can be searched and used as context in AI conversations
    // Search scope allows organizing documents by topic or domain
    // Private document stores provide data isolation for sensitive content
    // For document creation and RAG setup, see: https://docs.freetoken.ai/docs/guides/rag
    @MainActor
    func createDocument(
        body: String,
        searchScope: String,
        metadata: String? = nil,
        privateDocumentStoreId: String? = nil,
        completion: @escaping (Result<FreeToken.Document, Error>) -> Void
    ) async throws {
        try await freeTokenClient.client.createDocument(
            content: body,
            metadata: metadata,
            searchScope: searchScope,
            privateDocumentStoreID: privateDocumentStoreId,
            success: { document in
                completion(.success(document))
            },
            error: { error in
                completion(.failure(error))
            }
        )
    }
    
    // MARK: - Document Retrieval
    // Retrieves a document by its unique ID
    // Useful for viewing or editing previously created documents
    // For document management, see: https://docs.freetoken.ai/docs/guides/rag
    @MainActor
    func getDocument(byID id: String, completion: @escaping (Result<FreeToken.Document, Error>) -> Void) async {
        await freeTokenClient.client.getDocument(
            id: id,
            success: { document in
                completion(.success(document))
            },
            error: { error in
                completion(.failure(error))
            }
        )
    }
    
    // MARK: - Document Search
    // Searches documents using semantic search for RAG
    // Returns relevant document chunks that match the query
    // These chunks can be used as context for AI responses
    // Search scope and private stores allow filtering by domain/security requirements
    // For semantic search capabilities, see: https://docs.freetoken.ai/docs/guides/rag
    // RAG is automatically enabled when documents are uploaded and configured in the Agent
    @MainActor
    func searchDocuments(
        query: String,
        searchScope: String? = nil,
        privateDocumentStoreIds: [String]? = nil,
        maxResults: Int? = nil,
        completion: @escaping (Result<[FreeToken.DocumentChunk], Error>) -> Void
    ) async {
        await freeTokenClient.client.searchDocuments(
            query: query,
            searchScope: searchScope,
            privateDocumentStoreIds: privateDocumentStoreIds,
            maxResults: maxResults,
            success: { results in
                completion(.success(results.documentChunks))
            },
            error: { error in
                completion(.failure(error))
            }
        )
    }
}
