import SwiftUI

struct ProfileView: View {
    // AuthViewModel は親Viewから渡されることを想定
    // 親Viewが @StateObject で AuthViewModel を管理し、このViewに渡すか、
    // .environmentObject で共有されているものを @EnvironmentObject で受け取る。
    @ObservedObject var authViewModel: AuthViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            // ユーザーアイコン
            if let photoURL = authViewModel.user?.photoURL {
                AsyncImage(url: photoURL) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: 100, height: 100)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                    case .failure:
                        Image(systemName: "person.circle.fill") // エラー時フォールバック
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 100, height: 100)
                            .foregroundColor(.gray)
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .foregroundColor(.gray)
            }
            
            Text(authViewModel.user?.displayName ?? "ゲスト")
                .font(.title)
                .fontWeight(.bold)
            
            if let email = authViewModel.user?.email, !email.isEmpty {
                Text(email)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Divider()
                .padding(.vertical)
            
            Button {
                // TODO: サインアウト処理中のローディング表示などを検討 (authViewModel.isLoadingなど)
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
            // TODO: プロファイル編集機能への導線を追加検討
        }
        .padding()
        .navigationTitle("プロフィール")
        // .navigationBarTitleDisplayMode(.inline) // 必要に応じて表示モード調整
    }
}

#Preview {
    // Previewでは、AuthViewModelのモックまたは実際のインスタンスを生成して渡す。
    // AuthViewModelがシングルトンやEnvironmentObjectとしてアプリ全体で共有される場合、
    // Previewでもそのようにセットアップするか、ダミーデータを設定したインスタンスを使う。
    let previewAuthViewModel = AuthViewModel() 
    // 必要なら previewAuthViewModel.user にダミーデータを設定
    // 例: previewAuthViewModel.user = User(uid: "previewUser", email: "preview@example.com", displayName: "Preview User", photoURL: URL(string: "https://example.com/avatar.png"))
    
    return NavigationView { // ナビゲーションタイトルを表示するためにNavigationViewでラップ
        ProfileView(authViewModel: previewAuthViewModel)
    }
} 