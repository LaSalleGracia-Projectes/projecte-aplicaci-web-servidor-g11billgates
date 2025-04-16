import Foundation
import SwiftUI
import Combine

@MainActor
class ChatListViewModel: ObservableObject {
    @Published var chats: [ChatPreview] = []
    let currentUserId: String
    private var users: [User] = []
    
    init(currentUserId: String) {
        self.currentUserId = currentUserId
        loadChats()
        loadUsers()
        
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
    
    private func loadChats() {
        // TODO: Implementar carga de chats desde el servidor
        // Por ahora usamos datos de ejemplo
        chats = [
            ChatPreview(
                id: "1",
                username: "Marc",
                lastMessage: "¡Hola! ¿Quieres jugar?",
                timestamp: "10:30",
                profileImage: "https://example.com/profile1.jpg",
                participants: ["1", currentUserId],
                isHidden: false
            ),
            ChatPreview(
                id: "2",
                username: "Roger",
                lastMessage: "¿A qué hora quedamos?",
                timestamp: "09:15",
                profileImage: "https://example.com/profile2.jpg",
                participants: ["2", currentUserId],
                isHidden: false
            ),
            ChatPreview(
                id: "3",
                username: "Pau",
                lastMessage: "¡Buena partida!",
                timestamp: "Ayer",
                profileImage: "https://example.com/profile3.jpg",
                participants: ["3", currentUserId],
                isHidden: false
            ),
            ChatPreview(
                id: "4",
                username: "Jordi",
                lastMessage: "¿Jugamos otra?",
                timestamp: "Lunes",
                profileImage: "https://example.com/profile4.jpg",
                participants: ["4", currentUserId],
                isHidden: false
            )
        ].filter { !$0.isHidden }
    }
    
    private func loadUsers() {
        // TODO: Implementar carga de usuarios desde el servidor
        // Por ahora usamos datos de ejemplo
        users = [
            User(name: "Marc", age: 20, gender: "Masculino", description: "Me encanta jugar", games: [("League of Legends", "Oro")], profileImage: "https://example.com/profile1.jpg"),
            User(name: "Roger", age: 21, gender: "Masculino", description: "Siempre disponible", games: [("Valorant", "Platino")], profileImage: "https://example.com/profile2.jpg"),
            User(name: "Pau", age: 19, gender: "Masculino", description: "Jugador casual", games: [("CS:GO", "Plata")], profileImage: "https://example.com/profile3.jpg"),
            User(name: "Jordi", age: 22, gender: "Masculino", description: "Pro player", games: [("Dota 2", "Diamante")], profileImage: "https://example.com/profile4.jpg")
        ]
    }
    
    func findUser(withName name: String) -> User? {
        return users.first { $0.name == name }
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    private func addUserIfNeeded(_ user: User) {
        if !users.contains(where: { $0.name == user.name }) {
            users.append(user)
        }
    }
} 
