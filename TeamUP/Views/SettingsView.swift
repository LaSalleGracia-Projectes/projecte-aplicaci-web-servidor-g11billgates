import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @Environment(\.dismiss) var dismiss
    @AppStorage("isDarkMode") private var isDarkMode = false
    @State private var filterByRank = false
    @State private var minAge = 18
    @State private var maxAge = 50
    @State private var genderPreference = AppSettings.GenderPreference.all
    @State private var showChangePassword = false
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Cuenta")) {
                    Button(action: {
                        showChangePassword = true
                    }) {
                        HStack {
                            Image(systemName: "lock")
                                .foregroundColor(Color(red: 0.9, green: 0.3, blue: 0.2))
                            Text("Cambiar contraseña")
                        }
                    }
                }
                
                Section(header: Text("Notificaciones")) {
                    Toggle("Mensajes nuevos", isOn: .constant(true))
                    Toggle("Nuevos matches", isOn: .constant(true))
                }
                
                Section(header: Text("Privacidad")) {
                    Toggle("Perfil público", isOn: .constant(true))
                    Toggle("Mostrar edad", isOn: .constant(true))
                }
            }
            .navigationTitle("Ajustes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showChangePassword) {
            ChangePasswordView()
        }
    }
} 