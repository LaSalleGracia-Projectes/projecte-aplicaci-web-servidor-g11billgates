import SwiftUI

struct MatchView: View {
    let matchedUser: User
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("¡Es un match!")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.white)
                
                HStack(spacing: 20) {
                    // User 1 image
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.white)
                    
                    // Heart icon
                    Image(systemName: "heart.fill")
                        .resizable()
                        .frame(width: 50, height: 50)
                        .foregroundColor(.red)
                    
                    // Matched user image
                    if matchedUser.profileImage != "person.circle.fill" {
                        AsyncImage(url: URL(string: matchedUser.profileImage)) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .foregroundColor(.white)
                        }
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 100, height: 100)
                            .foregroundColor(.white)
                    }
                }
                
                Text("Tú y \(matchedUser.name) han coincidido")
                    .font(.title2)
                    .foregroundColor(.white)
                
                Text("¡Empieza a chatear!")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Button(action: {
                    dismiss()
                }) {
                    Text("Continuar")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(red: 0.9, green: 0.3, blue: 0.2))
                        .cornerRadius(10)
                }
                .padding(.horizontal, 40)
                .padding(.top, 20)
            }
            .padding()
        }
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
        )
    )
}
