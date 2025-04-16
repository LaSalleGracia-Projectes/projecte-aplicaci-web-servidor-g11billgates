import Foundation

class MongoDBManager {
    static let shared = MongoDBManager()
    // Change this to your actual server IP address or domain
    private let baseURL = "http://localhost:3000"  // Replace XXX with your actual local IP address
    // For production, use your hosted server domain:
    // private let baseURL = "https://your-server-domain.com"
    
    private init() {}
    
    func loginUser(email: String, password: String) async throws -> User {
        guard let url = URL(string: "\(baseURL)/login") else {
            throw MongoDBError.invalidURL
        }
        
        let loginData: [String: Any] = [
            "Correo": email,
            "Contraseña": password
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: loginData)
            request.httpBody = jsonData
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw MongoDBError.serverError(message: "Invalid response")
            }
            
            if !(200...299).contains(httpResponse.statusCode) {
                if let errorDict = try? JSONSerialization.jsonObject(with: data) as? [String: String],
                   let errorMessage = errorDict["error"] {
                    throw MongoDBError.loginFailed(message: errorMessage)
                } else {
                    throw MongoDBError.loginFailed(message: "Login failed with status code: \(httpResponse.statusCode)")
                }
            }
            
            guard let responseDict = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let userData = responseDict["user"] as? [String: Any] else {
                throw MongoDBError.invalidResponse
            }
            
            // Convert games data
            var userGames: [(String, String)] = []
            if let games = userData["games"] as? [[String: Any]] {
                for game in games {
                    if let gameId = game["gameId"] as? String {
                        let rank = String(describing: game["rank"] ?? "Beginner")
                        userGames.append((gameId, rank))
                    }
                }
            }
            
            // Create user object
            let user = User(
                name: userData["name"] as? String ?? "",
                age: userData["age"] as? Int ?? 0,
                gender: userData["gender"] as? String ?? "Not specified",
                description: userData["description"] as? String ?? "",
                games: userGames,
                profileImage: userData["profileImage"] as? String ?? "default_profile"
            )
            
