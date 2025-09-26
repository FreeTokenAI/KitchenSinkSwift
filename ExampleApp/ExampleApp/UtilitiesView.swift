import SwiftUI
import FreeToken

struct UtilitiesView: View {
    private var freeTokenClient: FreeTokenClient
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showingEncryptionKey = false
    @State private var generatedUserPrivateKey = ""
    @State private var generatedSharedPublicKey = ""
    @State private var isEncryptionEnabled = false
    @State private var showingResetConfirmation = false
    @State private var isResetting = false
    @State private var showingTokenCounter = false

    init(freeTokenClient: FreeTokenClient) {
        self.freeTokenClient = freeTokenClient
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    headerView
                    utilityButtonsGrid
                }
                .padding()
            }
            .navigationTitle("Utilities")
            .alert(alertTitle, isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
            .sheet(isPresented: $showingEncryptionKey) {
                EncryptionKeySheetView(
                    userPrivateKey: $generatedUserPrivateKey,
                    sharedPublicKey: $generatedSharedPublicKey,
                    isPresented: $showingEncryptionKey
                )
            }
            .sheet(isPresented: $showingTokenCounter) {
                TokenCounterView(
                    isPresented: $showingTokenCounter,
                    freeTokenClient: freeTokenClient
                )
            }
            .onChange(of: generatedUserPrivateKey) { newValue in
                print("generatedUserPrivateKey changed to: '\(newValue)' (length: \(newValue.count))")
            }
            .onChange(of: generatedSharedPublicKey) { newValue in
                print("generatedSharedPublicKey changed to: '\(newValue)' (length: \(newValue.count))")
            }
            .confirmationDialog(
                "Reset Device",
                isPresented: $showingResetConfirmation,
                titleVisibility: .visible
            ) {
                Button("Reset Device", role: .destructive) {
                    Task {
                        await performDeviceReset()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will reset your device registration and clear the current session. You will need to register again to continue using the app.")
            }
            .disabled(isResetting)
            .overlay {
                if isResetting {
                    ZStack {
                        Color.black.opacity(0.5)
                            .ignoresSafeArea()

                        VStack(spacing: 20) {
                            ProgressView()
                                .scaleEffect(1.5)
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))

                            Text("Resetting Device...")
                                .font(.headline)
                                .foregroundColor(.white)

                            Text("Please wait while we reset the client")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(30)
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(20)
                    }
                }
            }
        }
    }

    private var headerView: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label {
                Text("Manage your device settings, reset caches, and perform other utility functions.")
            } icon: {
                Image(systemName: "wrench.and.screwdriver")
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
    }

    private var utilityButtonsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            UtilityButtonView(
                icon: "lock.fill",
                iconColor: .green,
                title: "Enable Encryption",
                description: "Generate an Encryption Key and Enable Encryption"
            ) {
                Task { @MainActor in
                    enableEncryption()
                }
            }

            UtilityButtonView(
                icon: "arrow.triangle.2.circlepath",
                iconColor: .red,
                title: "Reset Device",
                description: "Reset your device settings & models"
            ) {
                showingResetConfirmation = true
            }

            UtilityButtonView(
                icon: "trash",
                iconColor: .orange,
                title: "Reset Model Caches",
                description: "Clear all downloaded AI models"
            ) {
                Task {
                    await resetModelCaches()
                }
            }

            UtilityButtonView(
                icon: "bubble.left.and.bubble.right.fill",
                iconColor: .blue,
                title: "Reset Chat Caches",
                description: "Clear model context chat caches"
            ) {
                Task {
                    await resetChatCache()
                }
            }

            UtilityButtonView(
                icon: "square.stack.3d.down.right.fill",
                iconColor: .purple,
                title: "Reset Embedding Model Cache",
                description: "Clear cached embedding model"
            ) {
                Task {
                    await resetEmbeddingModelCache()
                }
            }

            UtilityButtonView(
                icon: "number",
                iconColor: .teal,
                title: "Count Tokens",
                description: "Calculate token usage for text"
            ) {
                showingTokenCounter = true
            }
        }
    }

    @MainActor
    private func enableEncryption() {
        // Generate both keys
        let userPrivateKey = freeTokenClient.client.enableEncryption(scope: .userPrivate)
        let sharedPublicKey = freeTokenClient.client.enableEncryption(scope: .sharedPublic)

        print("Generated user private key: \(userPrivateKey)")
        print("Generated shared public key: \(sharedPublicKey)")
        print("User private key length: \(userPrivateKey.count)")
        print("Shared public key length: \(sharedPublicKey.count)")

        // Set state directly since we're already on main thread
        generatedUserPrivateKey = userPrivateKey
        generatedSharedPublicKey = sharedPublicKey
        isEncryptionEnabled = true

        print("State updated - userPrivateKey: \(generatedUserPrivateKey)")
        print("State updated - sharedPublicKey: \(generatedSharedPublicKey)")

        // Show sheet after state is set
        if !userPrivateKey.isEmpty && !sharedPublicKey.isEmpty {
            showingEncryptionKey = true
            print("Showing sheet with both keys in state")
        }
    }

    private func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showingAlert = true
    }

    @MainActor
    private func performDeviceReset() async {
        isResetting = true
        print("Starting device reset...")

        // Call the reset method on FreeTokenClient
        await freeTokenClient.resetDevice()

        // The app will automatically show the registration screen
        // because freeTokenClient.registered is now false
        isResetting = false
        print("Device reset completed")
    }

    @MainActor
    private func resetChatCache() async {
        do {
            // Call the FreeToken SDK to reset chat cache
            try await freeTokenClient.client.resetChatCache()

            // Show success alert
            showAlert(title: "Success", message: "Chat Cache was Reset Successfully")
            print("Chat cache reset successfully")
        } catch {
            // Show error alert if something goes wrong
            showAlert(title: "Error", message: "Failed to reset chat cache: \(error.localizedDescription)")
            print("Failed to reset chat cache: \(error)")
        }
    }

    @MainActor
    private func resetModelCaches() async {
        do {
            // Call the FreeToken SDK to reset model caches
            try await freeTokenClient.client.resetModelCaches()

            // Show success alert
            showAlert(title: "Success", message: "Model Caches were Reset Successfully")
            print("Model caches reset successfully")
        } catch {
            // Show error alert if something goes wrong
            showAlert(title: "Error", message: "Failed to reset model caches: \(error.localizedDescription)")
            print("Failed to reset model caches: \(error)")
        }
    }

    @MainActor
    private func resetEmbeddingModelCache() async {
        do {
            // Call the FreeToken SDK to reset embedding model cache
            try await freeTokenClient.client.resetEmbeddingModelCache()

            // Show success alert
            showAlert(title: "Success", message: "Embedding Model Cache was Reset Successfully")
            print("Embedding model cache reset successfully")
        } catch {
            // Show error alert if something goes wrong
            showAlert(title: "Error", message: "Failed to reset embedding model cache: \(error.localizedDescription)")
            print("Failed to reset embedding model cache: \(error)")
        }
    }
}
