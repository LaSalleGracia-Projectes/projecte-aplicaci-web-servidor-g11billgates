import Foundation

class MatchingUsersViewModel: ObservableObject {
    @Published var matchingUsers: [MatchingUser] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let baseURL = "http://localhost:3000"
    
    struct MatchingUser: Decodable, Identifiable {
        let id: Int
        let name: String
        let profileImage: String
        let games: [Game]
        let age: Int
        let region: String
        let description: String
        let matchPercentage: Int
        let commonGames: [CommonGame]
        
        struct Game: Decodable {
            let nombre: String
            let rango: String
        }
        
        struct CommonGame: Decodable {
            let nombre: String
            let miRango: String
            let suRango: String
        }
    }
    
    func fetchMatchingUsers(userId: Int) {
        isLoading = true
        errorMessage = nil
        
        guard let url = URL(string: "\(baseURL)/api/users/matching?userId=\(userId)") else {
            errorMessage = "URL inválida"
            isLoading = false
            return
        }
        
        print("Fetching users from: \(url.absoluteString)")
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = "Error de red: \(error.localizedDescription)"
                    print("Network error: \(error.localizedDescription)")
                    return
                }
                
                guard let data = data else {
                    self?.errorMessage = "No se recibieron datos"
                    print("No data received")
                    return
                }
                
                // Print the raw response for debugging
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("Raw response: \(jsonString)")
                }
                
                do {
                    let users = try JSONDecoder().decode([MatchingUser].self, from: data)
                    print("Successfully decoded \(users.count) users")
                    self?.matchingUsers = users
                } catch {
                    self?.errorMessage = "Error al decodificar los datos: \(error.localizedDescription)"
                    print("Decoding error: \(error)")
                }
            }
        }.resume()
    }
} 
