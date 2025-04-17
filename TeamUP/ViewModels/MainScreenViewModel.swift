import SwiftUI

class MainScreenViewModel: ObservableObject {
    @Published var currentIndex = 0
    @Published var users: [User] = []
    @Published var showMatch = false
    @Published var matchedUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    init() {
        // Usar datos de prueba temporalmente
        loadMockUsers()
    }
    
    private func loadMockUsers() {
        let mockUsers = [
            User(
                id: "1",
                name: "Usuario 1",
                age: 25,
                gender: "Hombre",
                description: "Jugador casual",
                games: [
                    Game(nombre: "League of Legends", rango: "Oro"),
                    Game(nombre: "Valorant", rango: "Plata")
                ],
                profileImage: "default_profile",
                matchPercentage: 80,
                commonGames: [
                    UserCommonGame(name: "League of Legends", userRank: "Oro", otherUserRank: "Plata"),
                    UserCommonGame(name: "Valorant", userRank: "Plata", otherUserRank: "Oro")
                ]
            ),
            User(
                id: "2",
                name: "Usuario 2",
                age: 30,
                gender: "Mujer",
                description: "Jugadora competitiva",
                games: [
                    Game(nombre: "League of Legends", rango: "Diamante"),
                    Game(nombre: "Overwatch 2", rango: "Máster")
                ],
                profileImage: "default_profile",
                matchPercentage: 75,
                commonGames: [
                    UserCommonGame(name: "League of Legends", userRank: "Diamante", otherUserRank: "Platino")
                ]
            )
        ]
        
        self.users = mockUsers
    }
    
    func dislikeUser() {
        if currentIndex < users.count {
            withAnimation {
                currentIndex += 1
            }
        }
    }
    
    func likeUser(_ userId: String) async {
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
    let gender: String?
    let region: String?
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
