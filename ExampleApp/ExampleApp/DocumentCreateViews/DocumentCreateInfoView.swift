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
                Text("Any document stored in your app’s vector store should be public data. It is not secure or protected from other users’ access.")
            } icon: {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
            }
            .font(.callout)
            .foregroundColor(.red)

            Label {
                Text("It is not recommended that you use the document store as a persistence store in your app. Only use it for context to be provided to an AI.")
            } icon: {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.orange)
            }
            .font(.callout)
            .foregroundColor(.orange)

            Label {
                Text("For large documents, break them into chunks. Large documents may hit an upload error.")
            } icon: {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.blue)
            }
            .font(.callout)
            .foregroundColor(.blue)
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color(.systemGray6), Color(.systemGray5)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.07), radius: 6, x: 0, y: 2)
    }
}
