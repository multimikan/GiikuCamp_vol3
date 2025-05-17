import Foundation
import SwiftUI

class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""
    @Published var isLoading: Bool = false
    
    private let apiClient: GPTAPIClient
    
    init(apiClient: GPTAPIClient = GPTAPIClient(apiKey: Environment.openAIAPIKey)) {
        self.apiClient = apiClient
        
        // 初期化時にシステムプロンプトを追加
        addDefaultSystemPrompt()
    }
    
    private func addDefaultSystemPrompt() {
        // システムプロンプトをここに設定
        let systemPrompt = "あなたは役立つAIアシスタントです。簡潔かつ丁寧に応答してください。"
        
        let systemMessage = ChatMessage(
            id: UUID().uuidString,
            role: "system",
            content: systemPrompt,
            createdAt: Date()
        )
        
        // システムメッセージをメッセージリストに追加（UIには表示されない）
        messages.append(systemMessage)
    }
    
    func sendMessage() async {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let userMessage = ChatMessage(id: UUID().uuidString, role: "user", content: inputText, createdAt: Date())
        
        await MainActor.run {
            messages.append(userMessage)
            isLoading = true
            inputText = ""
        }
        
        do {
            let apiMessages = messages.map { Message(role: $0.role, content: $0.content) }
            let response = try await apiClient.sendMessage(apiMessages)
            
            let assistantMessage = ChatMessage(id: UUID().uuidString, role: "assistant", content: response, createdAt: Date())
            
            await MainActor.run {
                messages.append(assistantMessage)
                isLoading = false
            }
        } catch {
            print("Error: \(error.localizedDescription)")
            
            await MainActor.run {
                let errorMessage = ChatMessage(id: UUID().uuidString, role: "assistant", content: "エラーが発生しました: \(error.localizedDescription)", createdAt: Date())
                messages.append(errorMessage)
                isLoading = false
            }
        }
    }
}

struct ChatMessage: Identifiable {
    let id: String
    let role: String
    let content: String
    let createdAt: Date
} 