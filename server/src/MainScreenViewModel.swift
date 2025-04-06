import Foundation

class MainScreenViewModel: ObservableObject {
    @Published var users: [User] = []
    @Published var isLoading: Bool = false
    private let defaultUsers: [User] = [] // Assuming defaultUsers is defined somewhere in the code

    func loadUsers() async {
        isLoading = true
        do {
            // Obtener el usuario actual
            if let currentUser = AuthViewModel.shared.currentUser {
                // Obtener usuarios compatibles
                let compatibleUsers = try await MongoDBManager.shared.getCompatibleUsers(
                    userId: currentUser.id
                )
                
                // Solo mostrar usuarios compatibles, no mostrar usuarios de prueba
                self.users = compatibleUsers
            } else {
                // Si no hay usuario actual, no mostrar nada
                self.users = []
            }
        } catch {
            print("Error loading users: \(error)")
            // En caso de error, no mostrar nada
            self.users = []
        }
        isLoading = false
    }
} 