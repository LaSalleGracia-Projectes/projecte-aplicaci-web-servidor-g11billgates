import SwiftUI

class UserViewModel: ObservableObject {
    @Published var user: User
    @Published var isEditingProfile = false
    @Published var tempBio: String = ""
    @Published var selectedGames: [Game] = []
    
    init(user: User) {
        self.user = user
        self.tempBio = user.description
        
        // Inicializar juegos y rangos desde el usuario
        for (gameName, rank) in user.games {
            if let gameIndex = Game.allGames.firstIndex(where: { $0.name == gameName }) {
                var game = Game.allGames[gameIndex]
                game.selectedRank = rank
                selectedGames.append(game)
            }
        }
    }
    
    func updateProfile() {
        user.description = tempBio
        
        // Actualizar juegos y rangos
        var updatedGames: [(String, String)] = []
        for game in selectedGames {
            if let rank = game.selectedRank {
                updatedGames.append((game.name, rank))
            }
        }
        user.games = updatedGames
        
        // Aquí se guardarían los cambios en la base de datos
        isEditingProfile = false
    }
    
    func addGame(_ game: Game) {
        if !selectedGames.contains(where: { $0.name == game.name }) {
            var newGame = game
            newGame.selectedRank = game.ranks.first
            selectedGames.append(newGame)
        }
    }
    
    func updateGameRank(for gameName: String, rank: String) {
        if let index = selectedGames.firstIndex(where: { $0.name == gameName }) {
            selectedGames[index].selectedRank = rank
        }
    }
    
    func removeGame(at index: Int) {
        if index >= 0 && index < selectedGames.count {
            selectedGames.remove(at: index)
        }
    }
    
    func removeGame(named gameName: String) {
        selectedGames.removeAll(where: { $0.name == gameName })
    }
    
    func updateProfileImage(_ imageName: String) {
        user.profileImage = imageName
    }
} 