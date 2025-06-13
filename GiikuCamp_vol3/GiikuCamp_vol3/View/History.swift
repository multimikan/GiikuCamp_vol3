import SwiftUI
import FirebaseFirestore // Firestoreのためにインポート
import FirebaseAuth    // Authのためにインポート

// モデル
struct HistoryItem: Identifiable, Equatable {
    let id = UUID() // これはローカルでのIdentifiable用。FirestoreのIDとは別。
    var docID: String? // FirestoreのドキュメントID（削除時に使用）
    let subject: String
    let object: String
    let curriculum: String
    let description: String
    let deep_description: String
    let image_url: String? // 画像URLプロパティを追加
    var color: Color // subjectに基づいて色を決定する例

    // Equatable の実装（docIDが同じなら同じアイテムとみなす）
    static func == (lhs: HistoryItem, rhs: HistoryItem) -> Bool {
        lhs.docID == rhs.docID && lhs.docID != nil // docIDがあり、かつ一致する場合
    }
}

// ビューモデル
class HistoryViewModel: ObservableObject {
    @Published var historyItems: [HistoryItem] = [] // プロパティ名を historyes から historyItems に変更
    @Published var filterSubject: String? = nil
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    private var db = Firestore.firestore()
    private var authViewModel: AuthViewModel // AuthViewModelを保持

    // 表示用の一時的な色割り当て（実際のアプリではより良い方法を検討）
    private func colorForSubject(_ subject: String) -> Color {
        // 簡単なハッシュや固定マップで色を決定する例
        let colors: [Color] = [.red, .green, .blue, .orange, .purple, .pink, .yellow, .cyan, .mint]
        let hash = subject.hashValue
        return colors[abs(hash) % colors.count]
    }

    init(authViewModel: AuthViewModel) {
        self.authViewModel = authViewModel
        // fetchHistory() // initで呼ぶよりonAppearで呼ぶ方が一般的
    }

    var filteredHistoryItems: [HistoryItem] { // プロパティ名を filteredFavorites から変更
        if let filter = filterSubject, !filter.isEmpty {
            return historyItems.filter { $0.subject == filter }
        } else {
            return historyItems
        }
    }

    var availableSubjects: [String] {
        Array(Set(historyItems.map { $0.subject })).sorted()
    }

    @MainActor
    func fetchHistory() async {
        guard let userID = authViewModel.user?.uid else {
            errorMessage = "ユーザーがログインしていません。"
            historyItems = [] // ユーザーがいない場合は空にする
            return
        }
        
        self.isLoading = true
        self.errorMessage = nil
        
        let gptLogCollectionRef = db.collection("AppUser").document(userID).collection("GPT")
        
        do {
            let snapshot = try await gptLogCollectionRef.order(by: "timestamp", descending: true).getDocuments()
            var fetchedItems: [HistoryItem] = []
            
            for document in snapshot.documents {
                let data = document.data()
                let objectName = data["objectName"] as? String ?? "不明なオブジェクト"
                // let responseText = data["responseText"] as? String ?? ""
                let timestamp = data["timestamp"] as? Timestamp // これはGPTResponseLogのルートにある
                
                if let parsedExplanations = data["parsedExplanations"] as? [[String: Any]] {
                    for explanationDict in parsedExplanations {
                        // [[String:String]] ではなく [[String:Any]] で受けてキャストする
                        let subject = explanationDict["subject"] as? String ?? "不明な教科"
                        let object = explanationDict["object"] as? String ?? objectName // explanationのobjectがなければ応答対象のobjectName
                        let curriculum = explanationDict["curriculum"] as? String ?? "不明な単元"
                        let description = explanationDict["description"] as? String ?? "説明なし"
                        let deep_description = explanationDict["deep_description"] as? String ?? "詳細説明なし"
                        
                        //エラー項目は履歴に表示しない
                        if subject == "不明な教科" && curriculum == "不明な単元" && description == "説明なし" && explanationDict["error"] != nil{
                            continue
                        }
                        
                        let historyItem = HistoryItem(
                            docID: document.documentID, // GPTResponseLog全体のドキュメントIDを紐づける
                            subject: subject,
                            object: object,
                            curriculum: curriculum,
                            description: description,
                            deep_description: deep_description,
                            image_url: explanationDict["image_url"] as? String,
                            color: colorForSubject(subject) // subjectに基づいて色を決定
                        )
                        fetchedItems.append(historyItem)
                    }
                } else if let errorMsg = (data["parsedExplanations"] as? [[String:String]])?.first?["error"] {
                    // パースエラーの場合も何らかの形でログとして残すか検討。今回は表示しない。
                     print("Skipping error log in history: \(errorMsg)")
                } else if let responseText = data["responseText"] as? String, responseText.contains("I'm sorry, but I can't assist") {
                    // APIが支援不可と返した場合も表示しない
                    print("Skipping API unfulfillable request in history")
                }
                // ここでタイムスタンプや生のresponseTextをHistoryItemに含めるかも検討
            }
            self.historyItems = fetchedItems
        } catch {
            print("Error fetching history: \(error.localizedDescription)")
            self.errorMessage = "履歴の取得に失敗しました: \(error.localizedDescription)"
            self.historyItems = []
        }
        self.isLoading = false
    }

