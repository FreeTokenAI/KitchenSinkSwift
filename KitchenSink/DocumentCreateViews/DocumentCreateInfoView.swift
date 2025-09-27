//
//  DocumentCreateInfoView.swift
//  ExampleApp
//
//  Created by Ashley Luhrs on 7/17/25.
//

import SwiftUI

struct DocumentCreateInfoView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label {
                Text("ANY DOCUMENT STORED IN YOUR APP'S VECTOR STORE SHOULD BE PUBLIC DATA. IT IS NOT SECURE OR PROTECTED FROM OTHER USERS' ACCESS.")
                    .font(.system(size: 11, weight: .medium))
                    .textCase(.uppercase)
                    .kerning(0.6)
            } icon: {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                    .neonGlow(color: .red, radius: 2)
            }
            .foregroundColor(.red)

            Label {
                Text("IT IS NOT RECOMMENDED THAT YOU USE THE DOCUMENT STORE AS A PERSISTENCE STORE IN YOUR APP. ONLY USE IT FOR CONTEXT TO BE PROVIDED TO AN AI.")
                    .font(.system(size: 11, weight: .medium))
                    .textCase(.uppercase)
                    .kerning(0.6)
            } icon: {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(CyberpunkTheme.Colors.cyberOrange)
                    .neonGlow(color: CyberpunkTheme.Colors.cyberOrange, radius: 2)
            }
            .foregroundColor(CyberpunkTheme.Colors.cyberOrange)

            Label {
                Text("FOR LARGE DOCUMENTS, BREAK THEM INTO CHUNKS. LARGE DOCUMENTS MAY HIT AN UPLOAD ERROR.")
                    .font(.system(size: 11, weight: .medium))
                    .textCase(.uppercase)
                    .kerning(0.6)
            } icon: {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(CyberpunkTheme.Colors.cyberCyan)
                    .neonGlow(color: CyberpunkTheme.Colors.cyberCyan, radius: 2)
            }
            .foregroundColor(CyberpunkTheme.Colors.cyberCyan)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(CyberpunkTheme.Colors.cyberPanel)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(CyberpunkTheme.Colors.cyberMagenta.opacity(0.3), lineWidth: 1)
                )
        )
        .shadow(color: CyberpunkTheme.Colors.cyberMagenta.opacity(0.2), radius: 8)
    }
}