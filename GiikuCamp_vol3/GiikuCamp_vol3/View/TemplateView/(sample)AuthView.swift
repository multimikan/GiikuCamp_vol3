import SwiftUI
import GoogleSignIn

struct AuthView: View {
    @StateObject private var viewModel = AuthViewModel()
    
    var body: some View {
        ZStack {
            // 背景色
            Color(UIColor.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // アプリロゴ
                Image(systemName: "camera.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .foregroundColor(.blue)
                
                Text("GiikuCamp アプリ")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("画像認識アプリへようこそ")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Spacer()
                    .frame(height: 50)
                
                // Googleログインボタン
                Button {
                    Task {
                        await viewModel.signInWithGoogle()
                    }
                } label: {
                    HStack {
                        // Googleロゴがない場合はシステムアイコンで代用
                        Image(systemName: "g.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20, height: 20)
                            .foregroundColor(.blue)
                        
                        Text("Googleでサインイン")
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                            .background(Color(UIColor.systemBackground))
                    )
                    .cornerRadius(10)
                }
                .padding(.horizontal, 30)
                
                Spacer()
                
                // エラーメッセージ
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }
            }
            .padding()
            
            // ローディングインジケーター
            if viewModel.isLoading {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                
                ProgressView()
                    .scaleEffect(2)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            }
        }
        .onAppear {
            // 既存のユーザーがいるか確認
            if viewModel.getCurrentUser() != nil {
                viewModel.isAuthenticated = true
            }
        }
        .fullScreenCover(isPresented: $viewModel.isAuthenticated) {
            // 認証成功後に表示する画面
            ContentView()
        }
    }
}

#Preview {
    AuthView()
} 