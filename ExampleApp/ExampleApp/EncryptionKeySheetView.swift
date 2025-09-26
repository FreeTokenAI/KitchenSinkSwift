import SwiftUI

struct EncryptionKeySheetView: View {
    @Binding var userPrivateKey: String
    @Binding var sharedPublicKey: String
    @Binding var isPresented: Bool

    var body: some View {
        NavigationView {
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
            .navigationTitle("Encryption Keys Generated")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        isPresented = false
                    }
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
            Label("Encryption Enabled", systemImage: "lock.shield.fill")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.green)

            Text("All documents and messages will be encrypted for the remainder of this session.")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
    }

    private var userPrivateKeySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.lock.fill")
                    .foregroundColor(.blue)
                Text("User Private Key")
                    .font(.headline)
                    .foregroundColor(.primary)
            }

            Text("For encrypting your private documents and messages")
                .font(.caption)
                .foregroundColor(.secondary)

            keyDisplayView(key: userPrivateKey, keyType: "User Private")

            Button(action: {
                UIPasteboard.general.string = userPrivateKey
            }) {
                Label("Copy User Private Key", systemImage: "doc.on.doc")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
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
            Label("Copy Both Keys", systemImage: "doc.on.doc.fill")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(.green)
    }

    private var sharedPublicKeySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.2.fill")
                    .foregroundColor(.purple)
                Text("Shared Public Key")
                    .font(.headline)
                    .foregroundColor(.primary)
            }

            Text("For encrypting public documents accessible by all users")
                .font(.caption)
                .foregroundColor(.secondary)

            keyDisplayView(key: sharedPublicKey, keyType: "Shared Public")

            Button(action: {
                UIPasteboard.general.string = sharedPublicKey
            }) {
                Label("Copy Shared Public Key", systemImage: "doc.on.doc")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.purple)
        }
    }

    private func keyDisplayView(key: String, keyType: String) -> some View {
        Group {
            if key.isEmpty {
                Text("No key generated")
                    .foregroundColor(.secondary)
                    .italic()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ScrollView {
                    Text(key)
                        .font(.system(size: 13, weight: .regular, design: .monospaced))
                        .foregroundColor(.primary)
                        .textSelection(.enabled)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .id(key)  // Force view refresh when key changes
        .frame(maxWidth: .infinity, minHeight: 80, maxHeight: 120)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(.separator), lineWidth: 1)
        )
        .onAppear {
            print("\(keyType) KeyDisplayView appeared - key value: '\(key)' isEmpty: \(key.isEmpty)")
        }
    }

    private var importantNotesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Important", systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundColor(.orange)

            Text("""
                • These keys are only shown once
                • Store them in a secure password manager
                • Without these keys, encrypted data cannot be recovered
                • User Private Key: For your private documents and messages
                • Shared Public Key: For public documents accessible by all users
                • Both keys are required for full functionality
                """)
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }
}