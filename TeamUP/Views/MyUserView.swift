import SwiftUI

struct MyUserView: View {
    @StateObject private var viewModel: UserViewModel
    @State private var showSettings = false
    @State private var showGameSelector = false
    @State private var tempName: String = ""
    @State private var tempAge: Int = 18
    @State private var tempGender: String = "Hombre"
    @State private var showImagePicker = false
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authManager: AuthenticationManager
    
    let genderOptions = ["Hombre", "Mujer", "Otro"]
    let isEmptyUser: Bool
    
    init(user: User) {
        _viewModel = StateObject(wrappedValue: UserViewModel(user: user))
        isEmptyUser = user.name.isEmpty && user.description.isEmpty && user.games.isEmpty
    }
    
    var body: some View {
        if isEmptyUser {
            VStack(spacing: 24) {
                Image(systemName: "person.crop.circle.badge.exclam")
                    .resizable()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.gray)
                Text("No has iniciado sesión")
                    .font(.title2)
                    .foregroundColor(.gray)
                Button(action: {
                    authManager.logout()
                }) {
                    Text("Volver a iniciar sesión")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(red: 0.9, green: 0.3, blue: 0.2))
                        .cornerRadius(10)
                }
                .padding(.horizontal, 32)
            }
            .padding()
        } else {
            NavigationStack {
                VStack(spacing: 0) {
                    // Header
                    ZStack {
                        HStack {
                            Spacer()
                            Text("Team")
                                .font(.system(size: 28, weight: .bold)) +
                            Text("UP")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(Color(red: 0.9, green: 0.3, blue: 0.2))
                            Spacer()
                        }
                        
                        HStack {
                            Spacer()
                            Button(action: {
                                showSettings = true
                            }) {
                                Image(systemName: "gear")
                                    .font(.system(size: 20))
                                    .foregroundColor(Color(red: 0.9, green: 0.3, blue: 0.2))
                            }
                            .padding(.trailing, 16)
                        }
                    }
                    .padding(.vertical, 8)
                    .background(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.2), radius: 5, y: 2)
                    
                    ScrollView {
                        VStack(spacing: 20) {
                            // Imagen de perfil
                            ZStack {
                                if viewModel.user.profileImage.starts(with: "http") {
                                    AsyncImage(url: URL(string: viewModel.user.profileImage)) { image in
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 120, height: 120)
                                            .clipShape(Circle())
                                            .overlay(Circle().stroke(Color(red: 0.9, green: 0.3, blue: 0.2), lineWidth: 3))
                                    } placeholder: {
                                        Image(systemName: "person.circle.fill")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 120, height: 120)
                                            .foregroundColor(.gray)
                                            .overlay(Circle().stroke(Color(red: 0.9, green: 0.3, blue: 0.2), lineWidth: 3))
                                    }
                                } else {
                                    Image(viewModel.user.profileImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 120, height: 120)
                                        .clipShape(Circle())
                                        .overlay(Circle().stroke(Color(red: 0.9, green: 0.3, blue: 0.2), lineWidth: 3))
                                }
                                
                                if viewModel.isEditingProfile {
                                    Button(action: {
                                        showImagePicker = true
                                    }) {
                                        ZStack {
                                            Circle()
                                                .fill(Color(red: 0.9, green: 0.3, blue: 0.2))
                                                .frame(width: 36, height: 36)
                                            
                                            Image(systemName: "camera.fill")
                                                .foregroundColor(.white)
                                                .font(.system(size: 18))
                                        }
                                    }
                                    .offset(x: 40, y: 40)
                                }
                            }
                            .padding(.top, 20)
                            
                            // Información del usuario
                            VStack(spacing: 20) {
                                if viewModel.isEditingProfile {
                                    // Modo edición
                                    VStack(alignment: .leading, spacing: 16) {
                                        Text("Información personal")
                                            .font(.system(size: 18, weight: .semibold))
                                            .padding(.horizontal, 16)
                                        
                                        VStack(spacing: 12) {
                                            // Nombre
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text("Nombre")
                                                    .font(.caption)
                                                    .foregroundColor(.gray)
                                                
                                                TextField("Nombre", text: $tempName)
                                                    .padding(10)
                                                    .background(Color(.systemGray6))
                                                    .cornerRadius(8)
                                            }
                                            
                                            // Edad
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text("Edad")
                                                    .font(.caption)
                                                    .foregroundColor(.gray)
                                                
                                                HStack {
                                                    Text("\(tempAge) años")
                                                    
                                                    Spacer()
                                                    
                                                    Stepper("", value: $tempAge, in: 18...100)
                                                }
                                                .padding(10)
                                                .background(Color(.systemGray6))
                                                .cornerRadius(8)
                                            }
                                            
                                            // Género
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text("Género")
                                                    .font(.caption)
                                                    .foregroundColor(.gray)
                                                
                                                Picker("Género", selection: $tempGender) {
                                                    ForEach(genderOptions, id: \.self) { option in
                                                        Text(option).tag(option)
                                                    }
                                                }
                                                .pickerStyle(.segmented)
                                                .padding(10)
                                                .background(Color(.systemGray6))
                                                .cornerRadius(8)
                                            }
                                        }
                                        .padding(.horizontal, 16)
                                    }
                                } else {
                                    // Modo visualización
                                    VStack(spacing: 8) {
                                        Text(viewModel.user.name)
                                            .font(.system(size: 24, weight: .bold))
                                        
                                        HStack {
                                            Text("\(viewModel.user.age) años")
                                            Text("•")
                                            Text(viewModel.user.gender)
                                        }
                                        .font(.system(size: 16))
                                        .foregroundColor(.gray)
                                    }
                                }
                            }
                            
                            // Biografía
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text("Biografía")
                                        .font(.system(size: 18, weight: .semibold))
                                    
                                    Spacer()
                                    
                                    if viewModel.isEditingProfile {
                                        // Ya tenemos botones de guardar/cancelar abajo
                                    } else {
                                        Button("Editar") {
                                            startEditing()
                                        }
                                        .foregroundColor(Color(red: 0.9, green: 0.3, blue: 0.2))
                                    }
                                }
                                .padding(.horizontal, 16)
                                
                                if viewModel.isEditingProfile {
                                    TextEditor(text: $viewModel.tempBio)
                                        .frame(height: 100)
                                        .padding(8)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(8)
                                        .padding(.horizontal, 16)
                                } else {
                                    Text(viewModel.user.description)
                                        .font(.system(size: 16))
                                        .padding(12)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(8)
                                        .padding(.horizontal, 16)
                                }
                            }
                            .padding(.top, 10)
                            
                            // Juegos
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text("Mis juegos")
                                        .font(.system(size: 18, weight: .semibold))
                                    
                                    Spacer()
                                    
                                    if viewModel.isEditingProfile {
                                        Button("Añadir") {
                                            showGameSelector = true
                                        }
                                        .foregroundColor(Color(red: 0.9, green: 0.3, blue: 0.2))
                                    }
                                }
                                .padding(.horizontal, 16)
                                
                                if viewModel.selectedGames.isEmpty {
                                    Text("No has añadido ningún juego")
                                        .font(.system(size: 16))
                                        .foregroundColor(.gray)
                                        .frame(maxWidth: .infinity, alignment: .center)
                                        .padding(.vertical, 20)
                                } else {
                                    ForEach(viewModel.selectedGames.indices, id: \.self) { index in
                                        let game = viewModel.selectedGames[index]
                                        HStack {
                                            // Icono del juego
                                            Image(systemName: "gamecontroller.fill")
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: 40, height: 40)
                                                .foregroundColor(Color(red: 0.9, green: 0.3, blue: 0.2))
                                                .padding(4)
                                                .background(Color.white.opacity(0.2))
                                                .cornerRadius(8)
                                            
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(game.name)
                                                    .font(.system(size: 16, weight: .semibold))
                                                
                                                if viewModel.isEditingProfile {
                                                    Picker("Rango", selection: Binding(
                                                        get: { game.selectedRank ?? game.ranks.first ?? "" },
                                                        set: { viewModel.updateGameRank(for: game.name, rank: $0) }
                                                    )) {
                                                        ForEach(game.ranks, id: \.self) { rank in
                                                            Text(rank).tag(rank)
                                                        }
                                                    }
                                                    .pickerStyle(.menu)
                                                } else {
                                                    Text(game.selectedRank ?? "Sin rango")
                                                        .font(.system(size: 14))
                                                        .foregroundColor(.gray)
                                                }
                                            }
                                            
                                            Spacer()
                                            
                                            if viewModel.isEditingProfile {
                                                Button(action: {
                                                    viewModel.removeGame(at: index)
                                                }) {
                                                    Image(systemName: "minus.circle.fill")
                                                        .foregroundColor(.red)
                                                }
                                            }
                                        }
                                        .padding(12)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(8)
                                        .padding(.horizontal, 16)
                                    }
                                }
                            }
                            .padding(.top, 10)
                            
                            // Botones de edición
                            if viewModel.isEditingProfile {
                                HStack(spacing: 20) {
                                    Button(action: {
                                        cancelEditing()
                                    }) {
                                        Text("Cancelar")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.gray)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                            .background(Color(.systemGray5))
                                            .cornerRadius(10)
                                    }
                                    
                                    Button(action: {
                                        saveChanges()
                                    }) {
                                        Text("Guardar")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                            .background(Color(red: 0.9, green: 0.3, blue: 0.2))
                                            .cornerRadius(10)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.top, 20)
                                .padding(.bottom, 30)
                            }
                            
                            Spacer(minLength: 30)
                        }
                    }

                    // Botón de cerrar sesión
                    Button(action: {
                        viewModel.logout()
                        authManager.isAuthenticated = false
                    }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Cerrar sesión")
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(red: 0.9, green: 0.3, blue: 0.2))
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
                .background(Color(.systemGray6))
                .sheet(isPresented: $showSettings) {
                    SettingsView()
                }
                .sheet(isPresented: $showGameSelector) {
                    GameSelectorView(selectedGames: viewModel.selectedGames) { game in
                        viewModel.addGame(game)
                    }
                }
                .onAppear {
                    tempName = viewModel.user.name
                    tempAge = viewModel.user.age
                    tempGender = viewModel.user.gender
                }
            }
        }
    }
    
    private func startEditing() {
        tempName = viewModel.user.name
        tempAge = viewModel.user.age
        tempGender = viewModel.user.gender
        viewModel.tempBio = viewModel.user.description
        viewModel.isEditingProfile = true
    }
    
    private func cancelEditing() {
        viewModel.isEditingProfile = false
    }
    
    private func saveChanges() {
        // Actualizar los datos del usuario
        viewModel.user.name = tempName
        viewModel.user.age = tempAge
        viewModel.user.gender = tempGender
        viewModel.updateProfile()
    }
}

// Vista para seleccionar juegos
struct GameSelectorView: View {
    var selectedGames: [Game]
    var onGameSelected: (Game) -> Void
    @Environment(\.dismiss) var dismiss
    
    var availableGames: [Game] {
        Game.allGames.filter { game in
            !selectedGames.contains(where: { $0.name == game.name })
        }
    }
    
    var body: some View {
        NavigationStack {
            List(availableGames) { game in
                Button(action: {
                    onGameSelected(game)
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: "gamecontroller.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 40, height: 40)
                            .foregroundColor(Color(red: 0.9, green: 0.3, blue: 0.2))
                        
                        Text(game.name)
                            .font(.system(size: 16))
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Seleccionar juego")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
            }
        }
    }
} 
