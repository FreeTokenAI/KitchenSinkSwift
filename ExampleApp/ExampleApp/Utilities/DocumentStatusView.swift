//
//  DocumentStatusView.swift
//  ExampleApp
//
//  Created by Ashley Luhrs on 7/17/25.
//

import SwiftUI

enum DocumentStatus {
    case loading
    case success
    case error
}

struct DocumentStatusView: View {
    let message: String
    let status: DocumentStatus

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                status == .success ? Color.green.opacity(0.18) :
                                status == .error ? Color.red.opacity(0.18) :
                                Color.blue.opacity(0.18),
                                Color(.systemBackground)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)
                if status == .loading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                        .frame(width: 24, height: 24)
                        .accessibilityLabel("Loading")
                } else {
                    Image(systemName: status == .success ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                        .foregroundColor(status == .success ? .green : .red)
                        .font(.title2)
                        .accessibilityLabel(status == .success ? "Success" : "Error")
                }
            }
            Text(message)
                .foregroundColor(.primary)
                .font(.body)
                .lineLimit(3)
                .minimumScaleFactor(0.9)
            Spacer()
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 20)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    status == .success ? Color.green.opacity(0.12) :
                    status == .error ? Color.red.opacity(0.12) :
                    Color.blue.opacity(0.12),
                    Color(.systemGray6)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.09), radius: 8, x: 0, y: 2)
        .transition(.move(edge: .top).combined(with: .opacity))
        .animation(.spring(), value: message)
        .accessibilityElement(children: .combine)
    }
}
