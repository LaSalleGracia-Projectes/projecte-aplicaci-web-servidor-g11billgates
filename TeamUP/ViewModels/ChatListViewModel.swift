import SwiftUI
import Combine

class ChatListViewModel: ObservableObject {
    @Published var chats: [ChatPreview] = [
        ChatPreview(username: "Laura", lastMessage: "¿Jugamos una partida?", timestamp: "12:30", profileImage: "ToadTestIcon"),
        ChatPreview(username: "Marc", lastMessage: "Buen juego!", timestamp: "11:45", profileImage: "DogTestIcon"),
        ChatPreview(username: "Saten", lastMessage: "¿Mañana a las 5?", timestamp: "10:15", profileImage: "CatTestIcon"),
        ChatPreview(username: "Roger", lastMessage: "GG WP", timestamp: "Ayer", profileImage: "TerroristTestIcon")
    ]
    
    // Lista de usuarios para poder mostrar sus perfiles
    private var users: [User] = [
        User(name: "Laura", age: 25, gender: "Mujer", description: "Main support, looking for ADC", games: [("League of Legends", "Diamante"), ("World of Warcraft", "2100+")], profileImage: "ToadTestIcon"),
        User(name: "Marc", age: 20, gender: "Hombre", description: "Mejor player del wow españa", games: [("WoW", "2900"), ("CS2", "Águila")], profileImage: "DogTestIcon"),
        User(name: "Saten", age: 24, gender: "Mujer", description: "Hola me llamo Saten soy maja", games: [("Valorant", "Inmortal"), ("CS2", "Águila")], profileImage: "CatTestIcon"),
        User(name: "Roger", age: 28, gender: "Hombre", description: "Jugador competitivo buscando team", games: [("Valorant", "Inmortal"), ("CS2", "Águila")], profileImage: "TerroristTestIcon")
    ]
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Suscribirse a notificaciones de nuevos chats
        NotificationCenter.default.publisher(for: NSNotification.Name("NewChatAdded"))
            .sink { [weak self] notification in
                if let chat = notification.userInfo?["chat"] as? ChatPreview {
                    DispatchQueue.main.async {
                        // Añadir el nuevo chat al principio de la lista
                        self?.chats.insert(chat, at: 0)
                        
                        // Si el usuario no existe en la lista, lo añadimos
                        if let matchedUser = notification.userInfo?["user"] as? User {
                            self?.addUserIfNeeded(matchedUser)
                        }
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    func findUser(withName name: String) -> User? {
        return users.first { $0.name == name }
    }
    
    private func addUserIfNeeded(_ user: User) {
        if !users.contains(where: { $0.name == user.name }) {
            users.append(user)
        }
    }
} 