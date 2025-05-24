import Foundation
import SwiftUI
import Combine

class ChatViewModel: ObservableObject {
    // MARK: - Environment Objects
    @EnvironmentObject var cloudViewModel: CloudViewModel // CloudViewModelをEnvironmentObjectとして受け取る

    // MARK: - Published Properties for UI
    @Published var messages: [ChatMessage] = [
        // Preview用のダミーメッセージ
        ChatMessage(role: "user", content: "こんにちは！調子はどうですか？", createdAt: Calendar.current.date(byAdding: .minute, value: -5, to: Date())!),
        ChatMessage(role: "assistant", content: "こんにちは！私は元気です。何かお手伝いできることはありますか？", createdAt: Calendar.current.date(byAdding: .minute, value: -4, to: Date())!)
    ]
    @Published var inputText: String = ""
    @Published var isLoading: Bool = false
    @Published var isUserProfileSheetPresented: Bool = false

    // UserProfileView で使用するプロパティ
    @Published var userProfileLanguage: String = ""
    @Published var userProfileAge: String = ""
    @Published var userProfileEmail: String = ""

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization
    init() {
        // CloudViewModelが注入された後に初期設定を行う場合は、onAppearや別のメソッドで対応
        // ここでは、userProfileの初期値をonAppearで設定することを想定
        print("ChatViewModel initialized")
    }

    // MARK: - Intents / Actions
    func onChatViewAppear() {
        print("ChatView appeared")
        // cloudViewModelが利用可能になった時点でユーザープロファイル情報をロード
        // cloudViewModelのプロパティに直接アクセスするのではなく、
        // cloudViewModelが準備完了であることを確認してからアクセスするのが安全
        // 例: cloudViewModelの初期化完了を待つか、オプショナルバインディングを使う
        // DispatchQueue.main.async { // cloudViewModelの準備を待つために少し遅延させる（より良い方法を検討）
        //     self.loadUserProfileFromCloudViewModel()
        // }
        // TODO: 実際のメッセージ読み込み処理など
    }

    func loadUserProfileFromCloudViewModel() {
        // 注意: このメソッドはcloudViewModelが利用可能な状態で呼び出す必要がある
        // self.userProfileLanguage = cloudViewModel.data.language
        // self.userProfileAge = String(cloudViewModel.data.born)
        // self.userProfileEmail = cloudViewModel.data.email ?? ""
        // print("User profile loaded into ChatViewModel: Lang=\(self.userProfileLanguage)")
        // 上記はCloudViewModelの準備ができていないとクラッシュする可能性があるため、
        // 呼び出し側でcloudViewModelが利用可能であることを保証するか、
        // cloudViewModelのデータが更新されたことを検知して反映する仕組み（例: sink）が必要。
        // 簡単な対処としては、CloudViewModelのdataを監視し、変更があったらこれらの値を更新する。
        // もしくは、ChatViewのonAppearで直接cloudViewModelの値を参照し、
        // UserProfileViewに渡す際にChatViewModelのプロパティにコピーする。
        // ここでは一旦、UserProfileView表示時に値がセットされると仮定。
    }

    func sendMessage() async {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let userMessage = ChatMessage(role: "user", content: inputText)
        
        DispatchQueue.main.async {
            self.messages.append(userMessage)
            let messageToSend = self.inputText
            self.inputText = "" 
            self.isLoading = true
            print("Sending message: \(messageToSend)")
        }

        // --- API呼び出しのダミー ---
        do {
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1秒待機
            DispatchQueue.main.async {
                self.messages.append(ChatMessage(role: "assistant", content: "AIからの返答です: \(userMessage.content)"))
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.isLoading = false
                // TODO: エラーハンドリング
                print("Error during dummy API call: \(error)")
            }
        }
        // --- API呼び出しのダミーここまで ---
    }

    func saveUserProfile() {
        // cloudViewModel.data.language = userProfileLanguage
        // if let age = Int(userProfileAge) {
        //     cloudViewModel.data.born = age
        // }
        // cloudViewModel.data.email = userProfileEmail.isEmpty ? nil : userProfileEmail
        // Task {
        //     await cloudViewModel.saveData()
        // }
        print("User profile save requested: Lang=\(userProfileLanguage), Age=\(userProfileAge), Email=\(userProfileEmail)")
        // isUserProfileSheetPresented = false // 保存後にシートを閉じる場合
        // TODO: 実際にCloudViewModel経由でデータを保存する処理
    }

    func resetProfileChanges() {
        // UserProfileViewを開いたときのCloudViewModelのデータでリセット
        // loadUserProfileFromCloudViewModel() // 再度CloudViewModelから読み込む
        print("User profile changes reset requested.")
        // TODO: 実際にCloudViewModelから値を再読み込みする処理
    }
    
    func showUserProfile() {
        // プロフィールシート表示時に現在のユーザー情報をViewModelにコピー
        // self.userProfileLanguage = cloudViewModel.data.language
        // self.userProfileAge = String(cloudViewModel.data.born)
        // self.userProfileEmail = cloudViewModel.data.email ?? ""
        // print("Showing user profile. Initial values: Lang=\(userProfileLanguage)")
        isUserProfileSheetPresented = true
    }
}

// ChatMessage 構造体の定義をここから削除
// struct ChatMessage: Identifiable {
//     let id: String
//     let role: String
//     let content: String
//     let createdAt: Date
// } 
