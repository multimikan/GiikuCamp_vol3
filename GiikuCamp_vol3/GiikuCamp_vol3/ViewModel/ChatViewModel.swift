import Foundation
import SwiftUI

class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""
    @Published var isLoading: Bool = false
    
    private let apiClient: GPTAPIClient
    var currentUser: User
    
    init(apiClient: GPTAPIClient = GPTAPIClient(apiKey: MyEnvironment.openAIAPIKey),
         user: User = User(name: "ゲスト")) {
        self.apiClient = apiClient
        self.currentUser = user
        
        // 初期化時にシステムプロンプトを追加
        addDefaultSystemPrompt()
    }
    
    private func addDefaultSystemPrompt() {
        // システムプロンプトをここに設定
        var systemPrompt = "提示したオブジェクトについて、そのオブジェクトが開発された際に用いられたパーツごとに適当な教科の学習単元を\(currentUser.age)歳までの学校指導要領内でユーザーに説明してください。回答時は、ユーザーが13歳未満の際は漢字を使わずにフランクな口調で回答をお願いします。回答時は以下のJSONフォーマットに必ず従うこと(バックスラッシュは無視)。また、\(currentUser.language)語で回答すること。\n\n"
        systemPrompt += "[{\"subject\":\"教科の名前\",\"object\":\"オブジェクトまたはパーツの名前\",\"curriculum\":\"単元の名前\",\"description\":\"簡単な説明\",\"deep_description\":\"詳細な説明\"}]"
        
        let systemMessage = ChatMessage(
            id: UUID().uuidString,
            role: "system",
            content: systemPrompt,
            createdAt: Date()
        )
        
        // システムメッセージをメッセージリストに追加（UIには表示されない）
        messages.append(systemMessage)
    }
    
    // JSONをSwiftの二次元配列（[[String: String]]）に変換する関数
    func parseJSONToContentArray(_ jsonString: String) -> [[String: String]] {
        do {
            // 入力されたJSONがそのままパースできない場合は、有効なJSON部分を検出して抽出
            let validJSONString = extractValidJSON(from: jsonString)
            
            guard let data = validJSONString.data(using: .utf8) else {
                print("JSON文字列をデータに変換できませんでした")
                return [["error": "JSONパースエラー"]]
            }
            
            // JSONをパース
            if let jsonArray = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] {
                // 文字列型のキーと値を持つ辞書の配列に変換
                return jsonArray.map { dict -> [String: String] in
                    var stringDict: [String: String] = [:]
                    for (key, value) in dict {
                        stringDict[key] = String(describing: value)
                    }
                    return stringDict
                }
            } else {
                print("JSONを配列として解析できませんでした")
                return [["error": "JSONパースエラー: 二次元配列ではありません"]]
            }
        } catch {
            print("JSONパースエラー: \(error.localizedDescription)")
            return [["error": "JSONパースエラー: \(error.localizedDescription)"]]
        }
    }
    
    // 文字列から有効なJSON部分を抽出する関数
    private func extractValidJSON(from text: String) -> String {
        // 文字列内の最初の"["と最後の"]"の間の部分を探す
        guard let startIndex = text.firstIndex(of: "["),
              let endIndex = text.lastIndex(of: "]") else {
            return "[]" // 有効なJSON配列が見つからない場合は空配列を返す
        }
        
        let jsonPart = text[startIndex...endIndex]
        return String(jsonPart)
    }
    
    // ユーザー情報を更新
    func updateUser(name: String, language: String? = nil, age: Int? = nil, email: String? = nil) {
        currentUser.name = name
        
        if let language = language {
            currentUser.language = language
        }
        
        if let age = age {
            currentUser.age = age
        }
        
        if let email = email {
            currentUser.email = email
        }
        
        // ユーザー情報が更新されたらシステムプロンプトも更新
        updateSystemPrompt()
    }
    
    // システムプロンプトを更新
    private func updateSystemPrompt() {
        if let index = messages.firstIndex(where: { $0.role == "system" }) {
            var systemPrompt = "提示したオブジェクトについて、そのオブジェクトが開発された際に用いられた(必要に応じてパーツごとに分けて解説することも可)適当な教科の学習単元を\(currentUser.age)歳までの学校指導要領内で回答してください。回答時は以下のJSONフォーマットに必ず従うこと(バックスラッシュは無視)。また、\(currentUser.language)語で回答すること。\n\n"
            systemPrompt += "[{\"subject\":\"教科の名前\",\"object\":\"オブジェクトまたはパーツの名前\",\"curriculum\":\"単元の名前\",\"description\":\"簡単な説明\",\"deep_description\":\"詳細な説明\"}]"
            
            // ユーザー情報を追加
            systemPrompt += "\n\nユーザー情報:\n"
            systemPrompt += "名前: \(currentUser.name)\n"
            systemPrompt += "言語: \(currentUser.language)\n"
            systemPrompt += "年齢: \(currentUser.age)\n"
            
            if let email = currentUser.email {
                systemPrompt += "メール: \(email)\n"
            }
            
            let newSystemMessage = ChatMessage(
                id: UUID().uuidString,
                role: "system",
                content: systemPrompt,
                createdAt: Date()
            )
            
            // 既存のシステムメッセージを更新
            messages[index] = newSystemMessage
        }
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
            // APIメッセージを作成（content部分はそのままの文字列）
            let apiMessages = messages.map { Message(role: $0.role, content: $0.content) }
            let response = try await apiClient.sendMessage(apiMessages)
            
            // 応答JSONを解析して二次元配列に変換
            let parsedContent = response
            
            let assistantMessage = ChatMessage(id: UUID().uuidString, role: "assistant", content: parsedContent, createdAt: Date())
            
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
