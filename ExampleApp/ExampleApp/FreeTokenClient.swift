import Foundation
import FreeToken
import CryptoKit

class FreeTokenClient: ObservableObject {
    // Default app token - developers can modify this directly in code
    static let DEFAULT_APP_TOKEN = "app_tkn_951a73e1-3631-42ea-9a78-e1ae812e75e9"

    let encryptionKey = SymmetricKey(size: .bits256)

    // Registration state
    @Published var registered = false
    @Published var needsRegistration = true
    @Published var isRegistering = false
    @Published var registrationError: String?

    // Model download state
    @Published var isDownloadingModel = false
    @Published var modelDownloadProgress: Double = 0.0

    var client: FreeToken {
        return FreeToken.shared
    }

    init() {
        // Check if already configured
        if FreeToken.shared.isConfigured {
            self.registered = true
            self.needsRegistration = false
        }
    }

    // Main registration method that uses the provided token
    func registerDevice(with token: String) async {
        await MainActor.run {
            isRegistering = true
            registrationError = nil
        }

        // Use the provided token
        let appToken = token

        do {
            // Configure FreeToken with the app token
            _ = try FreeToken.shared.configure(appToken: appToken)

            // Register device session
            await client.registerDeviceSession(scope: "example-app-device", success: {
                await self.downloadModel()
            }, error: { error in
                ExampleAppLogger.shared.log("❌ Device registration failed: \(error)", level: .error)
                Task {
                    await MainActor.run {
                        self.registrationError = error.message
                        self.isRegistering = false
                    }
                }
            })
        } catch {
            ExampleAppLogger.shared.log("❌ Error configuring FreeToken: \(error.localizedDescription)", level: .error)
            await MainActor.run {
                self.registrationError = "Failed to configure FreeToken: \(error.localizedDescription)"
                self.isRegistering = false
            }
        }
    }

    private func downloadModel() async {
        await MainActor.run {
            self.isDownloadingModel = true
            self.modelDownloadProgress = 0.0
        }

        await client.downloadAIModel(success: { _ in
            await MainActor.run {
                self.isDownloadingModel = false
                self.modelDownloadProgress = 1.0
            }
            await self.loadModel()
        }, error: { error in
            ExampleAppLogger.shared.log("⚠️ Model download failed - continuing with cloud inference: \(error)", level: .warning)
            Task {
                await MainActor.run {
                    self.isDownloadingModel = false
                    self.registrationError = nil // Clear error as cloud inference is acceptable
                }
                // Continue with registration even if model download fails
                await self.completeRegistration()
            }
        }, progressPercent: { progressPercent in
            ExampleAppLogger.shared.log("📥 Model download progress: \(progressPercent)%")
            Task {
                await MainActor.run {
                    self.modelDownloadProgress = progressPercent
                }
            }
        })
    }

    private func loadModel() async {
        await client.loadModel(success: { _ in
            await self.completeRegistration()
        }, error: { error in
            ExampleAppLogger.shared.log("⚠️ Error loading model into memory - 📱 Continuing with cloud inference: \(error)", level: .warning)
            Task {
                // Continue with registration even if model load fails
                await self.completeRegistration()
            }
        })
    }

    private func completeRegistration() async {
        // Create initial message thread for the app
//        await createMessageThread()

        await MainActor.run {
            self.registered = true
            self.needsRegistration = false
            self.isRegistering = false
            self.registrationError = nil
        }

        ExampleAppLogger.shared.log("✅ Successfully registered device and completed setup")
    }

    // Reset device - clears all state and returns to registration screen
    func resetDevice() async {
        do {
            // Reset the FreeToken SDK
            try await client.resetDevice()

            // Reset our local state
            await MainActor.run {
                self.registered = false
                self.needsRegistration = true
                self.isRegistering = false
                self.registrationError = nil
                self.isDownloadingModel = false
                self.modelDownloadProgress = 0.0
            }

            ExampleAppLogger.shared.log("✅ Device reset successfully - returning to registration")
        } catch {
            ExampleAppLogger.shared.log("❌ Error resetting device: \(error.localizedDescription)", level: .error)
            await MainActor.run {
                self.registrationError = "Failed to reset device: \(error.localizedDescription)"
            }
        }
    }

}
