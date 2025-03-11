import SwiftUI

// MARK: - Models
struct ChatMessage: Identifiable {
    let id = UUID()
    let content: String
    let timestamp: String
    let isFromCurrentUser: Bool
}

// MARK: - Views
struct ChatView: View {
    let user: User
    @State private var messageText = ""
    @State private var selectedUser: User?
    
    // Mensajes de ejemplo
    private let sampleMessages = [
        ChatMessage(content: "¡Hola! ¿Jugamos una partida?", timestamp: "14:30", isFromCurrentUser: true),
        ChatMessage(content: "¡Claro! Dame 5 minutos", timestamp: "14:31", isFromCurrentUser: false)
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header personalizado
            HStack(spacing: 16) {
                Image(user.profileImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                
                Button(action: {
                    selectedUser = user
                }) {
                    Text(user.name)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                }
                
                Spacer()
            }
            .padding()
            .background(Color(.systemBackground))
            .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
            
            // Área de mensajes
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(sampleMessages) { message in
                        MessageBubble(message: message)
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            
            // Campo de entrada de mensaje
            HStack(spacing: 12) {
                TextField("Mensaje", text: $messageText)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(20)
                
                Button(action: {
                    // Aquí iría la lógica para enviar el mensaje
                    if !messageText.isEmpty {
                        messageText = ""
                    }
                }) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Color(red: 0.9, green: 0.3, blue: 0.2))
                        .clipShape(Circle())
                }
            }
            .padding()
            .background(Color(.systemBackground))
        }
        .sheet(item: $selectedUser) { user in
            UserDetailView(user: user)
        }
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isFromCurrentUser { Spacer() }
            
            VStack(alignment: message.isFromCurrentUser ? .trailing : .leading) {
                Text(message.content)
                    .padding(12)
                    .background(message.isFromCurrentUser ?
                        Color(red: 0.9, green: 0.3, blue: 0.2) :
                        Color(.systemGray6))
                    .foregroundColor(message.isFromCurrentUser ? .white : .primary)
                    .cornerRadius(16)
                
                Text(message.timestamp)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
            }
            
            if !message.isFromCurrentUser { Spacer() }
        }
    }
}
