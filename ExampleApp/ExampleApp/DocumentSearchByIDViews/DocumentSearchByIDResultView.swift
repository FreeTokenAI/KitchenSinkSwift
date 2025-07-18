//
//  DocumentSearchByIDResultView.swift
//  ExampleApp
//
//  Created by Ashley Luhrs on 7/17/25.
//

import SwiftUI
import FreeToken

struct DocumentSearchByIDResultView: View {
    let document: FreeToken.Document
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "doc.text.magnifyingglass")
                    .foregroundColor(.accentColor)
                    .font(.title2)
                Text("Document Found!")
                    .font(.headline)
            }
            Divider()
            HStack {
                Image(systemName: "number")
                    .foregroundColor(.secondary)
                Text("ID:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(document.id)
                    .font(.subheadline)
                    .bold()
                Spacer()
                Button(action: {
                    UIPasteboard.general.string = document.id
                }) {
                    Image(systemName: "doc.on.doc")
                        .foregroundColor(.accentColor)
                }
                .buttonStyle(BorderlessButtonStyle())
            }
            HStack(alignment: .top) {
                Image(systemName: "text.alignleft")
                    .foregroundColor(.secondary)
                Text("Content:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(document.content)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color(.systemGray6), Color(.systemBackground)]),
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
