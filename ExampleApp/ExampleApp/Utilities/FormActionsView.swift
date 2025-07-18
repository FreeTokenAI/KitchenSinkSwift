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
                Text(primaryLabel)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.accentColor, Color.accentColor.opacity(0.7)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .shadow(color: Color.accentColor.opacity(0.15), radius: 4, x: 0, y: 2)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(!canPrimary)
            .opacity(canPrimary ? 1 : 0.6)
            if showClear {
                Button(clearLabel, action: onClear)
                    .fontWeight(.regular)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color(.systemGray5), Color(.systemGray6)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.primary)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                    .buttonStyle(PlainButtonStyle())
                    .accessibilityLabel("Clear all fields")
                    .accessibilityHint("Resets all input fields and result state")
                    .transition(.opacity)
            }
            if showValidationError, let errorMessage = validationErrorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.footnote)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut, value: showClear)
    }
}
