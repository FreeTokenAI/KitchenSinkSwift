//
//  DocumentCreateFieldView.swift
//  ExampleApp
//
//  Created by Ashley Luhrs on 7/17/25.
//

import SwiftUI

struct DocumentCreateFieldView: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let height: CGFloat
    let isMultiline: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.system(size: 12, weight: .semibold))
                .textCase(.uppercase)
                .kerning(0.8)
                .foregroundColor(CyberpunkTheme.Colors.cyberGold)

            if isMultiline {
                ZStack(alignment: .topLeading) {
                    Text(placeholder.uppercased())
                        .font(.system(size: 12, weight: .medium))
                        .textCase(.uppercase)
                        .kerning(0.6)
                        .foregroundStyle(CyberpunkTheme.Colors.cyberBlueLight.opacity(0.4))
                        .padding(.top, 8)
                        .padding(.horizontal, 5)
                        .opacity(text.isEmpty ? 1 : 0)

                    TextEditor(text: $text)
                        .font(.system(size: 13, weight: .regular, design: .monospaced))
                        .foregroundColor(CyberpunkTheme.Colors.cyberCyan)
                        .frame(height: height)
                        .padding(4)
                        .scrollContentBackground(.hidden)
                        .background(CyberpunkTheme.Colors.cyberPanel)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(CyberpunkTheme.Colors.cyberCyan.opacity(0.3), lineWidth: 1)
                        )
                }
            } else {
                TextField(placeholder.uppercased(), text: $text)
                    .font(.system(size: 13, weight: .regular, design: .monospaced))
                    .foregroundColor(CyberpunkTheme.Colors.cyberCyan)
                    .textCase(.none)
                    .padding(10)
                    .background(CyberpunkTheme.Colors.cyberPanel)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(CyberpunkTheme.Colors.cyberCyan.opacity(0.3), lineWidth: 1)
                    )
            }
        }
    }
}