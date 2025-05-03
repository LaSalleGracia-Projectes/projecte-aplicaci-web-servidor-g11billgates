import SwiftUI

struct MainScreenView: View {
    @StateObject private var viewModel = MainScreenViewModel()
    @State private var showLikeOverlay = false
    @State private var showDislikeOverlay = false
    @State private var showSettings = false
    @State private var selectedUser: User?
    @State private var showMatchView = false
    @State private var matchedUser: User?
    @State private var currentUserIndex = 0
    @State private var offset: CGSize = .zero
    @State private var swipeCount = 0
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGray6)
                    .ignoresSafeArea()
                
                VStack {
                    HeaderView(swipeCount: swipeCount)
                    
                    if !viewModel.users.isEmpty {
                        CardStackView(
                            users: viewModel.users,
                            currentIndex: $currentUserIndex,
                            offset: $offset,
                            swipeCount: $swipeCount,
                            viewModel: viewModel
                        )
                    } else {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Color(red: 0.9, green: 0.3, blue: 0.2)))
                    }
                    
                    Spacer()
                }
            }
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
        .task {
            await viewModel.loadUsers()
        }
    }
}

struct HeaderView: View {
    let swipeCount: Int
    
    var body: some View {
        HStack {
            Text("Team")
                .font(.system(size: 28, weight: .bold)) +
            Text("UP")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(Color(red: 0.9, green: 0.3, blue: 0.2))
            
            Spacer()
            
            HStack {
                Image(systemName: "hand.draw.fill")
                    .foregroundColor(Color(red: 0.9, green: 0.3, blue: 0.2))
                Text("\(swipeCount)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            .padding(8)
            .background(Color(.systemBackground))
            .cornerRadius(10)
            .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
        }
        .padding()
    }
}

struct CardStackView: View {
    let users: [User]
    @Binding var currentIndex: Int
    @Binding var offset: CGSize
    @Binding var swipeCount: Int
    @ObservedObject var viewModel: MainScreenViewModel
    
    var body: some View {
        ZStack {
            ForEach(Array(users.enumerated()), id: \.element.id) { index, user in
                if index >= currentIndex {
                    CardView(user: user)
                        .offset(index == currentIndex ? offset : .zero)
                        .rotationEffect(.degrees(index == currentIndex ? Double(offset.width / 20) : 0))
                        .scaleEffect(index == currentIndex ? 1.0 : 0.9)
                        .gesture(
                            DragGesture()
                                .onChanged { gesture in
                                    if index == currentIndex {
                                        offset = gesture.translation
                                    }
                                }
                                .onEnded { gesture in
                                    handleSwipe(gesture: gesture, user: user)
                                }
                        )
                }
            }
        }
    }
    
    private func handleSwipe(gesture: DragGesture.Value, user: User) {
        let horizontalAmount = gesture.translation.width
        let verticalAmount = gesture.translation.height
        
        if abs(horizontalAmount) > 100 || abs(verticalAmount) > 100 {
            if horizontalAmount > 0 {
                // Like
                Task {
                    do {
                        swipeCount = try await UserService.shared.incrementSwipes(userId: user.id)
                        await viewModel.likeUser()
                    } catch {
                        print("Error liking user: \(error)")
                    }
                }
            } else {
                // Dislike
                Task {
                    do {
                        swipeCount = try await UserService.shared.incrementSwipes(userId: user.id)
                        await viewModel.dislikeUser()
                    } catch {
                        print("Error incrementing swipes: \(error)")
                    }
                }
            }
            
            withAnimation {
                offset = CGSize(width: horizontalAmount > 0 ? 500 : -500, height: 0)
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                currentIndex += 1
                offset = .zero
            }
        } else {
            withAnimation {
                offset = .zero
            }
        }
    }
}

struct CardView: View {
    let user: User
    
    var body: some View {
        VStack {
            // User Image
            AsyncImage(url: URL(string: user.profileImage)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.gray
            }
            .frame(height: 400)
            .clipped()
            
            // User Info
            VStack(alignment: .leading, spacing: 8) {
                Text(user.name)
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("\(user.age) años")
                    .font(.subheadline)
                
                Text(user.description)
                    .font(.body)
                    .lineLimit(3)
                
                // Games
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(user.games, id: \.0) { game, rank in
                            VStack {
                                Text(game)
                                    .font(.caption)
                                    .fontWeight(.bold)
                                Text(rank)
                                    .font(.caption2)
                            }
                            .padding(8)
                            .background(Color(red: 0.9, green: 0.3, blue: 0.2).opacity(0.2))
                            .cornerRadius(8)
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(radius: 10)
        .padding()
    }
}

#Preview {
    MainScreenView()
} 
