import SwiftUI

class SettingsViewModel: ObservableObject {
    @Published var notificationsEnabled: Bool = true
    @Published var darkModeEnabled: Bool = false
    
    private var settings: AppSettings = AppSettings.default
    
    init() {
        // Aquí cargaríamos las configuraciones guardadas
        // Por ahora, usamos valores predeterminados
    }
    
    func getSettings() -> AppSettings {
        return settings
    }
    
    func saveSettings(filterByRank: Bool, minAge: Int, maxAge: Int, genderPreference: AppSettings.GenderPreference) {
        settings.filterByRank = filterByRank
        settings.minAge = minAge
        settings.maxAge = maxAge
        settings.genderPreference = genderPreference
        
        // Aquí guardaríamos las configuraciones
        // Por ejemplo, usando UserDefaults
        print("Configuraciones guardadas")
    }
    
    func toggleNotifications() {
        notificationsEnabled.toggle()
    }
    
    func toggleDarkMode() {
        darkModeEnabled.toggle()
    }
} 