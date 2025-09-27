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
            Text("ENTER A DOCUMENT ID TO RETRIEVE ITS CONTENT FROM YOUR APP'S VECTOR STORE.")
                .font(.system(size: 12, weight: .medium))
                .textCase(.uppercase)
                .kerning(0.8)
                .foregroundColor(CyberpunkTheme.Colors.cyberBlueLight)
                .accessibilityLabel("Instructions: Enter a document ID to retrieve its content from your app's vector store.")
        }
        .padding()
        .cyberPanel()
        .shadow(color: CyberpunkTheme.Colors.cyberMagenta.opacity(0.2), radius: 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Document Search Header")
    }
}