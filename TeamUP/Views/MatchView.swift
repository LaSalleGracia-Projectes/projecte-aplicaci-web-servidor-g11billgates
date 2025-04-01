import SwiftUI

struct MatchView: View {
    let matchedUser: User
    @Binding var isPresented: Bool
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            // Fondo con efecto de desenfoque
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Texto de Match con animación
                Text("¡MATCH!")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: Color(red: 0.9, green: 0.3, blue: 0.2), radius: 10)
                
                // Imágenes de perfil con animación
                HStack(spacing: 20) {
                    Image(matchedUser.profileImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 4))
                        .shadow(color: Color(red: 0.9, green: 0.3, blue: 0.2), radius: 10)
                    
                    Image(systemName: "heart.fill")
                        .font(.system(size: 40))
                        .foregroundColor(Color(red: 0.9, green: 0.3, blue: 0.2))
                        .shadow(color: .white, radius: 10)
                }
                
                // Mensaje personalizado
                Text("¡Has hecho match con \(matchedUser.name)!")
                    .font(.title2)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // Botones de acción
                VStack(spacing: 15) {
                    Button(action: {
                        // Aquí iríamos al chat
                        NotificationCenter.default.post(
                            name: NSNotification.Name("NewChatAdded"),
                            object: nil,
                            userInfo: [
                                "chat": ChatPreview(
                                    id: UUID().uuidString,
                                    username: matchedUser.name,
                                    lastMessage: "¡Hola! ¡Hemos hecho match!",
                                    timestamp: "Ahora",
                                    profileImage: matchedUser.profileImage
                                )
                            ]
                        )
                        isPresented = false
                    }) {
                        Text("Enviar mensaje")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(red: 0.9, green: 0.3, blue: 0.2))
                            .cornerRadius(15)
                    }
                    
                    Button(action: {
                        isPresented = false
                    }) {
                        Text("Seguir buscando")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.3))
                            .cornerRadius(15)
                    }
                }
                .padding(.horizontal, 40)
            }
        }
        .onAppear {
            // Aquí se podría añadir la lógica para guardar el match en la base de datos
        }
    }
}
