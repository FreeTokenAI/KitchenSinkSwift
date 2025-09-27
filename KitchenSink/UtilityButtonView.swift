import SwiftUI

struct UtilityButtonView: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 36))
                    .foregroundColor(iconColor)
                    .neonGlow(color: iconColor, radius: 3)

                Text(title.uppercased())
                    .font(.system(size: 14, weight: .bold))
                    .textCase(.uppercase)
                    .kerning(1.2)
                    .foregroundColor(iconColor)

                Text(description.uppercased())
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
                    .stroke(iconColor.opacity(0.5), lineWidth: 1)
            )
            .shadow(color: iconColor.opacity(0.3), radius: 10)
        }
        .buttonStyle(PlainButtonStyle())
    }
}