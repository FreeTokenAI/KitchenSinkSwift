import SwiftUI
import FreeToken

struct ToolCallResponseView: View {
    let toolCall: FreeToken.ToolCall
    @Binding var isPresented: Bool
    let onSubmit: (String) -> Void
    @State private var responseText: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Tool Call Details
                VStack(alignment: .leading, spacing: 12) {
                    Label("Tool Call Request", systemImage: "wrench.and.screwdriver.fill")
                        .font(.headline)
                        .foregroundColor(.primary)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Tool:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text(toolCall.name)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.accentColor)
                        }

                        if !toolCall.arguments.isEmpty {
                            Text("Arguments:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            ForEach(Array(toolCall.arguments.keys.sorted()), id: \.self) { key in
                                HStack {
                                    Text("\(key):")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(toolCall.arguments[key] ?? "")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                                .padding(.leading)
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }

                // Response Input
                VStack(alignment: .leading, spacing: 8) {
                    Label("Simulated API Response", systemImage: "text.bubble.fill")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text("Enter the response that the tool would return:")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    TextEditor(text: $responseText)
                        .font(.system(.body, design: .monospaced))
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.separator), lineWidth: 1)
                        )
                        .frame(minHeight: 150)
                        .focused($isFocused)

                    // Example hint for weather tool
                    if toolCall.name == "fetch_weather" {
                        Text("Example: \"72°F and sunny\" or {\"temperature\": 72, \"condition\": \"sunny\"}")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .italic()
                    }
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Tool Call Handler")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        // Submit empty string to prevent AI from getting stuck
                        onSubmit("")
                        isPresented = false
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Submit") {
                        submitResponse()
                    }
                    .disabled(responseText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                // Set default response based on tool
                if toolCall.name == "fetch_weather" {
                    if let location = toolCall.arguments["location"] {
                        responseText = "The weather in \(location) is 72°F and sunny."
                    }
                }

                // Focus the text editor
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isFocused = true
                }
            }
        }
    }

    private func submitResponse() {
        let trimmedResponse = responseText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedResponse.isEmpty {
            onSubmit(trimmedResponse)
            isPresented = false
        }
    }
}
