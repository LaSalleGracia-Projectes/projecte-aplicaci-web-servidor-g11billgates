import SwiftUI

class RegisterViewModel: ObservableObject {
    @Published var email = ""
    @Published var username = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var selectedGames: Set<Game> = []
    @Published var gender: Gender = .male
    @Published var age: Int = 18
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
        // Validar edad
        guard age >= 18 else {
            showError = true
            errorMessage = "Debes ser mayor de 18 años para registrarte"
            return false
        }
        
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
        
        // Validar edad nuevamente por seguridad
        guard age >= 18 else {
            showError = true
            errorMessage = "Debes ser mayor de 18 años para registrarte"
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
            
            // Subir la imagen de perfil si existe
            var profileImageUrl = "default_profile"
            if let image = profileImage {
                let boundary = UUID().uuidString
                var request = URLRequest(url: URL(string: "http://localhost:3000/upload-profile-image")!)
                request.httpMethod = "POST"
                request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
                
                var bodyData = Data()
                
                // Añadir archivo
                bodyData.append("--\(boundary)\r\n".data(using: .utf8)!)
                bodyData.append("Content-Disposition: form-data; name=\"profileImage\"; filename=\"profile.jpg\"\r\n".data(using: .utf8)!)
                bodyData.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
                bodyData.append(image.jpegData(compressionQuality: 0.8)!)
                bodyData.append("\r\n".data(using: .utf8)!)
                
                bodyData.append("--\(boundary)--\r\n".data(using: .utf8)!)
                request.httpBody = bodyData
                
                let (data, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    throw NSError(domain: "RegisterViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "Error al subir la imagen"])
                }
                
                let decoder = JSONDecoder()
                let result = try decoder.decode(ProfileImageResponse.self, from: data)
                profileImageUrl = result.imageUrl
            }
            
            // Crear una descripción inicial basada en los juegos seleccionados
            let gameNames = selectedGames.map { $0.name }.joined(separator: ", ")
            let initialDescription = "¡Hola! Me encanta jugar \(gameNames). ¡Busquemos equipo juntos!"
            
            // Create the user with the selected games
            let newUser = User(
                name: username,
                age: age,
                gender: gender.rawValue,
                description: initialDescription,
                games: games.map { ($0["nombre"] ?? "", $0["rango"] ?? "Principiante") },
                profileImage: profileImageUrl
            )
            
            // Register user in MongoDB
            try await authManager.register(user: newUser, email: email, password: password)
            
            // Actualizar el usuario actual en el AuthenticationManager
            await MainActor.run {
                authManager.currentUser = newUser
            }
            
            print("Usuario registrado exitosamente en MongoDB")
            isRegistering = false
            
        } catch {
            showError = true
            errorMessage = "Error al registrar el usuario. Por favor, intenta de nuevo."
            isRegistering = false
        }
    }
}

struct ProfileImageResponse: Decodable {
    let imageUrl: String
    
    enum CodingKeys: String, CodingKey {
        case imageUrl = "imageUrl"
    }
} 