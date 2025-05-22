import Foundation

struct User {
    var name: String
    var language: String
    var age: Int
    var email: String?
    
    init(name: String, language: String = "日本語", age: Int = 6, email: String? = nil) {
        self.name = name
        self.language = language
        self.age = age
        self.email = email
    }
}
 
