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
        
        // 初期化時にシステムプロンプトを追加（物体名はプレースホルダーのまま）
        // addDefaultSystemPrompt() は messages を変更するので MainActor で実行
        Task {
            await MainActor.run {
                addDefaultSystemPrompt()
            }
            await refreshUserData()
        }
    }
    
    private func addDefaultSystemPrompt() {
        // システムプロンプトを物体名プレースホルダーで作成
        let systemPrompt = createSystemPrompt(objectName: "!!!OBJECT_NAME!!!") // プレースホルダーを使用
        
        let systemMessage = ChatMessage(
            id: UUID().uuidString,
            role: "system",
            content: systemPrompt,
            createdAt: Date()
        )
        
        // システムメッセージをメッセージリストに追加（UIには表示されない）
        messages.append(systemMessage)
    }
    
    // 物体名を引数に取り、システムプロンプトを生成する
    private func createSystemPrompt(objectName: String) -> String {
        let age = cloudViewModel.data.born
        let language = cloudViewModel.data.language
        print("[ChatViewModel] createSystemPrompt - objectName: \(objectName), age: \(age), language: \(language)")

        var systemPrompt = """
        \(objectName)が開発された際に用いられた原理について、学校で学習する指導要領に関連付けてパーツごとに分けて説明してください。
        例えば、objectName=車ならobject="メーター",curriculum:"微分",description:"一瞬の速度を集めて微分しているんだ"
        説明は、日本の\(age)歳の子どもが理解できるように、\(language)でお願いします。
        その際、\(objectName)に関連する学校の教科と学習単元（もしあれば）を挙げ、簡単な説明と、少し詳しい説明を加えてください。
        回答は算数・数学が一番好ましいです。
        
        さらに、各説明セット（特に"curriculum"や"description"の内容）を視覚的に補足するような、著作権に配慮された**公開されている画像**のURLを一つ提案してください。画像が見つからない場合は null または空文字列としてください。
        
        回答は必ず以下のJSON形式に従ってください。
        バックスラッシュはエスケープせず、そのままJSON文字列として出力してください。

        [
          {
            "subject": "関連する教科名 (例: 理科, 算数など)",
            "object": "(\(language)語に変換した)\(objectName) (または関連する具体的なトピックやパーツ名)",
            "curriculum": "関連する学習単元名 (例: てこの原理, 二次関数など)",
            "description": "子ども向けの簡単な説明",
            "deep_description": "もう少し詳しく、興味を引くような説明",
            "image_url": "提案された画像のURL (存在しない場合はnullまたは空文字列)"
          }
        ]
        """
        return systemPrompt
    }
    
    // JSONをSwiftの二次元配列（[[String: String]]）に変換する関数
    func parseJSONToContentArray(_ jsonString: String) -> [[String: String]] {
        do {
            // 入力されたJSONがそのままパースできない場合は、有効なJSON部分を検出して抽出
            let validJSONString = extractValidJSON(from: jsonString)
            print("[ChatViewModel] Extracted valid JSON string: >>>\(validJSONString)<<<")

            guard !validJSONString.isEmpty, validJSONString != "[]" else {
                print("有効なJSONコンテンツが見つかりませんでした。元の文字列: \(jsonString)")
                return [["error": "有効なJSONコンテンツが見つかりませんでした"]]
            }
            
            guard let data = validJSONString.data(using: .utf8) else {
                print("JSON文字列をデータに変換できませんでした")
                return [["error": "JSONパースエラー: データ変換失敗"]]
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
            print("JSONパースエラー: \\(error.localizedDescription). 元の文字列: \(jsonString)")
            return [["error": "JSONパースエラー: \\(error.localizedDescription)"]]
        }
    }
    
    // 文字列から有効なJSON部分を抽出する関数
    private func extractValidJSON(from text: String) -> String {
        // 文字列内の最初の"["と最後の"]"の間の部分を探す
        guard let startIndex = text.firstIndex(of: "["),
              let endIndex = text.lastIndex(of: "]") else {
            return "[]" // 有効なJSON配列が見つからない場合は空配列を返す
        }
        
        // startIndex と endIndex の間に有効な文字があるか確認
        let potentialJson = text[startIndex...endIndex]
        if potentialJson.trimmingCharacters(in: .whitespacesAndNewlines).count > 2 { // "[]" より大きいことを確認
            return String(potentialJson)
        }
        return "[]"
    }
    
    // システムプロンプトを更新（物体名プレースホルダー版）
    @MainActor // この関数はmessagesを更新するのでMainActorで実行
    func updateSystemPrompt() {
        if let index = messages.firstIndex(where: { $0.role == "system" }) {
            let systemPrompt = createSystemPrompt(objectName: "!!!OBJECT_NAME!!!") // プレースホルダーを使用
            
            let newSystemMessage = ChatMessage(
                id: UUID().uuidString,
                role: "system",
                content: systemPrompt,
                createdAt: Date()
            )
            
            // 既存のシステムメッセージを更新
            messages[index] = newSystemMessage
        } else {
            // システムメッセージがない場合はデフォルトを追加
            addDefaultSystemPrompt()
        }
    }
    
    // Firestoreからデータを最新化
    func refreshUserData() async {
        // CloudViewModelのデータを更新
        await cloudViewModel.fetchCloud() // これがUI更新するなら内部でMainActorが必要
        
        // システムプロンプトを更新（物体名プレースホルダーを維持）
        await updateSystemPrompt() // @MainActor指定された関数を呼び出し
    }
    
    // YOLOで検出された物体名を処理する新しい関数
    func processObjectName(_ objectName: String) async -> [[String: String]]? {
        await MainActor.run {
            isLoading = true
        }
        
        var parsedResult: [[String: String]]? = nil // パース結果を保持する変数名を変更
        var rawResponseText: String = "" // 生のレスポンステキストを保持する変数
        
        do {
            await refreshUserData()
            let specificSystemPrompt = createSystemPrompt(objectName: objectName)
            let apiMessages = [Message(role: "system", content: specificSystemPrompt)]
            
            print("[ChatViewModel] Sending prompt for object: \(objectName)")
            print("[ChatViewModel] System prompt: \(specificSystemPrompt)")

            rawResponseText = try await apiClient.sendMessage(apiMessages)
            print("[ChatViewModel] Raw API Response for \(objectName): >>>\(rawResponseText)<<<")
            
            parsedResult = parseJSONToContentArray(rawResponseText)
            print("[ChatViewModel] Parsed Result for \(objectName): \(String(describing: parsedResult))")
            
            // FirestoreにGPT応答を保存
            // 非同期で実行し、この関数の処理をブロックしない
            Task {
                await cloudViewModel.saveGPTResponse(
                    objectName: objectName, 
                    responseText: rawResponseText, 
                    parsedExplanations: parsedResult
                )
            }
            
        } catch {
            print("[ChatViewModel] Error processing object name: \(error.localizedDescription)")
            rawResponseText = "Error: \(error.localizedDescription)" // エラー時もテキストを記録
            parsedResult = [["error": "APIエラー: \(error.localizedDescription)"]]
            // エラー発生時もログを保存するかは要件次第。今回は成功時のみとするか、エラー情報も保存するか。
            // ここではエラーの場合も保存を試みる（エラーメッセージがresponseTextに入る）
            Task {
                 await cloudViewModel.saveGPTResponse(
                    objectName: objectName, 
                    responseText: rawResponseText, 
                    parsedExplanations: parsedResult // エラー情報を含むパース結果
                )
            }
        }
        
        await MainActor.run {
            isLoading = false
        }
        
        return parsedResult // 変数名を変更したため、ここも合わせる
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
            await refreshUserData()
            
            var apiMessages = messages.map { Message(role: $0.role, content: $0.content) }
            
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
