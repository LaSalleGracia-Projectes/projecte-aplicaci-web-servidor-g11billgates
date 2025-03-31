import Foundation
import SwiftUI
import PhotosUI

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var messageText = ""
    @Published var selectedItem: PhotosPickerItem?
    @Published var selectedImage: UIImage?
    @Published var selectedVideoURL: URL?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let mediaService = MediaService.shared
    private let chatId: String
    
    init(chatId: String) {
        self.chatId = chatId
        loadMessages()
    }
    
    private func loadMessages() {
        // TODO: Implementar carga de mensajes desde el servidor
        // Por ahora usamos mensajes de ejemplo
        messages = [
            Message(content: "¡Hola! ¿Jugamos una partida?", isFromCurrentUser: true, timestamp: "14:30"),
            Message(content: "¡Claro! Dame 5 minutos", isFromCurrentUser: false, timestamp: "14:31")
        ]
    }
    
    func sendMessage() {
        guard !messageText.isEmpty else { return }
        
        let newMessage = Message(
            content: messageText,
            isFromCurrentUser: true,
            timestamp: formatTimestamp()
        )
        
        messages.append(newMessage)
        messageText = ""
        
        // TODO: Implementar envío al servidor
    }
    
    func sendImage(_ image: UIImage) {
        Task {
            isLoading = true
            do {
                let mediaURL = try await mediaService.uploadImage(image, forChat: chatId)
                let newMessage = Message(
                    content: "Imagen",
                    type: .image,
                    mediaURL: mediaURL,
                    isFromCurrentUser: true,
                    timestamp: formatTimestamp()
                )
                messages.append(newMessage)
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
    
    func sendVideo(_ videoURL: URL) {
        Task {
            isLoading = true
            do {
                let mediaURL = try await mediaService.uploadVideo(videoURL, forChat: chatId)
                let duration = try await mediaService.getVideoDuration(from: videoURL)
                let newMessage = Message(
                    content: "Video",
                    type: .video,
                    mediaURL: mediaURL,
                    isFromCurrentUser: true,
                    timestamp: formatTimestamp(),
                    duration: duration
                )
                messages.append(newMessage)
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
    
    private func formatTimestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: Date())
    }
} 