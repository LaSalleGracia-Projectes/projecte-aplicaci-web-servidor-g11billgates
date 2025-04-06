func getCompatibleUsers(userId: String) async throws -> [User] {
    guard let url = URL(string: "\(baseURL)/api/users/compatible?userId=\(userId)") else {
        throw NSError(domain: "Invalid URL", code: -1)
    }
    
    let (data, response) = try await URLSession.shared.data(from: url)
    
    guard let httpResponse = response as? HTTPURLResponse else {
        throw NSError(domain: "Invalid response", code: -1)
    }
    
    guard httpResponse.statusCode == 200 else {
        throw NSError(domain: "Server error", code: httpResponse.statusCode)
    }
    
    let users = try JSONDecoder().decode([User].self, from: data)
    return users
} 