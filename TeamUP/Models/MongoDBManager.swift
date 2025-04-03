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
        
        // Create the user document
        let userDocument: [String: Any] = [
            "IDUsuario": user.id,
            "Nombre": user.name,
            "Correo": email,
            "Contraseña": password,
            "FotoPerfil": user.profileImage,
            "Edad": user.age,
            "Region": "Not specified"
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
}

enum MongoDBError: Error {
    case invalidURL
    case serverError(message: String = "Unknown server error")
    case registrationFailed(Error)
    case gameAdditionFailed(Error)
    case loginFailed(message: String)
    case invalidResponse
    
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
        }
    }
} 