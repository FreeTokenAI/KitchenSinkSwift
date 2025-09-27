//
//  FormActionsView.swift
//  ExampleApp
//
//  Created by Ashley Luhrs on 7/17/25.
//

import SwiftUI

struct FormActionsView: View {
    let primaryLabel: String
    let canPrimary: Bool
    let showValidationError: Bool
    let validationErrorMessage: String?
    let showClear: Bool
    let clearLabel: String
    let onPrimary: () -> Void
    let onClear: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Button(action: onPrimary) {
                Text(primaryLabel.uppercased())
                    .font(.system(size: 14, weight: .bold))
                    .textCase(.uppercase)
                    .kerning(1.2)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        canPrimary ?
                        LinearGradient(
                            gradient: Gradient(colors: [CyberpunkTheme.Colors.cyberCyan, CyberpunkTheme.Colors.cyberCyan.opacity(0.7)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ) :
                        LinearGradient(
                            gradient: Gradient(colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.2)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(canPrimary ? CyberpunkTheme.Colors.cyberBlueDark : CyberpunkTheme.Colors.cyberBlueLight)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(canPrimary ? CyberpunkTheme.Colors.cyberCyan : Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .cornerRadius(12)
                    .shadow(color: canPrimary ? CyberpunkTheme.Colors.cyberCyan.opacity(0.3) : Color.clear, radius: 10)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(!canPrimary)

            if showClear {
                Button(action: onClear) {
                    Text(clearLabel.uppercased())
                        .font(.system(size: 14, weight: .semibold))
                        .textCase(.uppercase)
                        .kerning(1.2)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(CyberpunkTheme.Colors.cyberPanel)
                        .foregroundColor(CyberpunkTheme.Colors.cyberOrange)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(CyberpunkTheme.Colors.cyberOrange.opacity(0.5), lineWidth: 1)
                        )
                        .cornerRadius(12)
                        .shadow(color: CyberpunkTheme.Colors.cyberOrange.opacity(0.2), radius: 6)
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityLabel("Clear all fields")
                .accessibilityHint("Resets all input fields and result state")
                .transition(.opacity)
            }

            if showValidationError, let errorMessage = validationErrorMessage {
                Text(errorMessage.uppercased())
                    .font(.system(size: 11, weight: .medium))
                    .textCase(.uppercase)
                    .kerning(0.8)
                    .foregroundColor(.red)
                    .neonGlow(color: .red, radius: 2)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut, value: showClear)
    }
}