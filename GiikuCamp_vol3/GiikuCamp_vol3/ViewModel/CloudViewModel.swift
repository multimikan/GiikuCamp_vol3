import Foundation
import FirebaseFirestore
import FirebaseAuth

class CloudViewModel: ObservableObject {
    @Published var data: Cloud
    private let db = Firestore.firestore()
    
    init() {
        self.data = Cloud(isAgree: false, born: 0, language: "日本語", favorite: [:], email: nil)
    }

    func fetchCloud() async {
        do {
            if let currentUserID = getCurrentUserID() {
                // ログインユーザーのIDに基づいてドキュメントを取得
                let docRef = db.collection("AppUser").document(currentUserID)
                let document = try await docRef.getDocument()
                
                if document.exists {
                    DispatchQueue.main.async {
                        self.data = Cloud(
                            DocumentID: document.documentID,
                            isAgree: document.data()?["isAgree"] as? Bool ?? true,
                            born: document.data()?["born"] as? Int ?? 0,
                            language: document.data()?["language"] as? String ?? "日本語",
                            favorite: document.data()?["favorite"] as? [String: [String: Bool]] ?? [:],
                            email: document.data()?["email"] as? String
                        )
                    }
                    print("Document data: \(document.data() ?? [:])")
                } else {
                    print("Document does not exist for user \(currentUserID), creating new document")
                    // 現在のユーザーのメールアドレスを取得
                    let email = Auth.auth().currentUser?.email
                    
                    // 新しいドキュメントを作成
                    let newData = Cloud(
                        DocumentID: currentUserID,
                        isAgree: true,
                        born: 2004,
                        language: "日本",
                        favorite: [
                            "小学": ["算数": true, "理科": true],
                            "中学": ["数学": true, "理科": true],
                            "高校": ["数学123": true, "数学ABC": true, "化学": true, "物理": true, "生物": true]
                        ],
                        email: email
                    )
                    
                    DispatchQueue.main.async {
                        self.data = newData
                    }
                    
                    // 初期データを保存
                    await saveData()
                }
            } else {
                // ユーザーがログインしていない場合、匿名のデフォルトドキュメントを探す
                print("No user logged in, retrieving or creating anonymous document")
                
                // アプリ内で一時的に使用するデータを設定
                DispatchQueue.main.async {
                    self.data = Cloud(
                        isAgree: true,
                        born: 0,
                        language: "日本語",
                        favorite: [:],
                        email: nil
                    )
                }
            }
        } catch {
            print("Error getting documents: \(error)")
        }
    }
    
    private func getCurrentUserID() -> String? {
        return Auth.auth().currentUser?.uid
    }
    
    func saveData() async {
        do {
            // ユーザーIDがある場合はそれを使用
            if let currentUserID = getCurrentUserID() {
                var docRef: DocumentReference
                
                if let existingID = data.DocumentID {
                    // 既存のドキュメントIDがある場合はそれを使用
                    docRef = db.collection("AppUser").document(existingID)
                } else {
                    // ユーザーIDをドキュメントIDとして使用
                    docRef = db.collection("AppUser").document(currentUserID)
                }
                
                // 現在のメールアドレスが設定されていない場合は、Authから取得
                let email = data.email ?? Auth.auth().currentUser?.email
                
                try await docRef.setData([
                    "isAgree": data.isAgree,
                    "born": data.born,
                    "language": data.language,
                    "favorite": data.favorite,
                    "email": email as Any
                ])
                
                // ドキュメントIDとメールアドレスを更新
                DispatchQueue.main.async {
                    self.data.DocumentID = docRef.documentID
                    if self.data.email == nil {
                        self.data.email = email
                    }
                }
                
                print("Document successfully written!")
            } else {
                print("Cannot save data: No user ID available")
            }
        } catch {
            print("Error writing document: \(error)")
        }
    }
}
