import SwiftUI

struct CyberpunkTheme {
    // MARK: - Colors
    struct Colors {
        static let cyberGold = Color(red: 1.0, green: 0.843, blue: 0)
        static let cyberCyan = Color(red: 0, green: 1.0, blue: 1.0)
        static let cyberMagenta = Color(red: 1.0, green: 0, blue: 1.0)
        static let cyberGreen = Color(red: 0, green: 1.0, blue: 0)
        static let cyberGreenBright = Color(red: 0, green: 1.0, blue: 0.255)
        static let cyberOrange = Color(red: 1.0, green: 0.42, blue: 0)
        static let cyberBlueDark = Color(red: 0.039, green: 0.039, blue: 0.18)
        static let cyberBlueDarker = Color(red: 0.086, green: 0.129, blue: 0.243)
        static let cyberBlueDarkest = Color(red: 0.102, green: 0.102, blue: 0.243)
        static let cyberBlueLight = Color(red: 0.627, green: 0.663, blue: 1.0)
        static let cyberPanel = Color.white.opacity(0.05)
        static let cyberPanelLight = Color.white.opacity(0.08)
        static let cyberPanelSolid = Color(red: 0.063, green: 0.063, blue: 0.235)
    }

    // MARK: - Gradients
    struct Gradients {
        static let backgroundGradient = LinearGradient(
            gradient: Gradient(colors: [Colors.cyberBlueDark, Colors.cyberBlueDarker, Colors.cyberBlueDarkest]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static let goldGradient = LinearGradient(
            gradient: Gradient(colors: [Colors.cyberGold, Color(red: 1.0, green: 0.647, blue: 0)]),
            startPoint: .leading,
            endPoint: .trailing
        )

        static let cyanGradient = LinearGradient(
            gradient: Gradient(colors: [Colors.cyberCyan, Colors.cyberCyan.opacity(0.7)]),
            startPoint: .leading,
            endPoint: .trailing
        )

        static let buttonGradient = LinearGradient(
            gradient: Gradient(colors: [Colors.cyberBlueDark, Colors.cyberBlueDarker]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Text Styles
    struct TextStyles {
        static func cyberTitle(_ text: String) -> some View {
            Text(text)
                .font(.largeTitle)
                .fontWeight(.bold)
                .textCase(.uppercase)
                .kerning(3)
                .foregroundStyle(Gradients.goldGradient)
        }

        static func cyberHeadline(_ text: String) -> some View {
            Text(text)
                .font(.headline)
                .fontWeight(.semibold)
                .textCase(.uppercase)
                .kerning(1.5)
                .foregroundColor(Colors.cyberCyan)
        }

        static func cyberSubheadline(_ text: String) -> some View {
            Text(text)
                .font(.subheadline)
                .textCase(.uppercase)
                .kerning(1)
                .foregroundColor(Colors.cyberMagenta)
        }

        static func cyberCaption(_ text: String) -> some View {
            Text(text)
                .font(.caption)
                .textCase(.uppercase)
                .kerning(0.5)
                .foregroundColor(Colors.cyberBlueLight)
        }
    }

    // MARK: - View Modifiers
    struct ViewModifiers {
        struct CyberPanel: ViewModifier {
            func body(content: Content) -> some View {
                content
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Colors.cyberPanel)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.ultraThinMaterial)
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Colors.cyberMagenta.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: Colors.cyberMagenta.opacity(0.2), radius: 10)
            }
        }

        struct CyberButton: ViewModifier {
            var isPrimary: Bool = true

            func body(content: Content) -> some View {
                content
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(isPrimary ? Gradients.goldGradient : Gradients.buttonGradient)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isPrimary ? Colors.cyberGold : Colors.cyberCyan, lineWidth: 1)
                    )
                    .foregroundColor(isPrimary ? .black : .white)
                    .font(.system(size: 14, weight: .bold))
                    .textCase(.uppercase)
                    .kerning(1.5)
                    .shadow(color: isPrimary ? Colors.cyberGold.opacity(0.5) : Colors.cyberCyan.opacity(0.5), radius: 10)
            }
        }

        struct CyberTextField: ViewModifier {
            @Binding var isEditing: Bool

            func body(content: Content) -> some View {
                content
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Colors.cyberPanel)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isEditing ? Colors.cyberCyan : Colors.cyberCyan.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: isEditing ? Colors.cyberCyan.opacity(0.5) : .clear, radius: 5)
                    .foregroundColor(.white)
            }
        }

        struct NeonGlow: ViewModifier {
            var color: Color = Colors.cyberCyan
            var radius: CGFloat = 5

            func body(content: Content) -> some View {
                content
                    .shadow(color: color.opacity(0.8), radius: radius)
                    .shadow(color: color.opacity(0.5), radius: radius * 2)
            }
        }

        struct GlassPanel: ViewModifier {
            func body(content: Content) -> some View {
                content
                    .background(.ultraThinMaterial)
                    .background(Colors.cyberPanel)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Colors.cyberCyan.opacity(0.3),
                                        Colors.cyberMagenta.opacity(0.3)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            }
        }
    }
}

// MARK: - View Extensions
extension View {
    func cyberPanel() -> some View {
        modifier(CyberpunkTheme.ViewModifiers.CyberPanel())
    }

    func cyberButton(isPrimary: Bool = true) -> some View {
        modifier(CyberpunkTheme.ViewModifiers.CyberButton(isPrimary: isPrimary))
    }

    func cyberTextField(isEditing: Binding<Bool>) -> some View {
        modifier(CyberpunkTheme.ViewModifiers.CyberTextField(isEditing: isEditing))
    }

    func neonGlow(color: Color = CyberpunkTheme.Colors.cyberCyan, radius: CGFloat = 10) -> some View {
        modifier(CyberpunkTheme.ViewModifiers.NeonGlow(color: color, radius: radius))
    }

    func glassPanel() -> some View {
        modifier(CyberpunkTheme.ViewModifiers.GlassPanel())
    }
}

// MARK: - Animation Effects
struct PulseEffect: ViewModifier {
    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1.05 : 1.0)
            .opacity(isPulsing ? 0.8 : 1.0)
            .animation(
                Animation.easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: true),
                value: isPulsing
            )
            .onAppear {
                isPulsing = true
            }
    }
}

extension View {
    func pulseEffect() -> some View {
        modifier(PulseEffect())
    }
}