    @MainActor
    func deleteHistoryItem(item: HistoryItem) async {
        guard let userID = authViewModel.user?.uid, let docID = item.docID else {
            errorMessage = "アイテムの削除に失敗しました (ユーザーIDまたはドキュメントIDがありません)"
            return
        }
        
        // parsedExplanations が配列で、HistoryItem がその中の一つを表す場合、
        // ドキュメント全体を消すのではなく、配列内の該当要素を削除してドキュメントを更新する方が適切かもしれない。
        // 今回は簡単のため、GPTResponseLogのドキュメントごと削除する。
        // (つまり、同じ応答から生成された他の履歴アイテムも一緒に消える)
        
        let docRef = db.collection("AppUser").document(userID).collection("GPT").document(docID)
        
        do {
            try await docRef.delete()
            // ローカルの配列からも削除
            if let index = historyItems.firstIndex(where: { $0.docID == docID }) {
                 // 同じdocIDを持つ全てのアイテムを削除（parsedExplanationsの各要素がHistoryItemになるため）
                historyItems.removeAll { $0.docID == docID }
            }
            print("History item (docID: \(docID)) deleted successfully.")
        } catch {
            print("Error deleting history item: \(error.localizedDescription)")
            self.errorMessage = "履歴アイテムの削除に失敗しました。"
        }
    }
}

// ビュー
struct HistoryView: View {
    @StateObject var viewModel: HistoryViewModel
    @State var isPresented: Bool = false
    
    init(authViewModel: AuthViewModel = AuthViewModel()) {
        _viewModel = StateObject(wrappedValue: HistoryViewModel(authViewModel: authViewModel))
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                if viewModel.isLoading {
                    ProgressView("履歴を読み込み中...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                } else {
                    HStack {
                        Text("フィルター：")
                            .font(.subheadline)
                        Picker("フィルター", selection: $viewModel.filterSubject) {
                            Text("すべて").tag(nil as String?)
                            ForEach(viewModel.availableSubjects, id: \.self) { subject in
                                Text(subject).tag(Optional(subject))
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    .padding(.horizontal)
                    .padding(.top)

                    ScrollView {
                        if viewModel.filteredHistoryItems.isEmpty {
                            Text("履歴はありません。")
                                .foregroundColor(.gray)
                                .padding()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            LazyVStack(spacing: 16) {
                                ForEach(viewModel.filteredHistoryItems) { item in
                                    Button(action: {isPresented = true}) {
                                        VStack(alignment: .leading, spacing: 8) {
                                            HStack {
                                                Text("\(item.subject) - \(item.object)")
                                                    .font(.headline)
                                                    .foregroundColor(Color.primary)
                                                Spacer()
                                                Button(action: {
                                                    Task {
                                                        await viewModel.deleteHistoryItem(item: item)
                                                    }
                                                }) {
                                                    Image(systemName: "trash")
                                                        .foregroundColor(.red)
                                                }
                                                .buttonStyle(.borderless)
                                            }
                                            Text(item.curriculum)
                                                .font(.subheadline)
                                                .bold()
                                                .foregroundColor(Color.primary)
                                            Text(item.description)
                                                .font(.footnote)
                                                .foregroundColor(.secondary)
                                                .lineLimit(2)
                                        }
                                        .padding()
                                        .background(item.color.opacity(0.15))
                                        .cornerRadius(12)
                                        
                                        .sheet(isPresented: $isPresented){
                                            HistoryDetailView(item: item)
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                            .padding(.bottom)
                        }
                    }
                }
            }
            .onAppear {
                Task {
                    await viewModel.fetchHistory()
                }
            }
        }
    }
}

#Preview {
    // PreviewではAuthViewModelのモックまたは実際のインスタンスを渡す
    // 簡単のため、ここではデフォルトイニシャライザを使用
    HistoryView(authViewModel: AuthViewModel())
}
