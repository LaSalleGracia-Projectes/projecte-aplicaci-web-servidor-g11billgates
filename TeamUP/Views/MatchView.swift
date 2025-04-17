import SwiftUI

struct MatchView: View {
    let matchedUser: User
    @Binding var isShowing: Bool
    
    var body: some View {
        ZStack {
            // Fondo semi-transparente
            Color.black.opacity(0.8)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                // Título
                Text("¡Es un Match!")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                
                // Imágenes de perfil
                HStack(spacing: 20) {
                    if matchedUser.profileImage.starts(with: "http") {
                        AsyncImage(url: URL(string: matchedUser.profileImage)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                        } placeholder: {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 120, height: 120)
                                .foregroundColor(.gray)
                        }
                    } else {
                        Image(matchedUser.profileImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                    }
                }
                
                // Nombre del usuario
                Text(matchedUser.name)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
                
                // Juegos en común
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(matchedUser.games, id: \.0) { game in
                        HStack {
                            Text(game.0)
                                .font(.system(size: 16, weight: .medium))
                            Text("•")
                                .foregroundColor(.gray)
                            Text(game.1)
                                .font(.system(size: 16))
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
                
                // Botones
                HStack(spacing: 20) {
                    Button(action: {
                        isShowing = false
                    }) {
                        Text("Seguir buscando")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 24)
                            .background(Color(red: 0.9, green: 0.3, blue: 0.2))
                            .cornerRadius(25)
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
                            .padding(.vertical, 12)
                            .padding(.horizontal, 24)
                            .background(Color(red: 0.3, green: 0.8, blue: 0.4))
                            .cornerRadius(25)
                    }
                }
            }
            .padding(32)
            .background(Color(.systemBackground).opacity(0.9))
            .cornerRadius(20)
            .shadow(radius: 10)
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
