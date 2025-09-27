//
//  DocumentCreateResultView.swift
//  ExampleApp
//
//  Created by Ashley Luhrs on 7/17/25.
//

import SwiftUI
import FreeToken

struct DocumentCreateResultView: View {
    let document: FreeToken.Document

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundColor(.green)
                    .font(.title2)
                Text("Document Created!")
                    .font(.headline)
            }
            Divider()
            HStack {
                DocumentFieldView(systemImage: "number", label: "ID", value: document.id)
                Spacer()
                Button(action: {
                    UIPasteboard.general.string = document.id
                }) {
                    Image(systemName: "doc.on.doc")
                        .foregroundColor(.accentColor)
                }
                .buttonStyle(BorderlessButtonStyle())
            }
            if let metadata = document.metadata, !metadata.isEmpty {
                DocumentFieldView(systemImage: "info.circle", label: "Metadata", value: metadata)
            }
            DocumentFieldView(systemImage: "text.alignleft", label: "Content", value: document.content)
            DocumentFieldView(systemImage: "scope", label: "Search Scope", value: document.searchScope)
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.green.opacity(0.10), Color(.systemBackground)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.10), radius: 6, x: 0, y: 2)
        .transition(.move(edge: .top).combined(with: .opacity))
        .animation(.spring(), value: document.id)
    }
}

struct DocumentFieldView: View {
    let systemImage: String
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top) {
            Image(systemName: systemImage)
                .foregroundColor(.secondary)
            Text("\(label):")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text(value)
                .font(.subheadline)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
