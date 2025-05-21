import Foundation
import SwiftUI

class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""
    @Published var isLoading: Bool = false
    
    private let apiClient: GPTAPIClient
    private let cloudViewModel: CloudViewModel
    
    init(apiClient: GPTAPIClient = GPTAPIClient(apiKey: MyEnvironment.openAIAPIKey),
         cloudViewModel: CloudViewModel) {
        self.apiClient = apiClient
        self.cloudViewModel = cloudViewModel
        
        // 初期化時にシステムプロンプトを追加
        addDefaultSystemPrompt()
        
        // 初期化時にFirestoreからデータを取得
        Task {
            await refreshUserData()
        }
    }
    
    private func addDefaultSystemPrompt() {
        // システムプロンプトをここに設定
        let systemPrompt = createSystemPrompt()
        
        let systemMessage = ChatMessage(
            id: UUID().uuidString,
            role: "system",
            content: systemPrompt,
            createdAt: Date()
        )
        
        // システムメッセージをメッセージリストに追加（UIには表示されない）
        messages.append(systemMessage)
    }
    
    private func createSystemPrompt() -> String {
        let age = cloudViewModel.data.born
        let language = cloudViewModel.data.language
        
        var systemPrompt = "提示したオブジェクトについて、そのオブジェクトが開発された際に用いられたパーツごとに適当な教科の学習単元を\(age)歳までの学校指導要領内でユーザーに説明してください。回答時は、ユーザーが13歳未満の際は漢字を使わずにフランクな口調で回答をお願いします。回答時は以下のJSONフォーマットに必ず従うこと(バックスラッシュは無視)。また、\(language)語で回答すること。\n\n"
        systemPrompt += "[{\"subject\":\"教科の名前\",\"object\":\"オブジェクトまたはパーツの名前\",\"curriculum\":\"単元の名前\",\"description\":\"簡単な説明\",\"deep_description\":\"詳細な説明\"}]"
        
        return systemPrompt
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
    
    // システムプロンプトを更新
    func updateSystemPrompt() {
        if let index = messages.firstIndex(where: { $0.role == "system" }) {
            let systemPrompt = createSystemPrompt()
            
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
    
    // Firestoreからデータを最新化
    func refreshUserData() async {
        // CloudViewModelのデータを更新
        await cloudViewModel.fetchCloud()
        
        // システムプロンプトを更新
        updateSystemPrompt()
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
            // Firestoreからの最新データを取得
            await refreshUserData()
            
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
