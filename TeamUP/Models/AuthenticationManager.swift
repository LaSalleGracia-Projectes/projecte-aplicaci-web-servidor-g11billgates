import SwiftUI

final class AuthenticationManager: ObservableObject {
    static let shared: AuthenticationManager = {
        let instance = AuthenticationManager()
        return instance
    }()
    
    @Published var isAuthenticated: Bool = false
    @Published var currentUser: User?
    private let mongoManager = MongoDBManager.shared
    
    private init() {}
    
    func register(user: User, email: String, password: String) async throws {
        do {
            try await mongoManager.registerUser(user: user, email: email, password: password)
            await MainActor.run {
                self.currentUser = user
                self.isAuthenticated = true
            }
        } catch {
            throw AuthError.registrationFailed(error)
        }
    }
    
    func login(email: String, password: String) async throws {
        do {
            let user = try await mongoManager.loginUser(email: email, password: password)
            await MainActor.run {
                self.currentUser = user
                self.isAuthenticated = true
            }
        } catch let error as MongoDBError {
            switch error {
            case .loginFailed(let message):
                throw AuthError.invalidCredentials(message: message)
            default:
                throw AuthError.loginFailed(error)
            }
        } catch {
            throw AuthError.loginFailed(error)
        }
    }
    
    func logout() {
        isAuthenticated = false
        currentUser = nil
    }
    
    func addGame(game: Game, rank: String) async throws {
        guard let user = currentUser else {
            throw AuthError.notAuthenticated
        }
        
        try await mongoManager.addUserGame(userId: user.id.uuidString, game: game, rank: rank)
        
        await MainActor.run {
            // Update local user data
            var updatedGames = user.games
            updatedGames.append((game.name, rank))
            currentUser?.games = updatedGames
        }
    }
}
