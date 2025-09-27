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
                        status == .success ? CyberpunkTheme.Colors.cyberGreen.opacity(0.2) :
                        status == .error ? Color.red.opacity(0.2) :
                        CyberpunkTheme.Colors.cyberCyan.opacity(0.2)
                    )
                    .frame(width: 40, height: 40)
                    .overlay(
                        Circle()
                            .stroke(
                                status == .success ? CyberpunkTheme.Colors.cyberGreen.opacity(0.5) :
                                status == .error ? Color.red.opacity(0.5) :
                                CyberpunkTheme.Colors.cyberCyan.opacity(0.5),
                                lineWidth: 1
                            )
                    )
                if status == .loading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: CyberpunkTheme.Colors.cyberCyan))
                        .frame(width: 24, height: 24)
                        .accessibilityLabel("Loading")
                } else {
                    Image(systemName: status == .success ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                        .foregroundColor(status == .success ? CyberpunkTheme.Colors.cyberGreen : .red)
                        .font(.title2)
                        .neonGlow(
                            color: status == .success ? CyberpunkTheme.Colors.cyberGreen : .red,
                            radius: 2
                        )
                        .accessibilityLabel(status == .success ? "Success" : "Error")
                }
            }
            Text(message.uppercased())
                .font(.system(size: 12, weight: .medium))
                .textCase(.uppercase)
                .kerning(0.8)
                .foregroundColor(
                    status == .success ? CyberpunkTheme.Colors.cyberGreen :
                    status == .error ? .red :
                    CyberpunkTheme.Colors.cyberCyan
                )
                .lineLimit(3)
                .minimumScaleFactor(0.9)
            Spacer()
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(CyberpunkTheme.Colors.cyberPanel)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            status == .success ? CyberpunkTheme.Colors.cyberGreen.opacity(0.3) :
                            status == .error ? Color.red.opacity(0.3) :
                            CyberpunkTheme.Colors.cyberCyan.opacity(0.3),
                            lineWidth: 1
                        )
                )
        )
        .shadow(
            color: status == .success ? CyberpunkTheme.Colors.cyberGreen.opacity(0.2) :
                   status == .error ? Color.red.opacity(0.2) :
                   CyberpunkTheme.Colors.cyberCyan.opacity(0.2),
            radius: 8
        )
        .transition(.move(edge: .top).combined(with: .opacity))
        .animation(.spring(), value: message)
        .accessibilityElement(children: .combine)
    }
}