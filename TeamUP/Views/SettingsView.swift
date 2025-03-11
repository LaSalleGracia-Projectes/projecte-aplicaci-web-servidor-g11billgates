import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @Environment(\.dismiss) var dismiss
    @AppStorage("isDarkMode") private var isDarkMode = false
    @State private var filterByRank = false
    @State private var minAge = 18
    @State private var maxAge = 50
    @State private var genderPreference = AppSettings.GenderPreference.all
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Apariencia")) {
                    Picker("Tema", selection: $isDarkMode) {
                        Text("Claro").tag(false)
                        Text("Oscuro").tag(true)
                    }
                    .pickerStyle(.segmented)
                }
                
                Section(header: Text("Filtros de juego")) {
                    Toggle("Filtrar por rango", isOn: $filterByRank)
                }
                
                Section(header: Text("Filtros de edad")) {
                    HStack {
                        Text("Edad mínima: \(minAge)")
                        Spacer()
                        Stepper("", value: $minAge, in: 18...maxAge)
                    }
                    
                    HStack {
                        Text("Edad máxima: \(maxAge)")
                        Spacer()
                        Stepper("", value: $maxAge, in: minAge...100)
                    }
                }
                
                Section(header: Text("Filtros de género")) {
                    Picker("Mostrar", selection: $genderPreference) {
                        ForEach(AppSettings.GenderPreference.allCases) { preference in
                            Text(preference.rawValue).tag(preference)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("Configuración")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Guardar") {
                        // Guardar configuraciones
                        viewModel.saveSettings(
                            filterByRank: filterByRank,
                            minAge: minAge,
                            maxAge: maxAge,
                            genderPreference: genderPreference
                        )
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
            .preferredColorScheme(isDarkMode ? .dark : .light)
            .onAppear {
                // Cargar configuraciones actuales
                let settings = viewModel.getSettings()
                filterByRank = settings.filterByRank
                minAge = settings.minAge
                maxAge = settings.maxAge
                genderPreference = settings.genderPreference
            }
        }
    }
} 