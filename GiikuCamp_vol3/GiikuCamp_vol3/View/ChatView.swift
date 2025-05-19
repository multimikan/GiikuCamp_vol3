import SwiftUI

struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()
    @State private var showingUserProfile = false
    @State private var userName = ""
    @State private var userLanguage = ""
    @State private var userAge = ""
    @State private var userEmail = ""
    
    var body: some View {
        VStack {
            // ヘッダー（ユーザー情報）
            HStack {
                Text("ユーザー: \(viewModel.currentUser.name)")
                    .font(.caption)
                    .foregroundColor(.gray)
                Spacer()
                Button("プロフィール") {
                    userName = viewModel.currentUser.name
                    userLanguage = viewModel.currentUser.language
                    userAge = String(viewModel.currentUser.age)
                    userEmail = viewModel.currentUser.email ?? ""
                    showingUserProfile = true
                }
                .font(.caption)
            }
            .padding(.horizontal)
            
            // チャット表示部分
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(viewModel.messages.filter { $0.role != "system" }) { message in
                        MessageBubble(message: message)
                    }
                }
                .padding(.horizontal)
            }
            
            Divider()
            
            // 入力フィールド
            HStack {
                TextField("メッセージを入力", text: $viewModel.inputText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disabled(viewModel.isLoading)
                
                Button(action: {
                    Task {
                        await viewModel.sendMessage()
                    }
                }) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.blue)
                }
                .disabled(viewModel.isLoading || viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                NavigationLink("📷絶対決めてみせる"){
                    SampleCameraView()
                }
            }
            .padding()
        }
        .navigationTitle("GPT Chat")
        .sheet(isPresented: $showingUserProfile) {
            UserProfileView(
                userName: $userName,
                userLanguage: $userLanguage,
                userAge: $userAge,
                userEmail: $userEmail,
                onSave: {
                    viewModel.updateUser(
                        name: userName,
                        language: userLanguage,
                        age: Int(userAge) ?? viewModel.currentUser.age,
                        email: userEmail.isEmpty ? nil : userEmail
                    )
                },
                isPresented: $showingUserProfile
            )
        }
    }
}

struct UserProfileView: View {
    @Binding var userName: String
    @Binding var userLanguage: String
    @Binding var userAge: String
    @Binding var userEmail: String
    var onSave: () -> Void
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("基本情報")) {
                    TextField("名前", text: $userName)
                    TextField("言語", text: $userLanguage)
                    TextField("年齢", text: $userAge)
                        .keyboardType(.numberPad)
                }
                
                Section(header: Text("連絡先")) {
                    TextField("メール (任意)", text: $userEmail)
                        .keyboardType(.emailAddress)
                }
            }
            .navigationTitle("ユーザー設定")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        onSave()
                        isPresented = false
                    }
                }
            }
        }
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    @State private var isExpanded = false
    
    var body: some View {
        HStack {
            if message.role == "user" {
                Spacer()
            }
            
            VStack(alignment: message.role == "user" ? .trailing : .leading, spacing: 4) {
                if message.role == "assistant" {
                    // アシスタントの応答はJSONをパースして表示
                    VStack(alignment: .leading, spacing: 8) {
                        Text(message.content)
                            .lineLimit(isExpanded ? nil : 5)
                            .padding(10)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(12)
                        
                        if message.content.count > 100 {
                            Button(isExpanded ? "折りたたむ" : "すべて表示") {
                                isExpanded.toggle()
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                    }
                } else {
                    // ユーザーメッセージはそのまま表示
                    Text(message.content)
                        .padding(10)
                        .background(message.role == "user" ? Color.blue.opacity(0.2) : Color.gray.opacity(0.2))
                        .cornerRadius(12)
                }
                
                Text(formatDate(message.createdAt))
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            
            if message.role == "assistant" {
                Spacer()
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

#Preview {
    NavigationView {
        ChatView()
    }
} 
