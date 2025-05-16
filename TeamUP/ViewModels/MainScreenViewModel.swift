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
        
        guard let currentUser = authManager.currentUser else {
            users = []
            isLoading = false
            currentIndex = 0
            return
        }
        
        let currentUserGames = Set(currentUser.games.map { $0.0 })
        
        // Imágenes por defecto para usuarios reales
        let defaultImages = [
            "DwarfTestIcon",
            "ToadTestIcon",
            "TerroristTestIcon",
            "CatTestIcon"
        ]
        
        // Unir decoy y reales (sin duplicados y sin el usuario actual)
        var allUsers: [User] = defaultUsers
        do {
            let realUsers = try await mongoManager.getRegisteredUsers()
            let filteredRealUsers = realUsers.filter { realUser in
                realUser.name != currentUser.name && !defaultUsers.contains(where: { $0.name == realUser.name })
            }.map { user in
                // Si el usuario no tiene imagen, asigna una aleatoria
                if user.profileImage == "default_profile" || user.profileImage.isEmpty {
                    var newUser = user
                    newUser.profileImage = defaultImages.randomElement() ?? "DwarfTestIcon"
                    return newUser
                } else {
                    return user
                }
            }
            allUsers.append(contentsOf: filteredRealUsers)
        } catch {
            print("Error cargando usuarios reales: \(error)")
        }
        
        // Separar por juegos en común
        let withCommonGames = allUsers.filter { user in
            let userGames = Set(user.games.map { $0.0 })
            return !userGames.intersection(currentUserGames).isEmpty
        }
        let withoutCommonGames = allUsers.filter { user in
            let userGames = Set(user.games.map { $0.0 })
            return userGames.intersection(currentUserGames).isEmpty
        }
        
        users = withCommonGames + withoutCommonGames
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
