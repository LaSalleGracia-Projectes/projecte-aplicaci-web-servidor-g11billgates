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
        // Primero verificamos el código para obtener el token
        let verifyData = [
            "email": email,
            "code": code
        ]
        
        guard let verifyUrl = URL(string: "http://localhost:3000/verify-code") else {
            errorMessage = "Error en la URL del servidor"
            return
        }
        
        var verifyRequest = URLRequest(url: verifyUrl)
        verifyRequest.httpMethod = "POST"
        verifyRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            verifyRequest.httpBody = try JSONSerialization.data(withJSONObject: verifyData)
        } catch {
            errorMessage = "Error al preparar los datos"
            return
        }
        
        URLSession.shared.dataTask(with: verifyRequest) { [weak self] data, response, error in
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
                       let resetToken = json["resetToken"] as? String {
                        // Si la verificación es exitosa, procedemos a resetear la contraseña
                        self?.resetPasswordWithToken(token: resetToken, newPassword: newPassword)
                    } else {
                        self?.errorMessage = "Error al obtener el token de reset"
                    }
                } else {
                    if let data = data,
                       let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let errorMessage = json["message"] as? String {
                        self?.errorMessage = errorMessage
                    } else {
                        self?.errorMessage = "Error al verificar el código"
                    }
                }
            }
        }.resume()
    }
    
    private func resetPasswordWithToken(token: String, newPassword: String) {
        let resetData = [
            "token": token,
            "newPassword": newPassword
        ]
        
        guard let resetUrl = URL(string: "http://localhost:3000/reset-password") else {
            errorMessage = "Error en la URL del servidor"
            return
        }
        
        var resetRequest = URLRequest(url: resetUrl)
        resetRequest.httpMethod = "POST"
        resetRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            resetRequest.httpBody = try JSONSerialization.data(withJSONObject: resetData)
        } catch {
            errorMessage = "Error al preparar los datos"
            return
        }
        
        URLSession.shared.dataTask(with: resetRequest) { [weak self] data, response, error in
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