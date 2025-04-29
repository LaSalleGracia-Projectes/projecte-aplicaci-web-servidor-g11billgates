import Foundation
import SwiftUI
import Combine

// MARK: - Models
struct ChatPreview: Codable, Identifiable {
    let id: String
    let username: String
    let lastMessage: String
    let timestamp: String
    let profileImage: String
    let participants: [String]
    let isHidden: Bool
}

// MARK: - ViewModel
@MainActor
class ChatListViewModel: ObservableObject {
    @Published var chats: [ChatPreview] = []
    @Published var isLoading = false
    @Published var error: String?
    let currentUserId: String
    private var users: [User] = []
    
    private let baseURL = "http://localhost:3000"
    private var cancellables = Set<AnyCancellable>()
    
    init(currentUserId: String) {
        self.currentUserId = currentUserId
        loadChats(for: currentUserId)
        loadUsers()
        loadExampleChats()
        
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
    
    func loadChats(for userId: String) {
        isLoading = true
        error = nil
        
        guard let url = URL(string: "\(baseURL)/api/users/\(userId)/chats") else {
            error = "URL inválida"
            isLoading = false
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.error = error.localizedDescription
                    return
                }
                
                guard let data = data else {
                    self?.error = "No se recibieron datos"
                    return
                }
                
                do {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    let chatPreviews = try decoder.decode([ChatPreview].self, from: data)
                    self?.chats = chatPreviews
                } catch {
                    self?.error = "Error al decodificar los chats: \(error.localizedDescription)"
                }
            }
        }
        task.resume()
    }
    
    func refreshChats(for userId: String) {
        loadChats(for: userId)
    }
    
    private func loadUsers() {
        // Usuarios de ejemplo con IDs
        users = [
            User(id: "1", name: "Marc", age: 20, gender: "Masculino", description: "Me encanta jugar", games: [("League of Legends", "Oro")], profileImage: "https://api.dicebear.com/7.x/avataaars/svg?seed=Marc"),
            User(id: "2", name: "Roger", age: 21, gender: "Masculino", description: "Siempre disponible", games: [("Valorant", "Platino")], profileImage: "https://api.dicebear.com/7.x/avataaars/svg?seed=Roger"),
            User(id: "3", name: "Pau", age: 19, gender: "Masculino", description: "Jugador casual", games: [("CS:GO", "Plata")], profileImage: "https://api.dicebear.com/7.x/avataaars/svg?seed=Pau"),
            User(id: "4", name: "Jordi", age: 22, gender: "Masculino", description: "Pro player", games: [("Dota 2", "Diamante")], profileImage: "https://api.dicebear.com/7.x/avataaars/svg?seed=Jordi")
        ]
    }
    
    private func loadExampleChats() {
        // Chats de ejemplo
        let exampleChats = [
            ChatPreview(
                id: "1",
                username: "Marc",
                lastMessage: "¡Hola! ¿Quieres jugar una partida?",
                timestamp: "10:30",
                profileImage: "https://api.dicebear.com/7.x/avataaars/svg?seed=Marc",
                participants: ["1", currentUserId],
                isHidden: false
            ),
            ChatPreview(
                id: "2",
                username: "Roger",
                lastMessage: "¿A qué hora quedamos para jugar?",
                timestamp: "09:15",
                profileImage: "https://api.dicebear.com/7.x/avataaars/svg?seed=Roger",
                participants: ["2", currentUserId],
                isHidden: false
            ),
            ChatPreview(
                id: "3",
                username: "Pau",
                lastMessage: "¡Buena partida!",
                timestamp: "Ayer",
                profileImage: "https://api.dicebear.com/7.x/avataaars/svg?seed=Pau",
                participants: ["3", currentUserId],
                isHidden: false
            ),
            ChatPreview(
                id: "4",
                username: "Jordi",
                lastMessage: "¿Jugamos otra?",
                timestamp: "Lunes",
                profileImage: "https://api.dicebear.com/7.x/avataaars/svg?seed=Jordi",
                participants: ["4", currentUserId],
                isHidden: false
            )
        ]
        
        // Añadir los chats de ejemplo a la lista existente
        chats.append(contentsOf: exampleChats)
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
