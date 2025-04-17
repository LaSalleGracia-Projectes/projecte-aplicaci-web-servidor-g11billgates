import Foundation

struct User: Identifiable, Decodable {
    let id: String
    let name: String
    let age: Int
    let gender: String
    let description: String
    let games: [(String, String)]
    let profileImage: String
    let matchPercentage: Int
    let commonGames: [CommonGame]
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name
        case age
        case gender
        case description
        case games
        case profileImage
        case matchPercentage
        case commonGames
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        age = try container.decode(Int.self, forKey: .age)
        gender = try container.decode(String.self, forKey: .gender)
        description = try container.decode(String.self, forKey: .description)
        games = try container.decode([(String, String)].self, forKey: .games)
        profileImage = try container.decode(String.self, forKey: .profileImage)
        matchPercentage = try container.decodeIfPresent(Int.self, forKey: .matchPercentage) ?? 0
        commonGames = try container.decodeIfPresent([CommonGame].self, forKey: .commonGames) ?? []
    }
    
    init(id: String, name: String, age: Int, gender: String, description: String, games: [(String, String)], profileImage: String, matchPercentage: Int = 0, commonGames: [CommonGame] = []) {
        self.id = id
        self.name = name
        self.age = age
        self.gender = gender
        self.description = description
        self.games = games
        self.profileImage = profileImage
        self.matchPercentage = matchPercentage
        self.commonGames = commonGames
    }
}

struct CommonGame: Decodable {
    let name: String
    let userRank: String
    let otherUserRank: String
}

// Helper struct to decode MongoDB ObjectId
struct ObjectId: Decodable {
    let stringValue: String
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        stringValue = try container.decode(String.self)
    }
} 