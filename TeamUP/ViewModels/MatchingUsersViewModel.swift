import Foundation
import SwiftUI

class MatchingUsersViewModel: ObservableObject {
    @Published var matchingUsers: [MatchingUser] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    init() {
        loadMockUsers()
    }
    
    private func loadMockUsers() {
        let mockUsers = [
            MatchingUser(
                id: 1,
                name: "Usuario 1",
                profileImage: "default_profile",
                games: [
                    MatchingUser.Game(nombre: "League of Legends", rango: "Oro"),
                    MatchingUser.Game(nombre: "Valorant", rango: "Plata")
                ],
                age: 25,
                gender: "Hombre",
                region: "Europa",
                description: "Jugador casual",
                matchPercentage: 80,
                commonGames: [
                    MatchingUser.CommonGame(nombre: "League of Legends", miRango: "Oro", suRango: "Plata"),
                    MatchingUser.CommonGame(nombre: "Valorant", miRango: "Plata", suRango: "Oro")
                ]
            ),
            MatchingUser(
                id: 2,
                name: "Usuario 2",
                profileImage: "default_profile",
                games: [
                    MatchingUser.Game(nombre: "League of Legends", rango: "Diamante"),
                    MatchingUser.Game(nombre: "Overwatch 2", rango: "Máster")
                ],
                age: 30,
                gender: "Mujer",
                region: "América",
                description: "Jugadora competitiva",
                matchPercentage: 75,
                commonGames: [
                    MatchingUser.CommonGame(nombre: "League of Legends", miRango: "Diamante", suRango: "Platino")
                ]
            )
        ]
        
        self.matchingUsers = mockUsers
    }
    
    struct MatchingUser: Decodable, Identifiable {
        let id: Int
        let name: String
        let profileImage: String
        let games: [Game]
        let age: Int
        let gender: String?
        let region: String?
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
} 
