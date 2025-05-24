import SwiftUI

struct ProfileView: View {
    @ObservedObject var authViewModel: AuthViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            // ユーザーアイコン
            if let photoURL = authViewModel.user?.photoURL {
                AsyncImage(url: photoURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                } placeholder: {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 100, height: 100)
                        .overlay(
                            ProgressView()
                        )
                }
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .foregroundColor(.gray)
            }
            
            // ユーザー名
            Text(authViewModel.user?.displayName ?? "ゲスト")
                .font(.title)
                .fontWeight(.bold)
            
            // メールアドレス
            if let email = authViewModel.user?.email {
                Text(email)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Divider()
                .padding(.vertical)
            
            // サインアウトボタン
            Button {
                authViewModel.signOut()
            } label: {
                Text("サインアウト")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .cornerRadius(10)
            }
            .padding(.horizontal, 30)
            
            Spacer()
        }
        .padding()
        .navigationTitle("プロフィール")
    }
}

#Preview {
    ProfileView(authViewModel: AuthViewModel())
} 