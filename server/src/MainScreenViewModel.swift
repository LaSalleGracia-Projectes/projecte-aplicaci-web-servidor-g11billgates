import Foundation

class MainScreenViewModel: ObservableObject {
    @Published var users: [User] = []
    @Published var isLoading: Bool = false
    private let defaultUsers: [User] = [] // Assuming defaultUsers is defined somewhere in the code

    func loadUsers() async {
        isLoading = true
        do {
            // Obtener el usuario actual y su juego seleccionado
            if let currentUser = AuthViewModel.shared.currentUser,
               let selectedGame = currentUser.juegos.first {
                // Obtener usuarios compatibles
                let compatibleUsers = try await MongoDBManager.shared.getCompatibleUsers(
                    userId: currentUser.id,
                    juegoId: selectedGame.juegoId
                )
                
                // Si hay usuarios compatibles, mostrarlos junto con los usuarios de prueba
                if !compatibleUsers.isEmpty {
                    self.users = compatibleUsers + defaultUsers
                } else {
                    // Si no hay usuarios compatibles, mostrar solo los usuarios de prueba
                    self.users = defaultUsers
                }
            } else {
                // Si no hay usuario actual o juego seleccionado, mostrar solo usuarios de prueba
                self.users = defaultUsers
            }
        } catch {
            print("Error loading users: \(error)")
            // En caso de error, mostrar usuarios de prueba
            self.users = defaultUsers
        }
        isLoading = false
    }
} 