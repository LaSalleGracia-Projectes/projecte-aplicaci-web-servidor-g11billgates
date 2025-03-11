import SwiftUI

struct AppSettings {
    var colorScheme: ColorScheme?
    var filterByRank: Bool
    var minAge: Int
    var maxAge: Int
    var genderPreference: GenderPreference
    
    enum GenderPreference: String, CaseIterable, Identifiable {
        case all = "Todos"
        case male = "Hombre"
        case female = "Mujer"
        
        var id: String { self.rawValue }
    }
    
    static let `default` = AppSettings(
        colorScheme: nil,
        filterByRank: false,
        minAge: 18,
        maxAge: 50,
        genderPreference: .all
    )
} 