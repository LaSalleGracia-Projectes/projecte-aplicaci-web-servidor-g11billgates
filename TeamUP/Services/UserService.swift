import Foundation

class UserService {
    static let shared = UserService()
    private let baseURL = "http://localhost:8080/users"
    
    func incrementSwipes(userId: String) async throws -> Int {
        guard let url = URL(string: "\(baseURL)/\(userId)/swipe") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let user = try JSONDecoder().decode(User.self, from: data)
        return user.swipes
    }
} 