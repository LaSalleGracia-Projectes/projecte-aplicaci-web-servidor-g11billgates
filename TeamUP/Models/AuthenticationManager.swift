import Foundation
import SwiftUI

class AuthenticationManager: ObservableObject {
    static let shared = AuthenticationManager()
    
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var errorMessage: String?
    
    private let mongoManager = MongoDBManager.shared
    
    private init() {}
    
    func login(email: String, password: String) async throws {
        do {
            let user = try await mongoManager.loginUser(email: email, password: password)
            await MainActor.run {
                self.currentUser = user
                self.isAuthenticated = true
                self.errorMessage = nil
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isAuthenticated = false
            }
            throw error
        }
    }
    
    func logout() {
        currentUser = nil
        isAuthenticated = false
        errorMessage = nil
    }
    
    func register(user: User, email: String, password: String) async throws {
        do {
            try await mongoManager.registerUser(user: user, email: email, password: password)
            await MainActor.run {
                self.currentUser = user
                self.isAuthenticated = true
                self.errorMessage = nil
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isAuthenticated = false
            }
            throw error
        }
    }
    
    func updateUserProfile(name: String, age: Int, gender: String, description: String, games: [Game]) async throws {
        guard let currentUser = currentUser else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user logged in"])
        }
        
        let updatedUser = User(
            id: currentUser.id,
            name: name,
            age: age,
            gender: gender,
            description: description,
            games: games,
            profileImage: currentUser.profileImage
        )
        
        do {
            try await mongoManager.updateUser(user: updatedUser)
            await MainActor.run {
                self.currentUser = updatedUser
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
            throw error
        }
    }
    
    func addGame(game: Game, rank: String) async throws {
        guard let user = currentUser else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user logged in"])
        }
        
        try await mongoManager.addUserGame(userId: user.id, game: game, rank: rank)
        
        await MainActor.run {
            // Create a new user with updated games
            let updatedUser = User(
                id: user.id,
                name: user.name,
                age: user.age,
                gender: user.gender,
                description: user.description,
                games: user.games + [Game(nombre: game.nombre, rango: rank)],
                profileImage: user.profileImage
            )
            self.currentUser = updatedUser
        }
    }
}
