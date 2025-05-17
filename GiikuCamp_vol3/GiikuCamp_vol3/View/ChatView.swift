import SwiftUI

struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()
    
    var body: some View {
        VStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(viewModel.messages) { message in
                        MessageBubble(message: message)
                    }
                }
                .padding(.horizontal)
            }
            
            Divider()
            
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
            }
            .padding()
        }
        .navigationTitle("GPT Chat")
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.role == "user" {
                Spacer()
            }
            
            VStack(alignment: message.role == "user" ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .padding(10)
                    .background(message.role == "user" ? Color.blue.opacity(0.2) : Color.gray.opacity(0.2))
                    .cornerRadius(12)
                
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