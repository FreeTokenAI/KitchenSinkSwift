import SwiftUI

struct TokenSetupView: View {
    @ObservedObject var freeTokenClient: FreeTokenClient
    @State private var appToken: String = FreeTokenClient.DEFAULT_APP_TOKEN
    @State private var isTokenValid: Bool = true
    @State private var isTextFieldFocused: Bool = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Cyberpunk Background gradient
                CyberpunkTheme.Gradients.backgroundGradient
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer()

                    // Header with Logo
                    VStack(spacing: 20) {
                        // Logo
                        Image("Logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120, height: 120)
                            .pulseEffect()

                        VStack(spacing: 8) {
                            Text("FREETOKEN")
                                .font(.system(size: 36, weight: .bold))
                                .textCase(.uppercase)
                                .kerning(4)
                                .foregroundStyle(CyberpunkTheme.Gradients.goldGradient)
                                .shadow(color: CyberpunkTheme.Colors.cyberGold.opacity(0.5), radius: 10)

                            Text("KITCHEN SINK")
                                .font(.system(size: 20, weight: .semibold))
                                .textCase(.uppercase)
                                .kerning(3)
                                .foregroundColor(CyberpunkTheme.Colors.cyberCyan)
                                .shadow(color: CyberpunkTheme.Colors.cyberCyan.opacity(0.5), radius: 5)
                        }

                        Text("AUTHENTICATE YOUR APP TOKEN")
                            .font(.system(size: 12, weight: .medium))
                            .textCase(.uppercase)
                            .kerning(1.5)
                            .foregroundColor(CyberpunkTheme.Colors.cyberMagenta)
                    }
                    .padding(.bottom, 40)

                    // Token Entry Container
                    VStack(alignment: .center, spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("APP TOKEN")
                                .font(.system(size: 14, weight: .bold))
                                .textCase(.uppercase)
                                .kerning(1.5)
                                .foregroundColor(CyberpunkTheme.Colors.cyberCyan)

                            TextField("app_tkn_...", text: $appToken, onEditingChanged: { editing in
                                isTextFieldFocused = editing
                            })
                            .textFieldStyle(PlainTextFieldStyle())
                            .cyberTextField(isEditing: $isTextFieldFocused)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .font(.system(.body, design: .monospaced))
                            .onChange(of: appToken) { _ in
                                isTokenValid = appToken.starts(with: "app_tkn_") && appToken.count > 10
                            }
                            .frame(maxWidth: 400)

                            Text("MODIFY THE TOKEN OR PASTE A NEW ONE")
                                .font(.system(size: 10, weight: .medium))
                                .textCase(.uppercase)
                                .kerning(0.8)
                                .foregroundColor(CyberpunkTheme.Colors.cyberBlueLight)
                        }
                        .frame(maxWidth: 400)

                        // Helpful info box with cyberpunk styling
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(CyberpunkTheme.Colors.cyberMagenta)
                                    .neonGlow(color: CyberpunkTheme.Colors.cyberMagenta, radius: 5)
                                Text("DEVELOPER NOTE")
                                    .font(.system(size: 12, weight: .bold))
                                    .textCase(.uppercase)
                                    .kerning(1)
                                    .foregroundColor(CyberpunkTheme.Colors.cyberMagenta)
                            }

                            Text("DEFAULT TOKEN LOADED FROM:\n`FREETOKENCLIENT.SWIFT` LINE 7\nMODIFY BEFORE REGISTERING")
                                .font(.system(size: 11, design: .monospaced))
                                .textCase(.uppercase)
                                .foregroundColor(CyberpunkTheme.Colors.cyberBlueLight)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding()
                        .frame(maxWidth: 400)
                        .cyberPanel()

                        // Registration button with cyberpunk styling
                        Button(action: {
                            Task {
                                await freeTokenClient.registerDevice(with: appToken)
                            }
                        }) {
                            HStack(spacing: 12) {
                                if freeTokenClient.isRegistering {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "chevron.right.2")
                                        .font(.system(size: 16, weight: .bold))
                                }
                                Text("REGISTER WITH TOKEN")
                                    .font(.system(size: 14, weight: .bold))
                                    .textCase(.uppercase)
                                    .kerning(2)
                            }
                            .frame(maxWidth: .infinity)
                            .cyberButton(isPrimary: !freeTokenClient.isRegistering && isTokenValid)
                        }
                        .disabled(freeTokenClient.isRegistering || appToken.isEmpty || !isTokenValid)
                        .frame(maxWidth: 400)
                        .padding(.horizontal)

                        // Error display with cyberpunk styling
                        if let error = freeTokenClient.registrationError {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.red)
                                        .neonGlow(color: .red, radius: 5)
                                    Text("REGISTRATION FAILED")
                                        .font(.system(size: 12, weight: .bold))
                                        .textCase(.uppercase)
                                        .kerning(1)
                                        .foregroundColor(.red)
                                }

                                Text(error.uppercased())
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(Color.red.opacity(0.9))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding()
                            .frame(maxWidth: 400)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.red.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.red.opacity(0.3), lineWidth: 1)
                                    )
                            )
                            .shadow(color: .red.opacity(0.3), radius: 10)
                        }

                        // Removed model download progress - now shown globally
                    }

                    Spacer()

                    // Footer with cyberpunk styling
                    VStack(spacing: 8) {
                        if !appToken.isEmpty && isTokenValid {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.shield.fill")
                                    .foregroundColor(CyberpunkTheme.Colors.cyberGreen)
                                    .neonGlow(color: CyberpunkTheme.Colors.cyberGreen, radius: 5)
                                Text(appToken == FreeTokenClient.DEFAULT_APP_TOKEN ? "USING DEFAULT TOKEN" : "USING CUSTOM TOKEN")
                                    .font(.system(size: 11, weight: .semibold))
                                    .textCase(.uppercase)
                                    .kerning(1)
                                    .foregroundColor(CyberpunkTheme.Colors.cyberGreen)
                            }
                        } else if !appToken.isEmpty {
                            HStack(spacing: 8) {
                                Image(systemName: "xmark.octagon.fill")
                                    .foregroundColor(CyberpunkTheme.Colors.cyberOrange)
                                    .neonGlow(color: CyberpunkTheme.Colors.cyberOrange, radius: 5)
                                Text("TOKEN MUST START WITH 'APP_TKN_'")
                                    .font(.system(size: 11, weight: .semibold))
                                    .textCase(.uppercase)
                                    .kerning(1)
                                    .foregroundColor(CyberpunkTheme.Colors.cyberOrange)
                            }
                        } else {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.octagon.fill")
                                    .foregroundColor(CyberpunkTheme.Colors.cyberOrange)
                                    .neonGlow(color: CyberpunkTheme.Colors.cyberOrange, radius: 5)
                                Text("TOKEN REQUIRED")
                                    .font(.system(size: 11, weight: .semibold))
                                    .textCase(.uppercase)
                                    .kerning(1)
                                    .foregroundColor(CyberpunkTheme.Colors.cyberOrange)
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
