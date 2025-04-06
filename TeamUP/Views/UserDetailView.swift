import SwiftUI

struct UserDetailView: View {
    let user: User
    
    var body: some View {
        VStack {
            if user.profileImage.starts(with: "http") {
                AsyncImage(url: URL(string: user.profileImage)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 150, height: 150)
                        .clipShape(Circle())
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 150, height: 150)
                        .foregroundColor(.gray)
                }
            } else {
                Image(user.profileImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 150, height: 150)
                    .clipShape(Circle())
            }
            
            Text(user.name)
                .font(.system(size: 28, weight: .bold))
            
            Text("\(user.age) años • \(user.gender)")
                .foregroundColor(.gray)
            
            Text(user.description)
                .padding()
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(user.games, id: \.0) { game in
                    HStack {
                        Text(game.0)
                            .font(.system(size: 14, weight: .medium))
                        Text("•")
                            .foregroundColor(.gray)
                        Text(game.1)
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                }
            }
            
            Spacer()
        }
        .padding()
    }
}
