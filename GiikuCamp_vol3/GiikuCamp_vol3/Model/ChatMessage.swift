import Foundation

struct ChatMessage: Identifiable {
    let id = UUID()
    var role: String // "user", "assistant", "system"
    var content: String
    var createdAt: Date = Date()
} 