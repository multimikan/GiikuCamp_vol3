import Foundation

// GPT APIリクエストモデル
struct GPTRequest: Encodable {
    let model: String
    let messages: [Message]
    let temperature: Float?
    
    init(model: String = "gpt-4.1", messages: [Message], temperature: Float? = 0.7) {
        self.model = model
        self.messages = messages
        self.temperature = temperature
    }
}

// メッセージモデル
struct Message: Codable {
    let role: String
    let content: String
}

// GPT APIレスポンスモデル
struct GPTResponse: Decodable {
    let id: String
    let object: String
    let created: Int
    let model: String
    let choices: [Choice]
    let usage: Usage
}

struct Choice: Decodable {
    let index: Int
    let message: Message
    let finishReason: String
    
    enum CodingKeys: String, CodingKey {
        case index
        case message
        case finishReason = "finish_reason"
    }
}

struct Usage: Decodable {
    let promptTokens: Int
    let completionTokens: Int
    let totalTokens: Int
    
    enum CodingKeys: String, CodingKey {
        case promptTokens = "prompt_tokens"
        case completionTokens = "completion_tokens"
        case totalTokens = "total_tokens"
    }
} 
