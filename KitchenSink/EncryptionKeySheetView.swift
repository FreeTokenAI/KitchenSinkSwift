import SwiftUI

struct EncryptionKeySheetView: View {
    @Binding var userPrivateKey: String
    @Binding var sharedPublicKey: String
    @Binding var isPresented: Bool

    var body: some View {
        NavigationView {
            ZStack {
                // Cyberpunk background
                CyberpunkTheme.Gradients.backgroundGradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        encryptionEnabledSection
                        userPrivateKeySection
                        sharedPublicKeySection
                        copyBothKeysButton
                        importantNotesSection
                        Spacer(minLength: 20)
                    }
                    .padding()
                }
            }
            .navigationTitle("ENCRYPTION KEYS")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(CyberpunkTheme.Colors.cyberPanel, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("DONE") {
                        isPresented = false
                    }
                    .font(.system(size: 14, weight: .bold))
                    .textCase(.uppercase)
                    .kerning(1.2)
                    .foregroundColor(CyberpunkTheme.Colors.cyberGreen)
                }
            }
        }
        .onAppear {
            print("EncryptionKeySheetView appeared with:")
            print("  User Private Key: '\(userPrivateKey)' (length: \(userPrivateKey.count))")
            print("  Shared Public Key: '\(sharedPublicKey)' (length: \(sharedPublicKey.count))")
        }
    }

    private var encryptionEnabledSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label {
                Text("ENCRYPTION ENABLED")
                    .font(.system(size: 16, weight: .bold))
                    .textCase(.uppercase)
                    .kerning(1.5)
                    .foregroundColor(CyberpunkTheme.Colors.cyberGreen)
                    .neonGlow(color: CyberpunkTheme.Colors.cyberGreen, radius: 2)
            } icon: {
                Image(systemName: "lock.shield.fill")
                    .foregroundColor(CyberpunkTheme.Colors.cyberGreen)
                    .neonGlow(color: CyberpunkTheme.Colors.cyberGreen, radius: 2)
            }

            Text("ALL DOCUMENTS AND MESSAGES WILL BE ENCRYPTED FOR THE REMAINDER OF THIS SESSION.")
                .font(.system(size: 12, weight: .medium))
                .textCase(.uppercase)
                .kerning(0.8)
                .foregroundColor(CyberpunkTheme.Colors.cyberBlueLight)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(CyberpunkTheme.Colors.cyberPanel)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(CyberpunkTheme.Colors.cyberGreen.opacity(0.5), lineWidth: 1)
                )
        )
        .shadow(color: CyberpunkTheme.Colors.cyberGreen.opacity(0.3), radius: 10)
    }

    private var userPrivateKeySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.lock.fill")
                    .foregroundColor(CyberpunkTheme.Colors.cyberCyan)
                    .neonGlow(color: CyberpunkTheme.Colors.cyberCyan, radius: 2)
                Text("USER PRIVATE KEY")
                    .font(.system(size: 14, weight: .bold))
                    .textCase(.uppercase)
                    .kerning(1.2)
                    .foregroundColor(CyberpunkTheme.Colors.cyberCyan)
            }

            Text("FOR ENCRYPTING YOUR PRIVATE DOCUMENTS AND MESSAGES")
                .font(.system(size: 10, weight: .medium))
                .textCase(.uppercase)
                .kerning(0.6)
                .foregroundColor(CyberpunkTheme.Colors.cyberBlueLight)

            keyDisplayView(key: userPrivateKey, keyType: "User Private")

            Button(action: {
                UIPasteboard.general.string = userPrivateKey
            }) {
                Label("COPY USER PRIVATE KEY", systemImage: "doc.on.doc")
                    .font(.system(size: 14, weight: .bold))
                    .textCase(.uppercase)
                    .kerning(1.2)
                    .frame(maxWidth: .infinity)
            }
            .cyberButton()
        }
    }

    private var copyBothKeysButton: some View {
        Button(action: {
            let combinedKeys = """
            USER PRIVATE KEY:
            \(userPrivateKey)

            SHARED PUBLIC KEY:
            \(sharedPublicKey)
            """
            UIPasteboard.general.string = combinedKeys
        }) {
            Label("COPY BOTH KEYS", systemImage: "doc.on.doc.fill")
                .font(.system(size: 14, weight: .bold))
                .textCase(.uppercase)
                .kerning(1.2)
                .frame(maxWidth: .infinity)
        }
        .cyberButton()
    }

    private var sharedPublicKeySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.2.fill")
                    .foregroundColor(CyberpunkTheme.Colors.cyberMagenta)
                    .neonGlow(color: CyberpunkTheme.Colors.cyberMagenta, radius: 2)
                Text("SHARED PUBLIC KEY")
                    .font(.system(size: 14, weight: .bold))
                    .textCase(.uppercase)
                    .kerning(1.2)
                    .foregroundColor(CyberpunkTheme.Colors.cyberMagenta)
            }

            Text("FOR ENCRYPTING PUBLIC DOCUMENTS ACCESSIBLE BY ALL USERS")
                .font(.system(size: 10, weight: .medium))
                .textCase(.uppercase)
                .kerning(0.6)
                .foregroundColor(CyberpunkTheme.Colors.cyberBlueLight)

            keyDisplayView(key: sharedPublicKey, keyType: "Shared Public")

            Button(action: {
                UIPasteboard.general.string = sharedPublicKey
            }) {
                Label("COPY SHARED PUBLIC KEY", systemImage: "doc.on.doc")
                    .font(.system(size: 14, weight: .bold))
                    .textCase(.uppercase)
                    .kerning(1.2)
                    .frame(maxWidth: .infinity)
            }
            .cyberButton()
        }
    }

    private func keyDisplayView(key: String, keyType: String) -> some View {
        Group {
            if key.isEmpty {
                Text("NO KEY GENERATED")
                    .font(.system(size: 12, weight: .medium))
                    .textCase(.uppercase)
                    .kerning(0.8)
                    .foregroundColor(CyberpunkTheme.Colors.cyberMagenta)
                    .italic()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ScrollView {
                    Text(key)
                        .font(.system(size: 13, weight: .regular, design: .monospaced))
                        .foregroundColor(CyberpunkTheme.Colors.cyberGold)
                        .textSelection(.enabled)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .id(key)  // Force view refresh when key changes
        .frame(maxWidth: .infinity, minHeight: 80, maxHeight: 120)
        .background(CyberpunkTheme.Colors.cyberPanel)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(CyberpunkTheme.Colors.cyberGold.opacity(0.3), lineWidth: 1)
        )
        .onAppear {
            print("\(keyType) KeyDisplayView appeared - key value: '\(key)' isEmpty: \(key.isEmpty)")
        }
    }

    private var importantNotesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label {
                Text("IMPORTANT")
                    .font(.system(size: 14, weight: .bold))
                    .textCase(.uppercase)
                    .kerning(1.2)
                    .foregroundColor(CyberpunkTheme.Colors.cyberOrange)
            } icon: {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(CyberpunkTheme.Colors.cyberOrange)
                    .neonGlow(color: CyberpunkTheme.Colors.cyberOrange, radius: 2)
            }

            Text("""
                • THESE KEYS ARE ONLY SHOWN ONCE
                • STORE THEM IN A SECURE PASSWORD MANAGER
                • WITHOUT THESE KEYS, ENCRYPTED DATA CANNOT BE RECOVERED
                • USER PRIVATE KEY: FOR YOUR PRIVATE DOCUMENTS AND MESSAGES
                • SHARED PUBLIC KEY: FOR PUBLIC DOCUMENTS ACCESSIBLE BY ALL USERS
                • BOTH KEYS ARE REQUIRED FOR FULL FUNCTIONALITY
                """)
                .font(.system(size: 10, weight: .medium))
                .textCase(.uppercase)
                .kerning(0.6)
                .foregroundColor(CyberpunkTheme.Colors.cyberBlueLight)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(CyberpunkTheme.Colors.cyberPanel)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(CyberpunkTheme.Colors.cyberOrange.opacity(0.5), lineWidth: 1)
                )
        )
        .shadow(color: CyberpunkTheme.Colors.cyberOrange.opacity(0.3), radius: 10)
    }
}