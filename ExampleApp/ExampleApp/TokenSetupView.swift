import SwiftUI

struct TokenSetupView: View {
    @ObservedObject var freeTokenClient: FreeTokenClient
    @State private var appToken: String = FreeTokenClient.DEFAULT_APP_TOKEN
    @State private var isTokenValid: Bool = true

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color(.systemBackground), Color(.secondarySystemBackground)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer()

                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "key.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.accentColor)

                        Text("FreeToken Kitchen Sink")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text("Review and confirm your app token")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 40)

                    // Token Entry Container
                    VStack(alignment: .center, spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("App Token")
                                .font(.headline)
                                .foregroundColor(.primary)

                            TextField("app_tkn_...", text: $appToken)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .onChange(of: appToken) { _ in
                                    isTokenValid = appToken.starts(with: "app_tkn_") && appToken.count > 10
                                }
                                .frame(maxWidth: 400)

                            Text("Modify the token above or paste a new one")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: 400)

                        // Helpful info box
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Developer Note", systemImage: "info.circle.fill")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)

                            Text("Default token loaded from:\n`FreeTokenClient.swift` line 7\nYou can modify it above before registering")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding()
                        .frame(maxWidth: 400)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.blue.opacity(0.1))
                        )

                        // Registration button
                        Button(action: {
                            Task {
                                await freeTokenClient.registerDevice(with: appToken)
                            }
                        }) {
                            HStack {
                                if freeTokenClient.isRegistering {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "arrow.right.circle.fill")
                                }
                                Text("Register with Token")
                            }
                            .frame(width: 400)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(freeTokenClient.isRegistering ? Color.gray : Color.accentColor)
                            )
                            .foregroundColor(.white)
                        }
                        .disabled(freeTokenClient.isRegistering || appToken.isEmpty || !isTokenValid)

                        // Error display
                        if let error = freeTokenClient.registrationError {
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Registration Failed", systemImage: "exclamationmark.triangle.fill")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.red)

                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding()
                            .frame(maxWidth: 400)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.red.opacity(0.1))
                            )
                        }

                        // Progress indicator for model download
                        if freeTokenClient.isDownloadingModel {
                            ModelDownloadProgressBar(progress: freeTokenClient.modelDownloadProgress)
                                .frame(maxWidth: 400)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }

                    Spacer()

                    // Footer
                    VStack(spacing: 8) {
                        if !appToken.isEmpty && isTokenValid {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text(appToken == FreeTokenClient.DEFAULT_APP_TOKEN ? "Using default token from code" : "Using custom token")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        } else if !appToken.isEmpty {
                            HStack {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.orange)
                                Text("Token should start with 'app_tkn_'")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            HStack {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundColor(.orange)
                                Text("Token is required")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
        }
    }
}

#Preview {
    TokenSetupView(freeTokenClient: FreeTokenClient())
}
