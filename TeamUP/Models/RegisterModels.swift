enum Gender: String {
    case male = "male"
    case female = "female"
}

enum SearchPreference: String {
    case all = "all"
    case male = "male"
    case female = "female"
}

struct GameRank {
    let game: Game
    let rank: String
} 