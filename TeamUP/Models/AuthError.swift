import Foundation

enum AuthError: LocalizedError {
    case invalidCredentials(message: String = "Credenciales inválidas")
    case emptyUsername
    case emptyPassword
    case weakPassword
    case invalidEmail
    case usernameTaken
    case emailTaken
    case passwordMismatch
    case networkError(Error)
    case unknown
    case notAuthenticated
    case registrationFailed(Error)
    case loginFailed(Error)
    case databaseError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials(let message):
            return message
        case .emptyUsername:
            return "Por favor, introduce un nombre de usuario"
        case .emptyPassword:
            return "Por favor, introduce una contraseña"
        case .weakPassword:
            return "La contraseña debe tener al menos 6 caracteres"
        case .invalidEmail:
            return "Por favor, introduce un email válido"
        case .usernameTaken:
            return "El nombre de usuario ya está en uso"
        case .emailTaken:
            return "El email ya está registrado"
        case .passwordMismatch:
            return "Las contraseñas no coinciden"
        case .networkError(let error):
            return "Error de red: \(error.localizedDescription)"
        case .unknown:
            return "Ha ocurrido un error inesperado"
        case .notAuthenticated:
            return "Usuario no autenticado"
        case .registrationFailed(let error):
            return "Error en el registro: \(error.localizedDescription)"
        case .loginFailed(let error):
            return "Error en el inicio de sesión: \(error.localizedDescription)"
        case .databaseError(let error):
            return "Error de base de datos: \(error.localizedDescription)"
        }
    }
}