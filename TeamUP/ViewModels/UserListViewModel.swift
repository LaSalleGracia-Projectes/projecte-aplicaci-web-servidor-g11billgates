import SwiftUI

class UserListViewModel: ObservableObject {
    @Published var users: [User] = [
        User(name: "Ana", age: 23, gender: "Mujer", description: "¡Hola! Me encanta jugar League of Legends y Valorant. Busco equipo para rankeds.", games: [("League of Legends", "Platino"), ("Valorant", "Oro")], profileImage: "profile1"),
        User(name: "Carlos", age: 28, gender: "Hombre", description: "Jugador de World of Warcraft desde vanilla. Main tank, experiencia en raids míticas.", games: [("World of Warcraft", "Mítico")], profileImage: "profile2"),
        User(name: "Elena", age: 25, gender: "Mujer", description: "Jugadora casual de varios juegos. Me gusta hacer nuevos amigos y divertirme.", games: [("Overwatch", "Platino"), ("Apex Legends", "Diamante")], profileImage: "profile3")
    ]
} 
