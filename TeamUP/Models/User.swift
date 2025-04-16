import Foundation

struct User: Identifiable, Decodable {
    let id: String
    var name: String
    var age: Int
    var gender: String
    var description: String
    var games: [(String, String)] // (nombre del juego, rango)
    var profileImage: String
    var likes: [String] = []
    var matches: [String] = []
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name = "Nombre"
        case age = "Edad"
        case gender = "Genero"
        case description = "Descripcion"
        case games = "Juegos"
        case profileImage = "FotoPerfil"
        case likes
        case matches
    }
    
    init(id: String = UUID().uuidString, name: String, age: Int, gender: String, description: String, games: [(String, String)], profileImage: String, likes: [String] = [], matches: [String] = []) {
        self.id = id
        self.name = name
        self.age = age
        self.gender = gender
        self.description = description
        self.games = games
        self.profileImage = profileImage
        self.likes = likes
        self.matches = matches
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Handle ObjectId conversion
        if let objectId = try? container.decode(ObjectId.self, forKey: .id) {
            id = objectId.stringValue
        } else {
            id = try container.decode(String.self, forKey: .id)
        }
        
        name = try container.decode(String.self, forKey: .name)
        age = try container.decode(Int.self, forKey: .age)
        gender = try container.decode(String.self, forKey: .gender)
        description = try container.decode(String.self, forKey: .description)
        profileImage = try container.decode(String.self, forKey: .profileImage)
        likes = try container.decodeIfPresent([String].self, forKey: .likes) ?? []
        matches = try container.decodeIfPresent([String].self, forKey: .matches) ?? []
        
        // Decode games with their correct structure
        let gamesData = try container.decode([[String: String]].self, forKey: .games)
        games = gamesData.compactMap { gameDict -> (String, String)? in
            guard let nombre = gameDict["nombre"],
                  let rango = gameDict["rango"] else {
                return nil
            }
            return (nombre, rango)
        }
    }
}

// Helper struct to decode MongoDB ObjectId
struct ObjectId: Decodable {
    let stringValue: String
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        stringValue = try container.decode(String.self)
    }
} 