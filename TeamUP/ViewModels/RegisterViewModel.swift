import SwiftUI

class RegisterViewModel: ObservableObject {
    @Published var email = ""
    @Published var username = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var selectedGames: Set<Game> = []
    @Published var gender: Gender = .male
    @Published var filterByRank = false
    @Published var searchPreference: SearchPreference = .all
    @Published var profileImage: UIImage?
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var showImagePicker = false
    @Published var isRegistering = false
    
    private let mongoManager = MongoDBManager.shared
    private let authManager = AuthenticationManager.shared
    
    func validateFirstStep() -> Bool {
        // Validar email
        guard email.contains("@") else {
            showError = true
            errorMessage = "Por favor, introduce un email válido"
            return false
        }
        
        // Validar usuario
        guard username.count >= 3 else {
            showError = true
            errorMessage = "El usuario debe tener al menos 3 caracteres"
            return false
        }
        
        // Validar contraseña
        guard password.count >= 6 else {
            showError = true
            errorMessage = "La contraseña debe tener al menos 6 caracteres"
            return false
        }
        
        // Validar confirmación de contraseña
        guard password == confirmPassword else {
            showError = true
            errorMessage = "Las contraseñas no coinciden"
            return false
        }
        
        return true
    }
    
    @MainActor
    func register() async {
        guard !selectedGames.isEmpty else {
            showError = true
            errorMessage = "Debes seleccionar al menos un juego"
            return
        }
        
        isRegistering = true
        showError = false
        
        do {
            // Create the user
            let newUser = User(
                name: username,
                age: 0, // You might want to add age field in your registration form
                gender: gender.rawValue,
                description: "",
                games: [],
                profileImage: "default_profile" // Handle profile image upload separately
            )
            
            // Register user in MongoDB
            try await authManager.register(user: newUser, email: email, password: password)
            
            // Add selected games for the user
            for game in selectedGames {
                try await authManager.addGame(game: game, rank: "Beginner")
            }
            
            print("Usuario registrado exitosamente en MongoDB")
            isRegistering = false
            
        } catch let error as MongoDBError {
            showError = true
            errorMessage = error.localizedDescription
            isRegistering = false
            
        } catch let error as AuthError {
            showError = true
            errorMessage = error.localizedDescription
            isRegistering = false
            
        } catch {
            showError = true
            errorMessage = "Error inesperado durante el registro"
            isRegistering = false
        }
    }
} 