import SwiftUI

struct DocumentView: View {
    private var freeTokenClient: FreeTokenClient
    @StateObject private var documentLoader: DocumentViewModel
    @State private var statusMessage: String = ""
    @State private var navigationPath = NavigationPath()

    init(freeTokenClient: FreeTokenClient) {
        self.freeTokenClient = freeTokenClient
        _documentLoader = StateObject(wrappedValue: DocumentViewModel(freeTokenClient: freeTokenClient))
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                // Cyberpunk background
                CyberpunkTheme.Gradients.backgroundGradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 28) {
                        VStack(alignment: .leading, spacing: 14) {
                            Label {
                                Text("CREATE NEW DOCUMENTS, SEARCH BY DOCUMENT ID, OR SEARCH FOR DOCUMENT CHUNKS USING A QUERY. CHOOSE AN OPTION BELOW TO GET STARTED.")
                                    .textCase(.uppercase)
                                    .font(.system(size: 12, weight: .medium))
                                    .kerning(0.8)
                            } icon: {
                                Image(systemName: "doc.text.magnifyingglass")
                                    .foregroundColor(CyberpunkTheme.Colors.cyberCyan)
                                    .neonGlow(color: CyberpunkTheme.Colors.cyberCyan, radius: 2)
                            }
                            .foregroundColor(CyberpunkTheme.Colors.cyberBlueLight)
                        }
                        .padding()
                        .cyberPanel()
                        .shadow(color: CyberpunkTheme.Colors.cyberMagenta.opacity(0.3), radius: 10)

                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        NavigationLink {
                            DocumentCreateView(
                                freeTokenClient: freeTokenClient,
                                documentLoader: documentLoader
                            )
                        } label: {
                            VStack(spacing: 12) {
                                Image(systemName: "plus.square.fill")
                                    .font(.system(size: 36))
                                    .foregroundColor(CyberpunkTheme.Colors.cyberGold)
                                    .neonGlow(color: CyberpunkTheme.Colors.cyberGold, radius: 3)

                                Text("CREATE DOCUMENT")
                                    .font(.system(size: 14, weight: .bold))
                                    .textCase(.uppercase)
                                    .kerning(1.2)
                                    .foregroundColor(CyberpunkTheme.Colors.cyberGold)

                                Text("ADD A NEW DOCUMENT TO YOUR VECTOR STORE")
                                    .font(.system(size: 10, weight: .medium))
                                    .textCase(.uppercase)
                                    .kerning(0.6)
                                    .foregroundColor(CyberpunkTheme.Colors.cyberBlueLight)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, minHeight: 160)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(CyberpunkTheme.Colors.cyberPanel)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(.ultraThinMaterial)
                                    )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(CyberpunkTheme.Colors.cyberGold.opacity(0.5), lineWidth: 1)
                            )
                            .shadow(color: CyberpunkTheme.Colors.cyberGold.opacity(0.3), radius: 10)
                        }
                        .buttonStyle(PlainButtonStyle())

                        NavigationLink {
                            CreatePrivateDocumentStoreView(
                                freeTokenClient: freeTokenClient,
                                documentLoader: documentLoader
                            )
                        } label: {
                            VStack(spacing: 12) {
                                Image(systemName: "lock.shield.fill")
                                    .font(.system(size: 36))
                                    .foregroundColor(CyberpunkTheme.Colors.cyberGreen)
                                    .neonGlow(color: CyberpunkTheme.Colors.cyberGreen, radius: 3)

                                Text("PRIVATE STORE")
                                    .font(.system(size: 14, weight: .bold))
                                    .textCase(.uppercase)
                                    .kerning(1.2)
                                    .foregroundColor(CyberpunkTheme.Colors.cyberGreen)

                                Text("CREATE A SECURE PRIVATE DOCUMENT STORE")
                                    .font(.system(size: 10, weight: .medium))
                                    .textCase(.uppercase)
                                    .kerning(0.6)
                                    .foregroundColor(CyberpunkTheme.Colors.cyberBlueLight)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, minHeight: 160)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(CyberpunkTheme.Colors.cyberPanel)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(.ultraThinMaterial)
                                    )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(CyberpunkTheme.Colors.cyberGreen.opacity(0.5), lineWidth: 1)
                            )
                            .shadow(color: CyberpunkTheme.Colors.cyberGreen.opacity(0.3), radius: 10)
                        }
                        .buttonStyle(PlainButtonStyle())

                        NavigationLink {
                            DocumentSearchByIDView(
                                freeTokenClient: freeTokenClient,
                                documentLoader: documentLoader
                            )
                        } label: {
                            VStack(spacing: 12) {
                                Image(systemName: "number.square")
                                    .font(.system(size: 36))
                                    .foregroundColor(CyberpunkTheme.Colors.cyberOrange)
                                    .neonGlow(color: CyberpunkTheme.Colors.cyberOrange, radius: 3)

                                Text("GET BY ID")
                                    .font(.system(size: 14, weight: .bold))
                                    .textCase(.uppercase)
                                    .kerning(1.2)
                                    .foregroundColor(CyberpunkTheme.Colors.cyberOrange)

                                Text("FIND A SPECIFIC DOCUMENT USING ITS ID")
                                    .font(.system(size: 10, weight: .medium))
                                    .textCase(.uppercase)
                                    .kerning(0.6)
                                    .foregroundColor(CyberpunkTheme.Colors.cyberBlueLight)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, minHeight: 160)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(CyberpunkTheme.Colors.cyberPanel)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(.ultraThinMaterial)
                                    )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(CyberpunkTheme.Colors.cyberOrange.opacity(0.5), lineWidth: 1)
                            )
                            .shadow(color: CyberpunkTheme.Colors.cyberOrange.opacity(0.3), radius: 10)
                        }
                        .buttonStyle(PlainButtonStyle())

                        NavigationLink {
                            DocumentSearchByQueryView(
                                freeTokenClient: freeTokenClient,
                                documentLoader: documentLoader
                            )
                        } label: {
                            VStack(spacing: 12) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 36))
                                    .foregroundColor(CyberpunkTheme.Colors.cyberCyan)
                                    .neonGlow(color: CyberpunkTheme.Colors.cyberCyan, radius: 3)

                                Text("SEARCH DOCUMENTS")
                                    .font(.system(size: 14, weight: .bold))
                                    .textCase(.uppercase)
                                    .kerning(1.2)
                                    .foregroundColor(CyberpunkTheme.Colors.cyberCyan)

                                Text("QUERY DOCUMENT CHUNKS WITH SEMANTIC SEARCH")
                                    .font(.system(size: 10, weight: .medium))
                                    .textCase(.uppercase)
                                    .kerning(0.6)
                                    .foregroundColor(CyberpunkTheme.Colors.cyberBlueLight)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, minHeight: 160)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(CyberpunkTheme.Colors.cyberPanel)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(.ultraThinMaterial)
                                    )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(CyberpunkTheme.Colors.cyberCyan.opacity(0.5), lineWidth: 1)
                            )
                            .shadow(color: CyberpunkTheme.Colors.cyberCyan.opacity(0.3), radius: 10)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }

                    if !statusMessage.isEmpty {
                        Text(statusMessage)
                            .foregroundColor(.gray)
                            .padding(.top, 8)
                    }
                }
                .padding()
            }
            }
            .navigationTitle("DOCUMENTS")
            .toolbarBackground(CyberpunkTheme.Colors.cyberPanel, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
}
