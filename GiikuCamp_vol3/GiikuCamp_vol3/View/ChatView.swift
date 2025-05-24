import SwiftUI

struct ChatView: View {
    @EnvironmentObject var cloudViewModel: CloudViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var chatViewModel: ChatViewModel

    var body: some View {
        VStack {
            HeaderView(cloudViewModel: cloudViewModel, chatViewModel: chatViewModel)
            
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(chatViewModel.messages.filter { $0.role != "system" }) { message in
                        MessageBubble(message: message)
                    }
                }
                .padding(.horizontal)
            }
            
            Divider()
            
            MessageInputView(viewModel: chatViewModel)
        }
        .navigationTitle("GPT Chat")
        .sheet(isPresented: $chatViewModel.isUserProfileSheetPresented) {
            UserProfileView(
                viewModel: chatViewModel,
                isPresented: $chatViewModel.isUserProfileSheetPresented
            )
            .environmentObject(cloudViewModel)
        }
        .onAppear {
            chatViewModel.onChatViewAppear()
        }
    }
}

struct HeaderView: View {
    @ObservedObject var cloudViewModel: CloudViewModel
    @ObservedObject var chatViewModel: ChatViewModel

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("言語: \(cloudViewModel.data.language)")
                    .font(.caption)
                    .foregroundColor(.gray)
                if let email = cloudViewModel.data.email, !email.isEmpty {
                    Text("メール: \(email)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            Spacer()
            Button("プロフィール") {
                chatViewModel.showUserProfile()
            }
            .font(.caption)
        }
        .padding(.horizontal)
    }
}

struct MessageInputView: View {
    @ObservedObject var viewModel: ChatViewModel

    var body: some View {
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
                CameraView()
            }
        }
        .padding()
    }
}

struct UserProfileView: View {
    @ObservedObject var viewModel: ChatViewModel
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("基本情報")) {
                    TextField("言語", text: $viewModel.userProfileLanguage)
                    TextField("年齢", text: $viewModel.userProfileAge)
                        .keyboardType(.numberPad)
                }
                
                Section(header: Text("連絡先")) {
                    TextField("メールアドレス", text: $viewModel.userProfileEmail)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
            }
            .navigationTitle("ユーザー設定")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        isPresented = false
                        viewModel.resetProfileChanges()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        viewModel.saveUserProfile()
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
            .environmentObject(CloudViewModel())
            .environmentObject(AuthViewModel())
            .environmentObject(ChatViewModel())
    }
} 
