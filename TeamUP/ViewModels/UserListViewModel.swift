import Foundation

class UserListViewModel: ObservableObject {
    @Published var users: [User] = []
    
    func loadUsers() {
        guard let url = URL(string: "http://localhost:3000/api/users") else {
            print("Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Aquí deberías añadir el token de autenticación
        // request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let data = data, error == nil else {
                print("Error: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            do {
                let users = try JSONDecoder().decode([User].self, from: data)
                DispatchQueue.main.async {
                    self?.users = users
                }
            } catch {
                print("Error decoding users: \(error)")
            }
        }.resume()
    }
} 
