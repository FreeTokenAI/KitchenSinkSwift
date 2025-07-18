//
//  DocumentSearchByQueryResultView.swift
//  ExampleApp
//
//  Created by Ashley Luhrs on 7/17/25.
//

import SwiftUI
import FreeToken

struct DocumentSearchByQueryResultView: View {
    let chunk: FreeToken.DocumentChunk

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "doc.text.magnifyingglass")
                    .foregroundColor(.accentColor)
                    .font(.title2)
                Text("Chunk Found")
                    .font(.headline)
            }
            Divider()
            HStack {
                Image(systemName: "number")
                    .foregroundColor(.secondary)
                Text("ID:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(chunk.documentID)
                    .font(.subheadline)
                    .bold()
                Spacer()
                Button(action: {
                    UIPasteboard.general.string = chunk.documentID
                }) {
                    Image(systemName: "doc.on.doc")
                        .foregroundColor(.accentColor)
                }
                .buttonStyle(BorderlessButtonStyle())
            }
            if let metadata = chunk.documentMetadata, !metadata.isEmpty {
                HStack(alignment: .top) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.secondary)
                    Text("Metadata:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(metadata)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            HStack(alignment: .top) {
                Image(systemName: "text.alignleft")
                    .foregroundColor(.secondary)
                Text("Content:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(chunk.contentChunk)
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
        .animation(.spring(), value: chunk.documentID)
    }
}
