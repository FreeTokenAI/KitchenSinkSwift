# FreeToken Swift SDK Example App

A comprehensive demonstration application showcasing all capabilities of the FreeToken Swift SDK. This "kitchen sink" app provides working examples of every major feature, from basic AI chat to advanced RAG (Retrieval-Augmented Generation) implementations.

## 🚀 Quick Start

1. **Get Your App Token**
   - Sign up at [FreeToken Console](https://console.freetoken.ai)
   - Create a new app
   - Generate an app token

2. **Configure the App**
   - Open the project in Xcode
   - Navigate to `FreeTokenClient.swift`
   - Replace the default token with your app token

3. **Run the App**
   - Build and run on iOS 17.0+ device or simulator
   - Complete device registration on first launch

## 📚 Documentation

- **Full Documentation**: [docs.freetoken.ai](https://docs.freetoken.ai)
- **Getting Started Guide**: [docs.freetoken.ai/docs/getting-started](https://docs.freetoken.ai/docs/getting-started)
- **Learn More**: [freetoken.ai](https://freetoken.ai)
- **Console**: [console.freetoken.ai](https://console.freetoken.ai)

## 🎯 Features by Tab

### 🏠 Home Tab
The main landing screen providing:
- **Device Registration**: Initial setup flow for new users
- **Model Download Progress**: Visual feedback during AI model downloads
- **Quick Actions**: Fast access to primary features
- **Status Overview**: Current SDK configuration and connection status

**Key Capabilities Demonstrated**:
- SDK initialization and configuration
- Device session registration
- Model download with progress tracking
- Automatic device/cloud fallback setup

### 💬 Chat Tab
Full-featured AI chat interface demonstrating:
- **Message Threading**: Persistent conversation history with context
- **Streaming Responses**: Real-time token generation display
- **Model Selection**: Switch between different AI models on-the-fly
- **Tool Functions**: Weather tool example for function calling
- **RAG Integration**: Document search scope for contextual responses
- **Custom Parameters**: Fine-tune generation with temperature, topK, topP
- **Token Usage Stats**: Track input/output token consumption

**Key Capabilities Demonstrated**:
- Creating and managing message threads
- Streaming AI responses with status updates
- Tool calling and function execution
- Document-enhanced responses (RAG)
- AI run configuration customization
- Multi-model support with hot-swapping

### 🤖 AI Models Tab
Model management interface showcasing:
- **Model Discovery**: List all available AI models
- **Download Management**: Download models for on-device inference
- **Storage Control**: Delete models to free up space
- **Cloud vs Local**: Visual indicators for model capabilities
- **Device Compatibility**: Shows which models work on current device
- **Download Progress**: Real-time download status with percentage

**Key Capabilities Demonstrated**:
- Listing available AI models
- Model download for offline/faster inference
- Automatic cloud fallback when local fails
- Memory management and model deletion
- Cloud-only model identification

### ✨ Completions Tab
Simple text generation interface featuring:
- **Prompt-Based Generation**: Generate text from prompts
- **Streaming Output**: Watch tokens generate in real-time
- **Model Selection**: Choose specific models for completion
- **AIRunConfig**: Advanced generation parameters
- **Token Counting**: Track generation statistics
- **Performance Metrics**: Tokens per second measurement

**Key Capabilities Demonstrated**:
- Text completion API usage
- Streaming token generation
- Custom AI configuration parameters
- Performance monitoring
- Model-specific completions

### 📚 Documents Tab
RAG (Retrieval-Augmented Generation) system demonstrating:

#### Create Documents
- **Document Upload**: Add content to knowledge base
- **Metadata Addition**: Enrich documents with context
- **Search Scopes**: Organize documents by topic
- **Private Stores**: Create isolated document collections
- **Encryption Support**: Secure document storage

#### Search by Query
- **Semantic Search**: Find relevant document chunks
- **Scope Filtering**: Search within specific topics
- **Private Store Search**: Query isolated collections
- **Result Display**: View matching document chunks

#### Search by ID
- **Direct Retrieval**: Fetch specific documents
- **Document Details**: View full content and metadata
- **Management**: Edit or delete existing documents

**Key Capabilities Demonstrated**:
- Creating documents for RAG
- Private document store management
- Semantic document search
- Document retrieval and management
- Search scope organization
- Encrypted document handling

### 🔧 Utilities Tab
System utilities and advanced features:
- **Encryption Setup**: Generate encryption keys for data security
- **Token Counter**: Estimate token usage for text
- **Device Reset**: Clear all data and start fresh
- **Cache Management**: Clear downloaded models
- **Telemetry**: Usage statistics and analytics
- **Debug Tools**: Logging and diagnostic features

**Key Capabilities Demonstrated**:
- End-to-end encryption setup
- Token counting for cost estimation
- Device lifecycle management
- Memory and storage optimization
- Telemetry and statistics tracking

## 🎨 Architecture

The app follows MVVM (Model-View-ViewModel) architecture:
- **Views**: SwiftUI interfaces with cyberpunk theming
- **ViewModels**: Business logic and SDK interactions
- **FreeTokenClient**: Centralized SDK wrapper
- **Models**: FreeToken SDK data structures

## 🔑 Key Technologies

- **FreeToken Swift SDK**: Core AI functionality
- **SwiftUI**: Modern declarative UI
- **Combine**: Reactive programming for data flow
- **Swift Concurrency**: Async/await for API calls
- **CryptoKit**: Encryption key generation

## 📱 Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+
- FreeToken SDK 1.0+

## 🏗️ Project Structure

```
KitchenSink/
├── FreeTokenClient.swift       # SDK wrapper and initialization
├── ChatView.swift              # Chat interface and message threading
├── ChatViewModel.swift         # Chat logic and streaming
├── AIModelsView.swift          # Model management UI
├── AIModelsViewModel.swift     # Model download and lifecycle
├── CompletionsView.swift       # Text generation interface
├── DocumentView.swift          # Document management tabs
├── DocumentViewModel.swift     # RAG document operations
├── UtilitiesView.swift        # System utilities
├── TokenCounterView.swift      # Token estimation tool
└── ViewBuilders/              # Reusable UI components
```

## 🚦 Getting Started with Development

1. **Clone the repository**
   ```bash
   git clone [repository-url]
   cd KitchenSink
   ```

2. **Open in Xcode**
   ```bash
   open KitchenSink.xcodeproj
   ```

3. **Configure your app token**
   - Edit `FreeTokenClient.swift`
   - Replace `DEFAULT_APP_TOKEN` with your token from [console.freetoken.ai](https://console.freetoken.ai)

4. **Build and run**
   - Select your target device/simulator
   - Press ⌘R to build and run

## 🎯 Use Cases Demonstrated

- **Customer Support Bot**: Use chat with RAG for context-aware support
- **Content Generation**: Use completions for creative writing
- **Document Q&A**: Upload documents and query them with AI
- **Offline AI**: Download models for airplane mode usage
- **Secure AI**: Enable encryption for sensitive data
- **A/B Testing**: Switch between models to compare performance
- **Tool Integration**: Extend AI with custom functions

## 🔗 Resources

- **Documentation**: [docs.freetoken.ai](https://docs.freetoken.ai)
- **Console**: [console.freetoken.ai](https://console.freetoken.ai)
- **Website**: [freetoken.ai](https://freetoken.ai)
- **Support**: support@freetoken.ai

## 📄 License

This example application is provided as-is for demonstration purposes. See LICENSE file for details.

## 🤝 Contributing

This is a demonstration app to showcase SDK capabilities. For SDK issues or feature requests, please contact FreeToken support.

---

Built with ❤️ using FreeToken Swift SDK