import SwiftUI

class MainScreenViewModel: ObservableObject {
    @Published var currentIndex = 0
    @Published var users: [User] = []
    @Published var showMatch = false
    @Published var matchedUser: User?
    @Published var isLoading = true
    
    private let mongoManager = MongoDBManager.shared
    private let authManager = AuthenticationManager.shared
    
    // Usuarios de prueba por defecto
    private let defaultUsers = [
        User(
            name: "Alex",
            age: 23,
            gender: "Hombre",
            description: "Buscando equipo para rankeds",
            games: [
                ("League of Legends", "Platino"),
                ("Valorant", "Oro")
            ],
            profileImage: "DwarfTestIcon"
        ),
        User(
            name: "Laura",
            age: 25,
            gender: "Mujer",
            description: "Main support, looking for ADC",
            games: [
                ("League of Legends", "Diamante"),
                ("World of Warcraft", "2100+")
            ],
            profileImage: "ToadTestIcon"
        ),
        User(
            name: "Roger",
            age: 28,
            gender: "Hombre",
            description: "Jugador competitivo buscando team",
            games: [
                ("Valorant", "Inmortal"),
                ("CS2", "Águila")
            ],
            profileImage: "TerroristTestIcon"
        ),
        User(
            name: "Saten",
            age: 24,
            gender: "Mujer",
            description: "Hola me llamo Saten soy maja",
            games: [
                ("Valorant", "Inmortal"),
                ("CS2", "Águila")
            ],
            profileImage: "CatTestIcon"
        ),
        User(
            name: "Marc",
            age: 20,
            gender: "Hombre",
            description: "Mejor player del wow españa",
            games: [
                ("WoW", "2900"),
                ("CS2", "Águila")
            ],
            profileImage: "DogTestIcon"
        )
    ]
    
    init() {
        Task {
            await loadUsers()
        }
    }
    
    @MainActor
    func loadUsers() async {
        isLoading = true
        
        do {
            // Get current user
            guard let currentUser = authManager.currentUser else {
                users = []
                isLoading = false
                return
            }
            
            // Get matching users
            let matchingUsers = try await mongoManager.getMatchingUsers(userId: currentUser.id)
            
            // Update UI with matching users
            users = matchingUsers
            isLoading = false
            
        } catch {
            print("Error loading users: \(error)")
            users = []
            isLoading = false
        }
    }
    
    func likeUser() {
        guard currentIndex < users.count else { return }
        let likedUser = users[currentIndex]
        currentIndex += 1
        
        // Aquí podrías implementar la lógica de match
        // Por ahora solo avanzamos al siguiente usuario
    }
    
    func dislikeUser() {
        guard currentIndex < users.count else { return }
        currentIndex += 1
    }
    
    // Esta función se usará cuando implementemos la base de datos
    private func saveMatch(with user: User) {
        // TODO: Implementar la lógica para guardar el match en la base de datos
        // Por ejemplo:
        // DatabaseManager.shared.saveMatch(currentUser: currentUser, matchedUser: user)
    }
}
