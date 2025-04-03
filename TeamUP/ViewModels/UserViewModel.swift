import SwiftUI
import Foundation

class UserViewModel: ObservableObject {
    @Published var user: User
    @Published var isEditingProfile = false
    @Published var tempBio: String = ""
    @Published var selectedGames: [Game] = []
    @Published var isLoggedIn: Bool = true
    @Published var users: [User] = []
    
    init(user: User) {
        self.user = user
        self.tempBio = user.description
        
        // Convertir los juegos del usuario a objetos Game
        self.selectedGames = user.games.compactMap { gameTuple in
            if let gameIndex = Game.allGames.firstIndex(where: { $0.name == gameTuple.0 }) {
                var game = Game.allGames[gameIndex]
                game.selectedRank = gameTuple.1
                return game
            }
            return nil
        }
    }
    
    func updateProfile() {
        user.description = tempBio
        
        // Convertir los objetos Game a tuplas (String, String)
        let updatedGames = selectedGames.compactMap { game -> (String, String)? in
            if let rank = game.selectedRank {
                return (game.name, rank)
            }
            return nil
        }
        user.games = updatedGames
        
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
    
    func saveChanges(name: String, age: Int, gender: String) {
        user.name = name
        user.age = age
        user.gender = gender
        user.description = tempBio
        
        // Convertir los objetos Game a tuplas (String, String)
        let updatedGames = selectedGames.compactMap { game -> (String, String)? in
            if let rank = game.selectedRank {
                return (game.name, rank)
            }
            return nil
        }
        user.games = updatedGames
        
        isEditingProfile = false
    }
    
    func cancelEditing() {
        tempBio = user.description
        // Convertir los juegos del usuario a objetos Game
        self.selectedGames = user.games.compactMap { gameTuple in
            if let gameIndex = Game.allGames.firstIndex(where: { $0.name == gameTuple.0 }) {
                var game = Game.allGames[gameIndex]
                game.selectedRank = gameTuple.1
                return game
            }
            return nil
        }
        isEditingProfile = false
    }
    
    func logout() {
        // Limpiar los datos del usuario
        UserDefaults.standard.removeObject(forKey: "userToken")
        UserDefaults.standard.removeObject(forKey: "userData")
        isLoggedIn = false
    }
    
    func loadUsers() {
        guard let url = URL(string: "http://localhost:3000/api/users") else {
            print("Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Aquí deberías añadir el token de autenticación
        // request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let data = data, error == nil else {
                print("Error: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            do {
                let users = try JSONDecoder().decode([User].self, from: data)
                DispatchQueue.main.async {
                    self?.users = users
                }
            } catch {
                print("Error decoding users: \(error)")
            }
        }.resume()
    }
} 