            return user
            
        } catch {
            throw MongoDBError.loginFailed(message: error.localizedDescription)
        }
    }
    
    func registerUser(user: User, email: String, password: String) async throws {
        // Create URL for the registration endpoint
        guard let url = URL(string: "\(baseURL)/register") else {
            throw MongoDBError.invalidURL
        }
        
        // Create the user document with all necessary fields
        let userDocument: [String: Any] = [
            "IDUsuario": user.id,
            "Nombre": user.name,
            "Correo": email,
            "Contraseña": password,
            "FotoPerfil": user.profileImage,
            "Edad": user.age,
            "Region": "Not specified",
            "Descripcion": user.description,
            "Juegos": user.games.map { ["nombre": $0.0, "rango": $0.1] },
            "Genero": user.gender
        ]
        
        // Create the request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: userDocument)
            request.httpBody = jsonData
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw MongoDBError.serverError(message: "Invalid response")
            }
            
            if !(200...299).contains(httpResponse.statusCode) {
                // Try to parse error message from response
                if let errorDict = try? JSONSerialization.jsonObject(with: data) as? [String: String],
                   let errorMessage = errorDict["error"] {
                    throw MongoDBError.serverError(message: errorMessage)
                } else {
                    throw MongoDBError.serverError(message: "Registration failed with status code: \(httpResponse.statusCode)")
                }
            }
            
            // Handle the response
            let responseDict = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            print("User registered successfully: \(String(describing: responseDict))")
            
        } catch {
            throw MongoDBError.registrationFailed(error)
        }
    }
    
    func addUserGame(userId: String, game: Game, rank: String) async throws {
        guard let url = URL(string: "\(baseURL)/addUserGame") else {
            throw MongoDBError.invalidURL
        }
        
        let gameDocument: [String: Any] = [
            "IDUsuario": userId,
            "IDJuego": game.id.uuidString,
            "Estadisticas": "{}", // Empty statistics initially
            "Preferencias": "{}", // Empty preferences initially
            "NivelElo": 1200 // Default ELO rating
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: gameDocument)
            request.httpBody = jsonData
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw MongoDBError.serverError(message: "Invalid response")
            }
            
            if !(200...299).contains(httpResponse.statusCode) {
                // Try to parse error message from response
                if let errorDict = try? JSONSerialization.jsonObject(with: data) as? [String: String],
                   let errorMessage = errorDict["error"] {
                    throw MongoDBError.serverError(message: errorMessage)
                } else {
                    throw MongoDBError.serverError(message: "Adding game failed with status code: \(httpResponse.statusCode)")
                }
            }
            
            let responseDict = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            print("Game added successfully: \(String(describing: responseDict))")
            
        } catch {
            throw MongoDBError.gameAdditionFailed(error)
        }
    }
    
    func getRegisteredUsers() async throws -> [User] {
        guard let url = URL(string: "\(baseURL)/users") else {
            throw MongoDBError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw MongoDBError.serverError(message: "Invalid response")
            }
            
            if !(200...299).contains(httpResponse.statusCode) {
                throw MongoDBError.serverError(message: "Failed to fetch users with status code: \(httpResponse.statusCode)")
            }
            
            guard let usersData = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
                throw MongoDBError.invalidResponse
            }
            
            return usersData.compactMap { userData -> User? in
                guard let name = userData["Nombre"] as? String,
                      let age = userData["Edad"] as? Int,
                      let gender = userData["Genero"] as? String,
                      let description = userData["Descripcion"] as? String,
                      let games = userData["Juegos"] as? [[String: String]] else {
                    return nil
                }
                
                let gamesList = games.compactMap { game -> (String, String)? in
                    guard let name = game["nombre"],
                          let rank = game["rango"] else {
                        return nil
                    }
                    return (name, rank)
                }
                
                return User(
                    name: name,
                    age: age,
                    gender: gender,
                    description: description,
                    games: gamesList,
                    profileImage: userData["FotoPerfil"] as? String ?? "default_profile"
                )
            }
            
        } catch {
            throw MongoDBError.serverError(message: error.localizedDescription)
        }
    }
    
    struct LikeResponse: Codable {
        let isMatch: Bool
        let matchedUser: MatchedUser?
        let message: String
    }

    struct MatchedUser: Codable {
        let id: Int
        let name: String
        let profileImage: String
    }

    struct ErrorResponse: Codable {
        let error: String
        let details: String?
    }

    func likeUser(userId: String, likedUserId: String) async throws -> LikeResponse {
        let url = URL(string: "\(baseURL)/api/users/\(userId)/like")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Añadir token de autenticación si existe
        if let token = UserDefaults.standard.string(forKey: "authToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let body = ["likedUserId": likedUserId]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw MongoDBError.serverError(message: "Respuesta inválida del servidor")
        }
        
        switch httpResponse.statusCode {
        case 200:
            let response = try JSONDecoder().decode(LikeResponse.self, from: data)
            return response
        case 400, 401, 404:
            let errorResponse = try JSONDecoder().decode(ErrorResponse.self, from: data)
            throw MongoDBError.serverError(message: errorResponse.error)
        default:
            throw MongoDBError.serverError(message: "Error desconocido del servidor")
        }
    }
    
    // Función para obtener los matches de un usuario
    func getMatches(userId: String) async throws -> [User] {
        guard let url = URL(string: "\(baseURL)/api/users/\(userId)/matches") else {
            throw MongoDBError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw MongoDBError.serverError(message: "Invalid response")
            }
            
            if !(200...299).contains(httpResponse.statusCode) {
                throw MongoDBError.serverError(message: "Failed to fetch matches with status code: \(httpResponse.statusCode)")
            }
            
            guard let usersData = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
                throw MongoDBError.invalidResponse
            }
            
            return usersData.compactMap { userData -> User? in
                guard let name = userData["Nombre"] as? String,
                      let age = userData["Edad"] as? Int,
                      let gender = userData["Genero"] as? String,
                      let description = userData["Descripcion"] as? String,
                      let games = userData["Juegos"] as? [[String: String]] else {
                    return nil
                }
                
                let gamesList = games.compactMap { game -> (String, String)? in
                    guard let name = game["nombre"],
                          let rank = game["rango"] else {
                        return nil
                    }
                    return (name, rank)
                }
                
                return User(
                    name: name,
                    age: age,
                    gender: gender,
                    description: description,
                    games: gamesList,
                    profileImage: userData["FotoPerfil"] as? String ?? "default_profile"
                )
            }
            
        } catch {
            throw MongoDBError.serverError(message: error.localizedDescription)
        }
    }
    
    // Función para obtener usuarios compatibles
    func getCompatibleUsers(userId: String) async throws -> [User] {
        guard let url = URL(string: "\(baseURL)/api/users/compatible/\(userId)") else {
            throw MongoDBError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw MongoDBError.serverError(message: "Invalid response")
            }
            
            if !(200...299).contains(httpResponse.statusCode) {
                throw MongoDBError.serverError(message: "Failed to fetch compatible users with status code: \(httpResponse.statusCode)")
            }
            
            guard let usersData = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
                throw MongoDBError.invalidResponse
            }
            
            return usersData.compactMap { userData -> User? in
                guard let name = userData["Nombre"] as? String,
                      let age = userData["Edad"] as? Int,
                      let gender = userData["Genero"] as? String,
                      let description = userData["Descripcion"] as? String,
                      let games = userData["Juegos"] as? [[String: String]] else {
                    return nil
                }
                
                let gamesList = games.compactMap { game -> (String, String)? in
                    guard let name = game["nombre"],
                          let rank = game["rango"] else {
                        return nil
                    }
                    return (name, rank)
                }
                
                return User(
                    name: name,
                    age: age,
                    gender: gender,
                    description: description,
                    games: gamesList,
                    profileImage: userData["FotoPerfil"] as? String ?? "default_profile"
                )
            }
            
        } catch {
            throw MongoDBError.serverError(message: error.localizedDescription)
        }
    }

    func getUsers() async throws -> [User] {
        let url = URL(string: "\(baseURL)/api/users")!
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw MongoDBError.serverError(message: "Invalid response")
        }
        
        if !(200...299).contains(httpResponse.statusCode) {
            throw MongoDBError.serverError(message: "Failed with status code: \(httpResponse.statusCode)")
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode([User].self, from: data)
    }

    func getCompatibleUsers() async throws -> [User] {
        guard let userId = UserDefaults.standard.string(forKey: "userId") else {
            throw MongoDBError.authError(message: "No user ID found")
        }
        
        let url = URL(string: "\(baseURL)/api/users/compatible?userId=\(userId)")!
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw MongoDBError.serverError(message: "Invalid response")
        }
        
        if !(200...299).contains(httpResponse.statusCode) {
            throw MongoDBError.serverError(message: "Failed with status code: \(httpResponse.statusCode)")
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode([User].self, from: data)
    }

    func getMatchingUsers(userId: String) async throws -> [User] {
        guard let url = URL(string: "\(baseURL)/api/users/matching?userId=\(userId)") else {
            throw MongoDBError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw MongoDBError.serverError(message: "Invalid response")
        }
        
        if !(200...299).contains(httpResponse.statusCode) {
            throw MongoDBError.serverError(message: "Failed with status code: \(httpResponse.statusCode)")
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode([User].self, from: data)
    }
}

enum MongoDBError: Error {
    case invalidURL
    case serverError(message: String = "Unknown server error")
    case registrationFailed(Error)
    case gameAdditionFailed(Error)
    case loginFailed(message: String)
    case invalidResponse
    case authError(message: String)
    
    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Invalid server URL"
        case .serverError(let message):
            return message
        case .registrationFailed(let error):
            return "Registration failed: \(error.localizedDescription)"
        case .gameAdditionFailed(let error):
            return "Failed to add game: \(error.localizedDescription)"
        case .loginFailed(let message):
            return "Login failed: \(message)"
        case .invalidResponse:
            return "Invalid response from server"
        case .authError(let message):
            return message
        }
    }
} 