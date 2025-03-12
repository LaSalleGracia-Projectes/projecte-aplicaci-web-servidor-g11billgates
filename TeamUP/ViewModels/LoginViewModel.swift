import SwiftUI
import Foundation

class LoginViewModel: ObservableObject {
    @Published var errorMessage = ""
    @Published var showSuccess = false
    @Published var loginSuccess = false
    
    init() {
        // Asegurarse de que no hay datos de sesión al iniciar
        UserDefaults.standard.removeObject(forKey: "userToken")
        UserDefaults.standard.removeObject(forKey: "userData")
    }
    
    func login(identifier: String, password: String) {
        // Validación básica
        if identifier.isEmpty || password.isEmpty {
            errorMessage = "Por favor, complete todos los campos"
            return
        }
        
        // Preparar los datos para el servidor
        let loginData = [
            "Identificador": identifier,  // Puede ser email o nombre de usuario
            "Contraseña": password
        ]
        
        guard let url = URL(string: "http://localhost:3000/login") else {
            errorMessage = "Error en la URL del servidor"
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: loginData)
        } catch {
            errorMessage = "Error al preparar los datos"
            return
        }
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = "Error de conexión: \(error.localizedDescription)"
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    self?.errorMessage = "Error en la respuesta del servidor"
                    return
                }
                
                if httpResponse.statusCode == 200 {
                    if let data = data {
                        do {
                            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                            if let userData = json?["user"] as? [String: Any] {
                                // Guardar datos del usuario
                                UserDefaults.standard.set(userData, forKey: "userData")
                                self?.loginSuccess = true
                                self?.errorMessage = ""
                            }
                        } catch {
                            self?.errorMessage = "Error al procesar la respuesta"
                        }
                    }
                } else {
                    if let data = data,
                       let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let errorMessage = json["error"] as? String {
                        self?.errorMessage = errorMessage
                    } else {
                        self?.errorMessage = "Error en el inicio de sesión"
                    }
                }
            }
        }.resume()
    }
    
    func resetPassword(identifier: String) {
        if identifier.isEmpty {
            errorMessage = "Introduce tu email o nombre de usuario para recuperar la contraseña"
            return
        }
        
        // Aquí iría la lógica para enviar el email de recuperación
        // Por ahora solo mostramos un mensaje
        errorMessage = "Se ha enviado un email con las instrucciones de recuperación"
    }
} 