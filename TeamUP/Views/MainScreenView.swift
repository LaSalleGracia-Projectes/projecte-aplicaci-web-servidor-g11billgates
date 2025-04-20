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
                                            await viewModel.likeUser()
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                                showLikeOverlay = false
                                            }
                                        }
                                    }
                                },
                                onDislike: {
                                    withAnimation(.spring()) {
                                        showDislikeOverlay = true
                                        Task {
                                            await viewModel.dislikeUser()
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                                showDislikeOverlay = false
                                            }
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
                                    Task {
                                        await viewModel.dislikeUser()
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                            showDislikeOverlay = false
                                        }
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
                                        await viewModel.likeUser()
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
            // En iPad, usamos un tamaño más pequeño y proporcional
            return min(screenWidth - 80, screenHeight * 0.6)
        } else {
            // En iPhone mantenemos el tamaño original
            return screenWidth - 40
        }
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Imagen del usuario
                if user.profileImage.starts(with: "http") {
                    AsyncImage(url: URL(string: user.profileImage)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: cardWidth, height: cardWidth)
                            .clipped()
                    } placeholder: {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: cardWidth, height: cardWidth)
                            .foregroundColor(.gray)
                    }
                } else {
                    Image(user.profileImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: cardWidth, height: cardWidth)
                        .clipped()
                }
                
                // Información del usuario
                VStack(alignment: .leading, spacing: 15) {
                    // Nombre y edad
                    HStack(spacing: 8) {
                        Button(action: {
                            onNameTap(user)
                        }) {
                            Text(user.name)
                                .font(.system(size: 26, weight: .bold))
                                .foregroundColor(.primary)
                        }
                        Text("\(user.age)")
                            .font(.system(size: 24))
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 15)
                    .padding(.leading, 15)
                    
                    // Juegos y rangos
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(user.games, id: \.0) { game in
                            HStack(spacing: 8) {
                                Text(game.0)
                                    .font(.system(size: 17, weight: .medium))
                                Text("•")
                                    .foregroundColor(.gray)
                                Text(game.1)
                                    .font(.system(size: 17))
                                    .foregroundColor(Color(red: 0.9, green: 0.3, blue: 0.2))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemGray6))
                            )
                        }
                    }
                    .padding(.leading, 15)
                    .padding(.bottom, 15)
                }
                .frame(width: cardWidth, alignment: .leading)
                .background(Color(.systemBackground))
            }
            .frame(width: cardWidth)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(radius: 8)
            .offset(x: offset.width, y: 0)
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
            
            // Indicadores de Like/Dislike
            HStack {
                Text("NOPE")
                    .font(.system(size: 20, weight: .bold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.red, lineWidth: 2)
                    )
                    .rotationEffect(.degrees(-30))
                    .opacity(offset.width < -20 ? 1 : 0)
                
                Spacer()
                
                Text("LIKE")
                    .font(.system(size: 20, weight: .bold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(red: 0.9, green: 0.3, blue: 0.2), lineWidth: 2)
                    )
                    .rotationEffect(.degrees(30))
                    .opacity(offset.width > 20 ? 1 : 0)
            }
            .foregroundColor(color)
            .padding(.horizontal, 40)
            .padding(.top, 40)
        }
    }
}

#Preview {
    MainScreenView()
} 
