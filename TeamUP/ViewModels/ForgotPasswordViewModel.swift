import Foundation

class ForgotPasswordViewModel: ObservableObject {
    @Published var errorMessage = ""
    @Published var showSuccess = false
    
    func resetPassword(identifier: String, newPassword: String) {
        // Validación básica
        if identifier.isEmpty || newPassword.isEmpty {
            errorMessage = "Por favor, complete todos los campos"
            return
        }
        
        let passwordData = [
            "Identificador": identifier,
            "NuevaContraseña": newPassword
        ]
        
        guard let url = URL(string: "http://localhost:3000/reset-password") else {
            errorMessage = "Error en la URL del servidor"
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: passwordData)
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
                       let errorMessage = json["error"] as? String {
                        self?.errorMessage = errorMessage
                    } else {
                        self?.errorMessage = "Error al cambiar la contraseña"
                    }
                }
            }
        }.resume()
    }
} 