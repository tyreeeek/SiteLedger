import Foundation
import Combine

struct ChatMessage: Identifiable {
    let id: String
    let content: String
    let isUser: Bool
    let timestamp: Date
    
    init(id: String = UUID().uuidString, content: String, isUser: Bool, timestamp: Date = Date()) {
        self.id = id
        self.content = content
        self.isUser = isUser
        self.timestamp = timestamp
    }
}

@MainActor
class AIChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiService = APIService.shared
    
    func sendMessage(_ text: String) async {
        let userMessage = ChatMessage(content: text, isUser: true, timestamp: Date())
        messages.append(userMessage)
        
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await apiService.sendChatMessage(text)
            let aiMessage = ChatMessage(content: response, isUser: false, timestamp: Date())
            messages.append(aiMessage)
        } catch {
            errorMessage = error.localizedDescription
            let errorMsg = ChatMessage(content: "Sorry, I couldn't process that request.", isUser: false, timestamp: Date())
            messages.append(errorMsg)
        }
        
        isLoading = false
    }
    
    func askAI(question: String) async throws -> String {
        isLoading = true
        defer { isLoading = false }
        
        let response = try await apiService.sendChatMessage(question)
        return response
    }
    
    func loadUserData(userID: String) async {
        // Load context data if needed - optional enhancement
    }
    
    func clearHistory() {
        messages = []
    }
}
