import SwiftUI

struct MatchView: View {
    let matchedUser: User
    @Binding var isShowing: Bool
    
    var body: some View {
        ZStack {
            // Fondo con gradiente
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black.opacity(0.9),
                    Color(red: 0.2, green: 0.2, blue: 0.2).opacity(0.95)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 25) {
                // Título con animación
                Text("¡Es un Match!")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: Color(red: 0.9, green: 0.3, blue: 0.2).opacity(0.5), radius: 5, x: 0, y: 2)
                
                // Imágenes de perfil con efecto de brillo
                HStack(spacing: 30) {
                    if matchedUser.profileImage.starts(with: "http") {
                        AsyncImage(url: URL(string: matchedUser.profileImage)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 140, height: 140)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: 3)
                                        .shadow(color: Color(red: 0.9, green: 0.3, blue: 0.2), radius: 10)
                                )
                        } placeholder: {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 140, height: 140)
                                .foregroundColor(.gray)
                        }
                    } else {
                        Image(matchedUser.profileImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 140, height: 140)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 3)
                                    .shadow(color: Color(red: 0.9, green: 0.3, blue: 0.2), radius: 10)
                            )
                    }
                }
                
                // Nombre del usuario con estilo mejorado
                Text(matchedUser.name)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.top, 10)
                
                // Juegos en común con diseño mejorado
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(matchedUser.games, id: \.0) { game in
                        HStack {
                            Text(game.0)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white)
                            Text("•")
                                .foregroundColor(Color(red: 0.9, green: 0.3, blue: 0.2))
                            Text(game.1)
                                .font(.system(size: 18))
                                .foregroundColor(Color(red: 0.9, green: 0.3, blue: 0.2))
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color(.systemGray6).opacity(0.3))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 15)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                        )
                    }
                }
                .padding(.top, 10)
                
                // Botones con diseño mejorado
                HStack(spacing: 25) {
                    Button(action: {
                        isShowing = false
                    }) {
                        Text("Seguir buscando")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.vertical, 15)
                            .padding(.horizontal, 30)
                            .background(
                                RoundedRectangle(cornerRadius: 25)
                                    .fill(Color(red: 0.9, green: 0.3, blue: 0.2))
                                    .shadow(color: Color(red: 0.9, green: 0.3, blue: 0.2).opacity(0.5), radius: 5, x: 0, y: 2)
                            )
                    }
                    
                    NavigationLink(destination: ChatView(
                        chatId: UUID().uuidString,
                        userId: matchedUser.id,
                        userAge: matchedUser.age,
                        reportedUserId: matchedUser.id
                    )) {
                        Text("Enviar mensaje")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.vertical, 15)
                            .padding(.horizontal, 30)
                            .background(
                                RoundedRectangle(cornerRadius: 25)
                                    .fill(Color(red: 0.3, green: 0.8, blue: 0.4))
                                    .shadow(color: Color(red: 0.3, green: 0.8, blue: 0.4).opacity(0.5), radius: 5, x: 0, y: 2)
                            )
                    }
                }
                .padding(.top, 20)
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color(.systemBackground).opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
            .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
        }
        .transition(.opacity)
        .animation(.easeInOut, value: isShowing)
    }
}

#Preview {
    MatchView(
        matchedUser: User(
            id: "1",
            name: "Usuario Ejemplo",
            age: 25,
            gender: "Masculino",
            description: "¡Hola! Me encanta jugar videojuegos competitivos.",
            games: [("League of Legends", "Diamante"), ("Valorant", "Platino")],
            profileImage: "person.circle.fill"
        ),
        isShowing: .constant(true)
    )
}
