import SwiftUI

struct MainView: View {
    @StateObject private var viewModel = UserListViewModel()
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 20) {
                ForEach(viewModel.users) { user in
                    UserCardView(user: user)
                }
            }
            .padding()
        }
        .onAppear {
            viewModel.loadUsers()
        }
    }
}

struct UserCardView: View {
    let user: User
    
    var body: some View {
        VStack {
            AsyncImage(url: URL(string: user.profileImage)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            }
            .frame(width: 150, height: 150)
            .clipShape(Circle())
            
            Text(user.name)
                .font(.headline)
            Text("\(user.age) años")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            if !user.description.isEmpty {
                Text(user.description)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            if !user.games.isEmpty {
                VStack(alignment: .leading) {
                    ForEach(user.games, id: \.0) { game in
                        Text("\(game.0): \(game.1)")
                            .font(.caption)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 5)
    }
}

#Preview {
    MainView()
} 