import Foundation
import FirebaseAuth
import GoogleSignIn
import FirebaseCore

class AuthViewModel: ObservableObject {
    @Published var user: AppUser?
    @Published var isAuthenticated = false
    @Published var errorMessage: String?
    @Published var isLoading = false
    
    init() {
        setupAuthStateListener()
    }
    
    private func setupAuthStateListener() {
        Auth.auth().addStateDidChangeListener { [weak self] _, firebaseUser in
            guard let self = self else { return }
            
            if let firebaseUser = firebaseUser {
                self.user = AppUser(user: firebaseUser)
                // self.isAuthenticated = true // この行をコメントアウトまたは削除
            } else {
                self.user = nil
                // self.isAuthenticated = false // この行も、ログアウト時に明示的に設定するため不要な場合がありますが、一旦残します
            }
        }
    }
    
    func signInWithGoogle() async {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            self.errorMessage = "クライアントIDが見つかりません"
            return
        }
        
        // Google Sign Inの設定
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        DispatchQueue.main.async {
            self.isLoading = true
        }
        
        do {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let rootViewController = windowScene.windows.first?.rootViewController else {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "画面の取得に失敗しました"
                }
                return
            }
            
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
            
            guard let idToken = result.user.idToken?.tokenString else {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "トークンの取得に失敗しました"
                }
                return
            }
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: result.user.accessToken.tokenString)
            
            let authResult = try await Auth.auth().signIn(with: credential)
            DispatchQueue.main.async {
                self.user = AppUser(user: authResult.user)
                print("[AuthViewModel] Setting isAuthenticated to true")
                self.isAuthenticated = true
                print("[AuthViewModel] isAuthenticated is now \(self.isAuthenticated)")
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            // Google Sign Outも行う
            GIDSignIn.sharedInstance.signOut()
            
            self.user = nil
            self.isAuthenticated = false
        } catch {
            self.errorMessage = AuthError.signOutError.message
        }
    }
    
    func getCurrentUser() -> AppUser? {
        if let firebaseUser = Auth.auth().currentUser {
            return AppUser(user: firebaseUser)
        }
        return nil
    }
} 
