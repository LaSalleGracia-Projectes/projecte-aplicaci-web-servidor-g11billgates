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
        errorMessage = nil
        
        // Obtener los juegos del usuario actual
        guard let currentUser = authManager.currentUser else {
            users = []
            isLoading = false
            currentIndex = 0
            return
        }
        
        let currentUserGames = Set(currentUser.games.map { $0.0 })
        
        // Usuarios de decoy filtrados por juegos en común
        let filteredDecoy = defaultUsers.filter { user in
            let userGames = Set(user.games.map { $0.0 })
            return !userGames.intersection(currentUserGames).isEmpty
        }
        
        // Añadir usuarios reales de la base de datos
        var filteredRealUsers: [User] = []
        do {
            let realUsers = try await mongoManager.getRegisteredUsers()
            // Evitar duplicados por nombre y no mostrar al usuario actual
            filteredRealUsers = realUsers.filter { realUser in
                realUser.name != currentUser.name && !filteredDecoy.contains(where: { $0.name == realUser.name })
            }
        } catch {
            print("Error cargando usuarios reales: \(error)")
            // Si falla, solo muestra los decoy
        }
        
        users = filteredDecoy + filteredRealUsers
        currentIndex = 0
        isLoading = false
    }
    
    @MainActor
    func likeUser() async {
        guard currentIndex < users.count else { return }
        let likedUser = users[currentIndex]
        showMatch = true
        matchedUser = likedUser
        // Eliminar la tarjeta actual
        users.remove(at: currentIndex)
        // No incrementes currentIndex
        
        // Crear un nuevo chat automáticamente
        let newChat = ChatPreview(
            id: UUID().uuidString,
            username: likedUser.name,
            lastMessage: "¡Hola! ¡Tenemos un match!",
            timestamp: "Ahora",
            profileImage: likedUser.profileImage,
            participants: [currentUserId, likedUser.id],
            isHidden: false
        )
        
        // Notificar que se ha creado un nuevo chat
        NotificationCenter.default.post(
            name: NSNotification.Name("NewChatAdded"),
            object: nil,
            userInfo: ["chat": newChat, "user": likedUser]
        )
    }
    
    @MainActor
    func dislikeUser() async {
        guard currentIndex < users.count else { return }
        // Eliminar la tarjeta actual
        users.remove(at: currentIndex)
        // No incrementes currentIndex
    }
    
    func resetIndex() {
        currentIndex = 0
    }
    
    // Esta función se usará cuando implementemos la base de datos
    private func saveMatch(with user: User) {
        // TODO: Implementar la lógica para guardar el match en la base de datos
        // Por ejemplo:
        // DatabaseManager.shared.saveMatch(currentUser: currentUser, matchedUser: user)
    }
}
