import SwiftUI

class MyUserViewModel: ObservableObject {
    @Published var user: User
    
    init(user: User) {
        self.user = user
    }
    
    func updateProfile(name: String, age: Int, description: String) {
        user.name = name
        user.age = age
        user.description = description
        // Aquí podrías añadir lógica para guardar los cambios en un servidor o base de datos
    }
} 