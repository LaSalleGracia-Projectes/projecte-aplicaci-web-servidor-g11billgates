import Foundation
import SwiftUI
import PhotosUI
import AVFoundation

@MainActor
class ChatViewModel: NSObject, ObservableObject {
    @Published var messages: [Message] = []
    @Published var messageText = ""
    @Published var selectedItem: PhotosPickerItem?
    @Published var selectedImage: UIImage?
    @Published var selectedVideoURL: URL?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isRecording = false
    @Published var recordingTime: TimeInterval = 0
    @Published var audioRecorder: AVAudioRecorder?
    @Published var audioURL: URL?
    @Published var audioPlayer: AVAudioPlayer?
    @Published var showAgeRestrictionAlert = false
    
    private let mediaService = MediaService.shared
    private let chatId: String
    private let userId: String
    private let userAge: Int
    private var recordingTimer: Timer?
    
    init(chatId: String, userId: String, userAge: Int) {
        self.chatId = chatId
        self.userId = userId
        self.userAge = userAge
        super.init()
        loadMessages()
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default)
            try session.setActive(true)
        } catch {
            errorMessage = "Error al configurar el audio: \(error.localizedDescription)"
        }
    }
    
    private func loadMessages() {
        // TODO: Implementar carga de mensajes desde el servidor
        // Por ahora usamos mensajes de ejemplo
        messages = [
            Message(content: "¡Hola! ¿Jugamos una partida?", type: .text, isFromCurrentUser: true, timestamp: "14:30"),
            Message(content: "¡Claro! Dame 5 minutos", type: .text, isFromCurrentUser: false, timestamp: "14:31")
        ]
    }
    
    private func checkAgeRestriction() -> Bool {
        return userAge >= 18
    }
    
    func sendMessage() async {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        if !checkAgeRestriction() {
            showAgeRestrictionAlert = true
            return
        }
        
        let newMessage = Message(
            content: messageText,
            type: .text,
            isFromCurrentUser: true,
            timestamp: formatTimestamp()
        )
        
        await MainActor.run {
            messages.append(newMessage)
            messageText = ""
        }
        
        // TODO: Implementar envío al servidor
    }
    
    func sendImage(_ image: UIImage) async {
        if !checkAgeRestriction() {
            showAgeRestrictionAlert = true
            return
        }
        
        do {
            let mediaURL = try await mediaService.uploadImage(image, forChat: chatId, userId: userId)
            let message = Message(
                content: "Imagen",
                type: .image,
                mediaURL: mediaURL,
                isFromCurrentUser: true,
                timestamp: formatTimestamp()
            )
            
            await MainActor.run {
                messages.append(message)
            }
        } catch {
            print("Error al subir la imagen: \(error)")
        }
    }
    
    func sendVideo(_ videoURL: URL) async {
        if !checkAgeRestriction() {
            showAgeRestrictionAlert = true
            return
        }
        
        do {
            let mediaURL = try await mediaService.uploadVideo(videoURL, forChat: chatId)
            let duration = try await mediaService.getMediaDuration(from: videoURL)
            let message = Message(
                content: "Video",
                type: .video,
                mediaURL: mediaURL,
                isFromCurrentUser: true,
                timestamp: formatTimestamp(),
                duration: duration
            )
            
            await MainActor.run {
                messages.append(message)
            }
        } catch {
            print("Error al subir el video: \(error)")
        }
    }
    
    func startRecording() {
        if !checkAgeRestriction() {
            showAgeRestrictionAlert = true
            return
        }
        
        let audioFilename = getDocumentsDirectory().appendingPathComponent("\(Date().timeIntervalSince1970).m4a")
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
            audioURL = audioFilename
            isRecording = true
            recordingTime = 0
            
            recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                Task { @MainActor in
                    self?.recordingTime += 0.1
                }
            }
        } catch {
            errorMessage = "Error al iniciar la grabación: \(error.localizedDescription)"
        }
    }
    
    func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
        recordingTimer?.invalidate()
        recordingTimer = nil
        
        if let url = audioURL {
            Task {
                await sendVoiceMessage(url)
            }
        }
    }
    
    private func sendVoiceMessage(_ url: URL) async {
        isLoading = true
        do {
            let mediaURL = try await mediaService.uploadVoiceMessage(url, forChat: chatId)
            let duration = try await mediaService.getMediaDuration(from: url)
            let newMessage = Message(
                content: "Mensaje de voz",
                type: .voice,
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
    
    func playVoiceMessage(_ url: URL) {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.play()
        } catch {
            errorMessage = "Error al reproducir el mensaje de voz: \(error.localizedDescription)"
        }
    }
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private func formatTimestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: Date())
    }
}

// MARK: - AVAudioRecorderDelegate
extension ChatViewModel: AVAudioRecorderDelegate {
    nonisolated func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            Task { @MainActor in
                errorMessage = "Error al finalizar la grabación"
            }
        }
    }
}

// MARK: - AVAudioPlayerDelegate
extension ChatViewModel: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        // Aquí podrías actualizar la UI cuando termine de reproducir
    }
} 
