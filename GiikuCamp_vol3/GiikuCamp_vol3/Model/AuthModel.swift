import Foundation
import FirebaseAuth

// User型をAppUserに変更して名前の衝突を回避
struct AppUser {
    let uid: String
    let email: String?
    let displayName: String?
    let photoURL: URL?
    
    init(user: FirebaseAuth.User) {
        self.uid = user.uid
        self.email = user.email
        self.displayName = user.displayName
        self.photoURL = user.photoURL
    }
}

enum AuthError: Error {
    case signInError
    case signOutError
    case noCurrentUser
    
    var message: String {
        switch self {
        case .signInError:
            return "サインインに失敗しました。もう一度お試しください。"
        case .signOutError:
            return "サインアウトに失敗しました。"
        case .noCurrentUser:
            return "ユーザー情報が見つかりません。"
        }
    }
} 