import SwiftUI

struct MatchView: View {
    let matchedUser: User
    @Binding var isShowing: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            // Encabezado
            Text("¡Es un Match!")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(Color(red: 0.9, green: 0.3, blue: 0.2))
            
            // Imágenes de perfil
            HStack(spacing: 20) {
                Image(matchedUser.profileImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color(red: 0.9, green: 0.3, blue: 0.2), lineWidth: 4))
            }
            
            // Información del usuario
            Text(matchedUser.name)
                .font(.title2)
                .fontWeight(.semibold)
            
            // Juegos en común
            VStack(alignment: .leading, spacing: 8) {
                Text("Juegos en común:")
                    .font(.headline)
                
                ForEach(matchedUser.commonGames, id: \.name) { game in
                    HStack {
                        Text(game.name)
                            .font(.system(size: 16, weight: .medium))
                        Spacer()
                        Text("\(game.myRank) vs \(game.theirRank)")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)
            
            // Porcentaje de coincidencia
            Text("\(matchedUser.matchPercentage)% de coincidencia")
                .font(.headline)
                .foregroundColor(Color(red: 0.9, green: 0.3, blue: 0.2))
            
            // Botones
            VStack(spacing: 12) {
                Button(action: {
                    // Implementar lógica para enviar mensaje
                }) {
                    Text("Enviar mensaje")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(red: 0.9, green: 0.3, blue: 0.2))
                        .cornerRadius(12)
                }
                
                Button(action: {
                    isShowing = false
                }) {
                    Text("Continuar jugando")
                        .font(.headline)
                        .foregroundColor(Color(red: 0.9, green: 0.3, blue: 0.2))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(red: 0.9, green: 0.3, blue: 0.2), lineWidth: 2)
                        )
                }
            }
            .padding(.horizontal)
        }
        .padding()
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
