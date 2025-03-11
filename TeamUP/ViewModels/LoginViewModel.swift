import SwiftUI

class LoginViewModel: ObservableObject {
    @Published var username = ""
    @Published var password = ""
    @Published var showError = false
    @Published var errorMessage = ""
    
    // Credenciales de prueba
    private let testUsername = "user"
    private let testPassword = "1234"
    
    func login() -> Bool {
        // Validaciones básicas
        guard !username.isEmpty else {
            showError = true
            errorMessage = "Por favor, introduce un nombre de usuario"
            return false
        }
        
        guard !password.isEmpty else {
            showError = true
            errorMessage = "Por favor, introduce una contraseña"
            return false
        }
        
        // Validación con credenciales de prueba
        if username == testUsername && password == testPassword {
            showError = false
            return true
        } else {
            showError = true
            errorMessage = "Usuario o contraseña incorrectos"
            return false
        }
    }
    
    func resetPassword() {
        if username.isEmpty {
            showError = true
            errorMessage = "Introduce tu nombre de usuario para recuperar la contraseña"
        } else {
            showError = true
            errorMessage = "Se ha enviado un email con las instrucciones"
        }
    }
} 