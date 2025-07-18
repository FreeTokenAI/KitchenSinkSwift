//
//  DocumentSearchByIDHeaderView.swift
//  ExampleApp
//
//  Created by Ashley Luhrs on 7/17/25.
//
import SwiftUI

struct DocumentSearchByIDHeaderView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Enter a document ID to retrieve its content from your app’s vector store.")
                .font(.callout)
                .foregroundColor(.secondary)
                .accessibilityLabel("Instructions: Enter a document ID to retrieve its content from your app’s vector store.")
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Document Search Header")
    }
}
