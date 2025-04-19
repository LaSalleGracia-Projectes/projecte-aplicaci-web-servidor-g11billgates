import Foundation

class ForgotPasswordViewModel: ObservableObject {
    @Published var errorMessage = ""
    @Published var showSuccess = false
    @Published var codeSent = false
    
    func sendVerificationCode(email: String) {
        if email.isEmpty {
            errorMessage = "Por favor, introduce tu email"
            return
        }
        
        let data = ["email": email]
        
        guard let url = URL(string: "http://localhost:3000/forgot-password") else {
            errorMessage = "Error en la URL del servidor"
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: data)
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
                    if let data = data,
                       let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let message = json["message"] as? String {
                        self?.errorMessage = message
                    } else {
                        self?.errorMessage = "Se ha enviado un código de verificación a tu email"
                    }
                    self?.codeSent = true
                } else {
                    if let data = data,
                       let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let errorMessage = json["message"] as? String {
                        self?.errorMessage = errorMessage
                    } else {
                        self?.errorMessage = "Error al enviar el código de verificación"
                    }
                }
            }
        }.resume()
    }
    
    func resetPassword(email: String, code: String, newPassword: String) {
        let data = [
            "email": email,
            "code": code,
            "newPassword": newPassword
        ]
        
        guard let url = URL(string: "http://localhost:3000/reset-password") else {
            errorMessage = "Error en la URL del servidor"
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: data)
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
                    self?.showSuccess = true
                    self?.errorMessage = ""
                } else {
                    if let data = data,
                       let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let errorMessage = json["message"] as? String {
                        self?.errorMessage = errorMessage
                    } else {
                        self?.errorMessage = "Error al cambiar la contraseña"
                    }
                }
            }
        }.resume()
    }
} 