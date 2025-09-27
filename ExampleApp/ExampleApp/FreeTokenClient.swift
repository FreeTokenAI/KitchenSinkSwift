import Foundation
import FreeToken
import CryptoKit

// MARK: - FreeToken SDK Client Wrapper
// This class manages the FreeToken SDK lifecycle and state for the application
// For complete setup guide, see: https://docs.freetoken.ai/docs/getting-started
class FreeTokenClient: ObservableObject {
    // Default app token - developers can modify this directly in code
    // To get your own app token:
    // 1. Visit https://console.freetoken.ai
    // 2. Create a new app in the Apps section
    // 3. Generate an App Token in the Manage App Tokens section
    // See: https://docs.freetoken.ai/docs/getting-started
    static let DEFAULT_APP_TOKEN = "app_tkn_951a73e1-3631-42ea-9a78-e1ae812e75e9"

    // Encryption key for secure data storage
    // Used with FreeToken's encryption features for protecting sensitive data
    // See: https://docs.freetoken.ai/docs/guides/encryption
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

    // MARK: - Device Registration
    // Main registration method that configures the SDK and establishes a device session
    // This is the first step after app installation to enable AI features
    // For detailed registration guide, see: https://docs.freetoken.ai/docs/getting-started
    func registerDevice(with token: String) async {
        await MainActor.run {
            isRegistering = true
            registrationError = nil
        }

        // Use the provided token
        let appToken = token

        do {
            // Step 1: Configure FreeToken with the app token
            // This initializes the SDK with your application credentials
            // See: https://docs.freetoken.ai/docs/getting-started
            _ = try FreeToken.shared.configure(appToken: appToken)

            // Step 2: Register device session with a unique scope
            // The scope helps organize and track device sessions
            // Success callback is called when registration is complete
            await client.registerDeviceSession(scope: "example-app-device", success: {
                // Complete registration immediately, download model in background
                await self.completeRegistration()

                // Start model download in background (non-blocking)
                Task {
                    await self.downloadModel()
                }
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

    // MARK: - Model Download
    // Downloads AI models for on-device inference
    // This enables offline AI capabilities and faster response times
    // For performance optimization, see: https://docs.freetoken.ai/docs/guides/performance
    // For automatic fallback between device/cloud, see: https://docs.freetoken.ai/docs/guides/automatic-device-fallbacks
    private func downloadModel() async {
        await MainActor.run {
            self.isDownloadingModel = true
            self.modelDownloadProgress = 0.0
        }

        // Download the AI model for local inference
        // If download fails, the SDK automatically falls back to cloud inference
        await client.downloadAIModel(success: { _ in
            ExampleAppLogger.shared.log("✅ Model downloaded successfully")
            await MainActor.run {
                self.modelDownloadProgress = 1.0
            }

            // Keep the progress bar visible for a moment before hiding
            Task {
                try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                await MainActor.run {
                    self.isDownloadingModel = false
                }
            }
        }, error: { error in
            ExampleAppLogger.shared.log("⚠️ Model download failed - continuing with cloud inference: \(error)", level: .warning)
            await MainActor.run {
                self.modelDownloadProgress = 0.0
            }

            // Keep error state visible briefly
            Task {
                try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                await MainActor.run {
                    self.isDownloadingModel = false
                }
            }
        }, progressPercent: { progressPercent in
            // progressPercent is already in 0.0-1.0 range (0.20 = 20%)
            ExampleAppLogger.shared.log("📥 Model download progress: \(Int(progressPercent * 100))%")
            Task {
                await MainActor.run {
                    self.modelDownloadProgress = progressPercent
                }
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

    // MARK: - Device Reset
    // Reset device - clears all state and returns to registration screen
    // This removes all cached data, models, and user sessions
    // Useful for testing or when switching users
    // For memory management best practices, see: https://docs.freetoken.ai/docs/guides/memory-management
    func resetDevice() async {
        do {
            // Reset the FreeToken SDK - clears all local data and models
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
