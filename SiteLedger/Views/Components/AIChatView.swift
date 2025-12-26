import SwiftUI

struct AIChatView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: AuthService
    @StateObject private var viewModel = AIChatViewModel()
    @State private var messageText = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.backgroundColor.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                                if viewModel.messages.isEmpty {
                                    VStack(spacing: DesignSystem.Spacing.large) {
                                        Image(systemName: "sparkles")
                                            .font(.system(size: 60))
                                            .foregroundColor(AppTheme.primaryColor)
                                        
                                        Text("AI Business Assistant")
                                            .font(DesignSystem.TextStyle.title2)
                                            .foregroundColor(DesignSystem.Colors.textPrimary)
                                        
                                        Text("Ask me anything about your business")
                                            .font(DesignSystem.TextStyle.bodySecondary)
                                            .foregroundColor(DesignSystem.Colors.textSecondary)
                                            .multilineTextAlignment(.center)
                                        
                                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                                            SuggestedQuestion(
                                                question: "How much did I spend this week?",
                                                action: {
                                                    messageText = "How much did I spend this week?"
                                                    sendMessage()
                                                }
                                            )
                                            
                                            SuggestedQuestion(
                                                question: "Which job is most profitable?",
                                                action: {
                                                    messageText = "Which job is most profitable?"
                                                    sendMessage()
                                                }
                                            )
                                            
                                            SuggestedQuestion(
                                                question: "Show me all receipts over $500",
                                                action: {
                                                    messageText = "Show me all receipts over $500"
                                                    sendMessage()
                                                }
                                            )
                                            
                                            SuggestedQuestion(
                                                question: "Summarize my month",
                                                action: {
                                                    messageText = "Summarize my month"
                                                    sendMessage()
                                                }
                                            )
                                        }
                                        .padding(.top, 20)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                } else {
                                    ForEach(viewModel.messages) { message in
                                        ChatMessageView(message: message)
                                            .id(message.id)
                                    }
                                    
                                    if isLoading {
                                        HStack(spacing: DesignSystem.Spacing.small) {
                                            Circle()
                                                .fill(AppTheme.textSecondary)
                                                .frame(width: 8)
                                                .opacity(0.4)
                                            Circle()
                                                .fill(AppTheme.textSecondary)
                                                .frame(width: 8)
                                                .opacity(0.6)
                                            Circle()
                                                .fill(AppTheme.textSecondary)
                                                .frame(width: 8)
                                                .opacity(1)
                                        }
                                        .padding()
                                        .id("loading")
                                    }
                                }
                            }
                            .padding()
                            .onChange(of: viewModel.messages.count) {
                                withAnimation {
                                    if let lastID = viewModel.messages.last?.id {
                                        proxy.scrollTo(lastID, anchor: .bottom)
                                    } else {
                                        proxy.scrollTo("loading", anchor: .bottom)
                                    }
                                }
                            }
                        }
                    }
                    
                    Divider()
                    
                    HStack(spacing: DesignSystem.Spacing.medium) {
                        TextField("Ask me something...", text: $messageText)
                            .textFieldStyle(.roundedBorder)
                            .disabled(isLoading)
                        
                        Button(action: sendMessage) {
                            Image(systemName: "paperplane.fill")
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(AppTheme.primaryColor)
                                .cornerRadius(8)
                        }
                        .disabled(messageText.isEmpty || isLoading)
                    }
                    .padding()
                }
            }
            .navigationTitle("AI Assistant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                if let userID = authService.currentUser?.id {
                    Task {
                        await viewModel.loadUserData(userID: userID)
                    }
                }
            }
        }
    }
    
    private func sendMessage() {
        guard !messageText.isEmpty else { return }
        
        let userMessage = ChatMessage(
            id: UUID().uuidString,
            content: messageText,
            isUser: true,
            timestamp: Date()
        )
        
        viewModel.messages.append(userMessage)
        let question = messageText
        messageText = ""
        isLoading = true
        
        Task {
            do {
                let response = try await viewModel.askAI(question: question)
                let aiMessage = ChatMessage(
                    id: UUID().uuidString,
                    content: response,
                    isUser: false,
                    timestamp: Date()
                )
                await MainActor.run {
                    viewModel.messages.append(aiMessage)
                    isLoading = false
                }
            } catch {
                let errorMessage = ChatMessage(
                    id: UUID().uuidString,
                    content: "Sorry, I couldn't process your request. Please try again.",
                    isUser: false,
                    timestamp: Date()
                )
                await MainActor.run {
                    viewModel.messages.append(errorMessage)
                    isLoading = false
                }
            }
        }
    }
}

struct ChatMessageView: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
                VStack(alignment: .trailing) {
                    Text(message.content)
                        .foregroundColor(.white)
                    Text(message.timestamp.formatted(date: .omitted, time: .shortened))
                        .font(DesignSystem.TextStyle.tiny)
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(DesignSystem.Spacing.medium)
                .background(AppTheme.primaryColor)
                .cornerRadius(12)
            } else {
                VStack(alignment: .leading) {
                    Text(message.content)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    Text(message.timestamp.formatted(date: .omitted, time: .shortened))
                        .font(DesignSystem.TextStyle.tiny)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                .padding(DesignSystem.Spacing.medium)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                Spacer()
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }
}

struct SuggestedQuestion: View {
    let question: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(AppTheme.primaryColor)
                    .font(DesignSystem.TextStyle.bodySecondary)
                
                Text(question)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .font(DesignSystem.TextStyle.bodySecondary)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .font(DesignSystem.TextStyle.caption)
            }
            .padding(DesignSystem.Spacing.medium)
            .background(Color.gray.opacity(0.05))
            .cornerRadius(10)
        }
    }
}

#Preview {
    AIChatView()
        .environmentObject(AuthService())
}
