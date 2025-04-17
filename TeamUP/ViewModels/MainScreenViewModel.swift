import SwiftUI

class MainScreenViewModel: ObservableObject {
    @Published var currentIndex = 0
    @Published var users: [User] = []
    @Published var showMatch = false
    @Published var matchedUser: User?
    @Published var isLoading = true
    @Published var errorMessage: String?
    
    private let mongoManager = MongoDBManager.shared
    private let authManager = AuthenticationManager.shared
    private var currentUserId: String {
        authManager.currentUser?.id ?? ""
    }
    
    init() {
        Task {
            await loadMatchingUsers()
        }
    }
    
    @MainActor
    func loadMatchingUsers() async {
        isLoading = true
        do {
            // Usar la URL base desde las variables de entorno o un valor por defecto
            let baseURL = "http://localhost:3000"
            guard let url = URL(string: "\(baseURL)/api/users/matching?userId=\(currentUserId)") else {
                throw URLError(.badURL)
            }
            
            let (data, _) = try await URLSession.shared.data(from: url)
            let decodedUsers = try JSONDecoder().decode([MatchingUser].self, from: data)
            
            self.users = decodedUsers.map { matchingUser in
                User(
                    id: String(matchingUser.id),
                    name: matchingUser.name,
                    age: matchingUser.age,
                    gender: "Not specified",
                    description: matchingUser.description,
                    games: matchingUser.games.map { ($0.nombre, $0.rango) },
                    profileImage: matchingUser.profileImage,
                    matchPercentage: matchingUser.matchPercentage,
                    commonGames: matchingUser.commonGames.map { game in
                        CommonGame(
                            name: game.nombre,
                            myRank: game.miRango,
                            theirRank: game.suRango
                        )
                    }
                )
            }
            isLoading = false
        } catch {
            errorMessage = "Error loading users: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    func dislikeUser() {
        if currentIndex < users.count {
            withAnimation {
                currentIndex += 1
            }
        }
    }
    
    func likeUser(_ userId: String) async {
        // Implementar lógica de like aquí
        if currentIndex < users.count {
            withAnimation {
                currentIndex += 1
            }
        }
    }
    
    // Esta función se usará cuando implementemos la base de datos
    private func saveMatch(with user: User) {
        // TODO: Implementar la lógica para guardar el match en la base de datos
        // Por ejemplo:
        // DatabaseManager.shared.saveMatch(currentUser: currentUser, matchedUser: user)
    }
}

// Modelos para decodificar la respuesta del servidor
struct MatchingUser: Codable {
    let id: Int
    let name: String
    let profileImage: String
    let games: [GameInfo]
    let age: Int
    let region: String
    let description: String
    let matchPercentage: Int
    let commonGames: [CommonGameInfo]
}

struct GameInfo: Codable {
    let nombre: String
    let rango: String
}

struct CommonGameInfo: Codable {
    let nombre: String
    let miRango: String
    let suRango: String
}

struct CommonGame {
    let name: String
    let myRank: String
    let theirRank: String
}
