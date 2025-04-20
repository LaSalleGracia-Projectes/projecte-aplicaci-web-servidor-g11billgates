import SwiftUI
// Asegúrate de que CustomStyles.swift esté en el mismo módulo o target

struct RegisterGamesView: View {
    @ObservedObject var viewModel: RegisterViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showingSuccessAlert = false
    
    var body: some View {
        ZStack {
            Color(.systemGray6)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Selección de juegos
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Selecciona tus juegos")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        ForEach(Game.allGames) { game in
                            GameSelectionRow(game: game, selectedGames: $viewModel.selectedGames)
                        }
                    }
                    .padding()
                    
                    // Género
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Tu género")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Picker("Género", selection: $viewModel.gender) {
                            Text("Hombre").tag(Gender.male)
                            Text("Mujer").tag(Gender.female)
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding()
                    
                    // Preferencias de búsqueda
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Preferencias de búsqueda")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Toggle("Filtrar por rango", isOn: $viewModel.filterByRank)
                        
                        Picker("Buscar jugadores de género", selection: $viewModel.searchPreference) {
                            Text("Todos").tag(SearchPreference.all)
                            Text("Hombre").tag(SearchPreference.male)
                            Text("Mujer").tag(SearchPreference.female)
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding()
                    
                    // Imagen de perfil
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Imagen de perfil")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Button(action: {
                            viewModel.showImagePicker = true
                        }) {
                            if let image = viewModel.profileImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .frame(width: 100, height: 100)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding()
                    .sheet(isPresented: $viewModel.showImagePicker) {
                        ImagePicker(image: $viewModel.profileImage)
                    }
                    
                    // Botón Registrarse
                    Button(action: {
                        Task {
                            await viewModel.register()
                            showingSuccessAlert = true
                        }
                    }) {
                        if viewModel.isRegistering {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Registrarse")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color(red: 0.9, green: 0.3, blue: 0.2))
                    .cornerRadius(10)
                    .disabled(viewModel.isRegistering)
                    .padding()
                }
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage)
        }
        .alert("Registro Exitoso", isPresented: $showingSuccessAlert) {
            Button("OK") {
                // Navigate to main app view or login
                dismiss()
            }
        } message: {
            Text("Tu cuenta ha sido creada exitosamente")
        }
    }
} 