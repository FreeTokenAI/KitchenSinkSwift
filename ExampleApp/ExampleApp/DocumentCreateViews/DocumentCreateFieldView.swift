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
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if isMultiline {
                ZStack(alignment: .topLeading) {
                    Text(placeholder)
                        .foregroundStyle(Color.gray.opacity(0.5))
                        .padding(.top, 8)
                        .padding(.horizontal, 5)
                        .opacity(text.isEmpty ? 1 : 0)
                    TextEditor(text: $text)
                        .frame(height: height)
                        .padding(4)
                        .scrollContentBackground(.hidden)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.accentColor.opacity(0.3), lineWidth: 1.5)
                        )
                }
            } else {
                TextField(placeholder, text: $text)
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color(.systemGray6)))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.accentColor.opacity(0.3), lineWidth: 1.5))
                    .font(.body)
            }
        }
    }
}
