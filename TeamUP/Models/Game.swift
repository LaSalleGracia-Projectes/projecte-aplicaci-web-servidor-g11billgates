import Foundation

struct Game: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let ranks: [String]
    var selectedRank: String?
    
    static let allGames: [Game] = [
        Game(
            name: "Counter Strike",
            ranks: ["Silver", "Gold Nova", "Master Guardian", "DMG", "LE", "LEM", "Supreme", "Global Elite"]
        ),
        Game(
            name: "League of Legends",
            ranks: ["Hierro", "Bronce", "Plata", "Oro", "Platino", "Diamante", "Master", "Grand Master", "Challenger"]
        ),
        Game(
            name: "World of Warcraft",
            ranks: ["1400+", "1600+", "1800+", "2000+", "2200+", "2400+", "2600+"]
        ),
        Game(
            name: "Valorant",
            ranks: ["Hierro", "Bronce", "Plata", "Oro", "Platino", "Diamante", "Ascendente", "Inmortal", "Radiante"]
        ),
        Game(
            name: "Dota 2",
            ranks: ["Heraldo", "Guardián", "Cruzado", "Arconte", "Leyenda", "Ancestral", "Divino", "Inmortal"]
        )
    ]
    
    // Inicializador
    init(name: String, ranks: [String], selectedRank: String? = nil) {
        self.name = name
        self.ranks = ranks
        self.selectedRank = selectedRank
    }
    
    // Implementación de Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Game, rhs: Game) -> Bool {
        lhs.id == rhs.id
    }
} 