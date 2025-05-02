import SwiftUI

struct UserCardView: View {
    let user: User
    @StateObject private var matchViewModel = MatchViewModel()
    @State private var showMatch = false
    
    var body: some View {
        VStack {
            // User profile image
            if user.profileImage != "person.circle.fill" {
                AsyncImage(url: URL(string: user.profileImage)) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .foregroundColor(.gray)
                }
                .frame(width: 200, height: 200)
                .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 200, height: 200)
                    .foregroundColor(.gray)
            }
            
            // User name
            Text(user.name)
                .font(.title)
                .fontWeight(.bold)
                .padding(.top, 10)
            
            // User age
            Text("\(user.age) años")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            // User games
            VStack(alignment: .leading, spacing: 8) {
                ForEach(user.games, id: \.0) { game in
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
            .padding(.top, 20)
            
            // Like/Dislike buttons
            HStack(spacing: 20) {
                Button(action: {
                    // Dislike action
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .resizable()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.red)
                }
                
                Button(action: {
                    if let userId = Int(user.id) {
                        matchViewModel.likeUser(userId: userId)
                    }
                }) {
                    Image(systemName: "heart.circle.fill")
                        .resizable()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.green)
                }
            }
            .padding(.top, 20)
        }
        .padding()
        .sheet(isPresented: $matchViewModel.showMatch) {
            if let matchedUser = matchViewModel.matchedUser {
                MatchView(matchedUser: matchedUser)
            }
        }
        .alert("Error", isPresented: .constant(!matchViewModel.errorMessage.isEmpty)) {
            Button("OK", role: .cancel) {
                matchViewModel.errorMessage = ""
            }
        } message: {
            Text(matchViewModel.errorMessage)
        }
    }
}

struct UserCardView_Previews: PreviewProvider {
    static var previews: some View {
        UserCardView(
            user: User(
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
} 