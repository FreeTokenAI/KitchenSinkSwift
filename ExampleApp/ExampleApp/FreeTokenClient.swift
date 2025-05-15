import Foundation
import FreeToken
import CryptoKit

class FreeTokenClient: ObservableObject {
    let encryptionKey = SymmetricKey(size: .bits256)
    var registered = false

    var client: FreeToken {
        if FreeToken.shared.isConfigured {
            return FreeToken.shared
        } else {
            return FreeToken.shared.configure(appToken: "app_tkn")
        }
    }
}
