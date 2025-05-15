import SwiftUI
import FreeToken

class DocumentLoader: ObservableObject {
    private var freeTokenClient: FreeTokenClient
    
    init(freeTokenClient: FreeTokenClient) {
        self.freeTokenClient = freeTokenClient
    }
    
    func createDocument(metadata: String, body: String, searchScope: String, completion: @escaping (Bool, String) -> Void) {
        freeTokenClient.client.createDocument(
            content: body,
            metadata: metadata,
            searchScope: searchScope,
            success: { document in
                DispatchQueue.main.async {
                    completion(true, "Document created!\n\nID: \(document.id)\n\nSearchScope: \(searchScope)\n\nMetadata: \(metadata).\n\nPlease look in the Admin console for the content preview.")
                }
            },
            error: { error in
                DispatchQueue.main.async {
                    completion(false, "Failed to create document: \(error.localizedDescription)")
                }
            }
        )
    }
    
    func getDocument(byID id: String, completion: @escaping (Result<FreeToken.Document, Error>) -> Void) {
        freeTokenClient.client.getDocument(
            id: id,
            success: { document in
                DispatchQueue.main.async {
                    completion(.success(document))
                }
            },
            error: { error in
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        )
    }
    
    func searchDocuments(query: String, searchScope: String? = nil, maxResults: Int? = nil, completion: @escaping (Result<FreeToken.DocumentSearchResults, Error>) -> Void
    ) {
        freeTokenClient.client.searchDocuments(
            query: query,
            searchScope: searchScope,
            maxResults: maxResults,
            success: { results in
                DispatchQueue.main.async {
                    completion(.success(results))
                }
            },
            error: { error in
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        )
    }
}
