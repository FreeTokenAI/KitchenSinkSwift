import SwiftUI
import FreeToken

class DocumentViewModel: ObservableObject {
    private var freeTokenClient: FreeTokenClient
    
    init(freeTokenClient: FreeTokenClient) {
        self.freeTokenClient = freeTokenClient
    }
    
    @MainActor
    func createDocument(
        body: String,
        searchScope: String,
        metadata: String? = nil,
        completion: @escaping (Result<FreeToken.Document, Error>) -> Void
    ) async {
        await freeTokenClient.client.createDocument(
            content: body,
            metadata: metadata,
            searchScope: searchScope,
            success: { document in
                completion(.success(document))
            },
            error: { error in
                completion(.failure(error))
            }
        )
    }
    
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
    
    @MainActor
    func searchDocuments(query: String, searchScope: String? = nil, maxResults: Int? = nil, completion: @escaping (Result<[FreeToken.DocumentChunk], Error>) -> Void
    ) async {
        await freeTokenClient.client.searchDocuments(
            query: query,
            searchScope: searchScope,
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
