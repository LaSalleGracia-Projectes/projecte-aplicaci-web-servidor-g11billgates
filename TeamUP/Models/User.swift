import Foundation

struct User: Identifiable, Decodable {
    let id: String
    var name: String
    var age: Int
    var gender: String
    var description: String
    var games: [(String, String)] // (nombre del juego, rango)
    var profileImage: String
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name
        case age
        case gender
        case description = "bio"
        case games = "interests"
        case profileImage
    }
    
    init(id: String = UUID().uuidString, name: String, age: Int, gender: String, description: String, games: [(String, String)], profileImage: String) {
        self.id = id
        self.name = name
        self.age = age
        self.gender = gender
        self.description = description
        self.games = games
        self.profileImage = profileImage
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        age = try container.decode(Int.self, forKey: .age)
        gender = try container.decode(String.self, forKey: .gender)
        description = try container.decode(String.self, forKey: .description)
        profileImage = try container.decode(String.self, forKey: .profileImage)
        
        // Decodificar los intereses como juegos
        let interests = try container.decode([String].self, forKey: .games)
        games = interests.map { ($0, "Sin rango") } // Asignamos "Sin rango" por defecto
    }
} 