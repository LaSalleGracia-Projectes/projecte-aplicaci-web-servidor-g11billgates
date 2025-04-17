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
        // Validar que se hayan seleccionado juegos
        guard !selectedGames.isEmpty else {
            showError = true
            errorMessage = "Debes seleccionar al menos un juego"
            return
        }
        
        isRegistering = true
        showError = false
        
        do {
            // Convertir los juegos seleccionados al formato correcto
            let games = selectedGames.map { game -> [String: String] in
                [
                    "nombre": game.name,
                    "rango": game.selectedRank ?? "Principiante"
                ]
            }
            
            // Create the user with the selected games
            let newUser = User(
                name: username,
                age: 0,
                gender: gender.rawValue,
                description: "",
                games: games.map { ($0["nombre"] ?? "", $0["rango"] ?? "Principiante") },
                profileImage: "default_profile"
            )
            
            // Register user in MongoDB
            try await authManager.register(user: newUser, email: email, password: password)
            
            print("Usuario registrado exitosamente en MongoDB")
            isRegistering = false
            
        } catch {
            showError = true
            errorMessage = "Error al registrar el usuario. Por favor, intenta de nuevo."
            isRegistering = false
        }
    }
} 