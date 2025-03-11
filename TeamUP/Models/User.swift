import Foundation

struct User: Identifiable {
    let id = UUID()
    var name: String
    var age: Int
    var gender: String
    var description: String
    var games: [(String, String)] // (nombre del juego, rango)
    var profileImage: String
} 