import SwiftUI

class MatchViewModel: ObservableObject {
    @Published var showMatch = false
    @Published var matchedUser: User?
    @Published var errorMessage = ""
    
    func likeUser(userId: Int) {
        guard let token = UserDefaults.standard.string(forKey: "userToken") else {
            errorMessage = "No estás autenticado"
            return
        }
        
        guard let url = URL(string: "http://localhost:3000/api/matches/like") else {
            errorMessage = "Error en la URL del servidor"
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let likeData = ["likedUserId": userId]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: likeData)
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
                       let success = json["success"] as? Bool,
                       success {
                        // Aquí podrías obtener los datos del usuario con el que se hizo match
                        // y actualizar matchedUser
                        self?.showMatch = true
                    } else {
                        self?.errorMessage = "Error al procesar la respuesta"
                    }
                } else {
                    if let data = data,
                       let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let error = json["error"] as? String {
                        self?.errorMessage = error
                    } else {
                        self?.errorMessage = "Error en el like"
                    }
                }
            }
        }.resume()
    }
} 