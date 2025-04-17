import SwiftUI

struct MainScreenView: View {
    @StateObject private var viewModel = MainScreenViewModel()
    @State private var showLikeOverlay = false
    @State private var showDislikeOverlay = false
    @State private var showSettings = false
    @State private var selectedUser: User?
    @State private var showMatchView = false
    @State private var matchedUser: User?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header - Ajustado para coincidir con otras vistas
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
                .frame(height: 56)
                .padding(.vertical, 8)
                .background(Color(.systemBackground))
                .shadow(color: .black.opacity(0.2), radius: 5, y: 2)
                
                // Contenido principal
                ScrollView {
                    // Card Stack or Message
                    ZStack {
                        if viewModel.currentIndex < viewModel.users.count {
                            CardView(
                                user: viewModel.users[viewModel.currentIndex],
                                onLike: {
                                    withAnimation(.spring()) {
                                        showLikeOverlay = true
                                        Task {
                                            await viewModel.likeUser(viewModel.users[viewModel.currentIndex].id)
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                                showLikeOverlay = false
                                            }
                                        }
                                    }
                                },
                                onDislike: {
                                    withAnimation(.spring()) {
                                        showDislikeOverlay = true
                                        viewModel.dislikeUser()
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                            showDislikeOverlay = false
                                        }
                                    }
                                },
                                onNameTap: { user in
                                    selectedUser = user
                                }
                            )
                            .transition(AnyTransition.asymmetric(
                                insertion: .opacity,
                                removal: .opacity
                            ))
                            .id(viewModel.currentIndex)
                            
                            // Like Overlay
                            if showLikeOverlay {
                                Text("LIKE")
                                    .font(.system(size: 80, weight: .bold))
                                    .foregroundColor(Color(red: 0.9, green: 0.3, blue: 0.2))
                                    .rotationEffect(.degrees(30))
                                    .transition(.scale)
                            }
                            
                            // Dislike Overlay
                            if showDislikeOverlay {
                                Text("MEH")
                                    .font(.system(size: 80, weight: .bold))
                                    .foregroundColor(.red)
                                    .rotationEffect(.degrees(-30))
                                    .transition(.scale)
                            }
                            
                        } else {
                            Text("Ya no quedan usuarios que mostrar, inténtalo más tarde")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.gray)
                                .padding()
                                .multilineTextAlignment(.center)
                        }
                    }
                    
                    // Botones de Like/Dislike
                    if viewModel.currentIndex < viewModel.users.count {
                        HStack(spacing: 60) {
                            // Botón Dislike
                            Button(action: {
                                withAnimation(.spring()) {
                                    showDislikeOverlay = true
                                    viewModel.dislikeUser()
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                        showDislikeOverlay = false
                                    }
                                }
                            }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 64, height: 64)
                                    .background(Color.red)
                                    .clipShape(Circle())
                                    .shadow(radius: 4)
                            }
                            
                            // Botón Like
                            Button(action: {
                                withAnimation(.spring()) {
                                    showLikeOverlay = true
                                    Task {
                                        await viewModel.likeUser(viewModel.users[viewModel.currentIndex].id)
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                            showLikeOverlay = false
                                        }
                                    }
                                }
                            }) {
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 64, height: 64)
                                    .background(Color(red: 0.9, green: 0.3, blue: 0.2))
                                    .clipShape(Circle())
                                    .shadow(radius: 4)
                            }
                        }
                        .padding(.top, 32)
                        .padding(.bottom, 24)
                    }
                }
            }
            .background(Color(.systemGray6))
            .navigationBarHidden(true)
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .sheet(item: $selectedUser) { user in
                UserDetailView(user: user)
            }
            .fullScreenCover(isPresented: $showMatchView) {
                if let matchedUser = matchedUser {
                    MatchView(matchedUser: matchedUser, isShowing: $showMatchView)
                }
            }
        }
    }
}

struct CardView: View {
    let user: User
    let onLike: () -> Void
    let onDislike: () -> Void
    let onNameTap: (User) -> Void
    
    @State private var offset = CGSize.zero
    @State private var color = Color.black
    
    // Ajustamos el tamaño de la tarjeta según el dispositivo
    private var cardWidth: CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        let isIPad = UIDevice.current.userInterfaceIdiom == .pad
        
        if isIPad {
            return min(screenWidth - 80, screenHeight * 0.6)
        } else {
            return screenWidth - 40
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Imagen de perfil y nombre
            ZStack(alignment: .bottom) {
                Image(user.profileImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: cardWidth, height: cardWidth)
                    .clipped()
                
                // Gradiente para el texto
                LinearGradient(
                    gradient: Gradient(colors: [.clear, .black.opacity(0.8)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 100)
                
                // Información del usuario
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Button(action: { onNameTap(user) }) {
                            Text("\(user.name), \(user.age)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        
                        // Porcentaje de coincidencia
                        Text("\(user.matchPercentage)% Match")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(red: 0.9, green: 0.3, blue: 0.2))
                            .cornerRadius(12)
                    }
                    
                    if !user.description.isEmpty {
                        Text(user.description)
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .lineLimit(2)
                    }
                }
                .padding()
            }
            
            // Juegos en común
            VStack(alignment: .leading, spacing: 12) {
                Text("Juegos en común")
                    .font(.headline)
                    .padding(.horizontal)
                    .padding(.top, 12)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(user.commonGames, id: \.name) { game in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(game.name)
                                    .font(.system(size: 16, weight: .semibold))
                                
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text("Tu rango")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                        Text(game.myRank)
                                            .font(.system(size: 14, weight: .medium))
                                    }
                                    
                                    Divider()
                                        .frame(height: 24)
                                        .padding(.horizontal, 8)
                                    
                                    VStack(alignment: .leading) {
                                        Text("Su rango")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                        Text(game.theirRank)
                                            .font(.system(size: 14, weight: .medium))
                                    }
                                }
                            }
                            .padding(12)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 12)
            }
            .background(Color(.systemBackground))
        }
        .frame(width: cardWidth)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(radius: 5)
        .offset(x: offset.width * 1.2, y: 0)
        .rotationEffect(.degrees(Double(offset.width / 40)))
        .gesture(
            DragGesture()
                .onChanged { gesture in
                    offset = gesture.translation
                    withAnimation {
                        color = offset.width > 0 ? .green : .red
                    }
                }
                .onEnded { _ in
                    withAnimation(.spring()) {
                        if offset.width > 120 {
                            offset.width = 500
                            onLike()
                        } else if offset.width < -120 {
                            offset.width = -500
                            onDislike()
                        } else {
                            offset = .zero
                            color = .black
                        }
                    }
                }
        )
    }
}

#Preview {
    MainScreenView()
} 
