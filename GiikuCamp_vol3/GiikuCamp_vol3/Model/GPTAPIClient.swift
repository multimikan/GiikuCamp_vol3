import Foundation

class GPTAPIClient {
    private let apiKey: String
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func sendMessage(_ messages: [Message]) async throws -> String {
        guard let url = URL(string: baseURL) else {
            throw URLError(.badURL)
        }
        
        let request = GPTRequest(messages: messages)
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            throw error
        }
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        guard httpResponse.statusCode == 200 else {
            throw NSError(domain: "GPTAPIError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "APIエラー: \(httpResponse.statusCode)"])
        }
        
        do {
            let gptResponse = try JSONDecoder().decode(GPTResponse.self, from: data)
            if let firstChoice = gptResponse.choices.first {
                return firstChoice.message.content
            } else {
                throw NSError(domain: "GPTAPIError", code: 0, userInfo: [NSLocalizedDescriptionKey: "レスポンスにメッセージが含まれていません"])
            }
        } catch {
            throw error
        }
    }
} 