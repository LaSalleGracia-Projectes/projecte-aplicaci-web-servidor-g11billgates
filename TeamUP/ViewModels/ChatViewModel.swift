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
    
    private let mediaService = MediaService.shared
    private let chatId: String
    private var recordingTimer: Timer?
    
    init(chatId: String) {
        self.chatId = chatId
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
    
    func sendMessage() {
        guard !messageText.isEmpty else { return }
        
        let newMessage = Message(
            content: messageText,
            type: .text,
            isFromCurrentUser: true,
            timestamp: formatTimestamp()
        )
        
        messages.append(newMessage)
        messageText = ""
        
        // TODO: Implementar envío al servidor
    }
    
    func startRecording() {
        let audioFilename = getDocumentsDirectory().appendingPathComponent("\(UUID().uuidString).m4a")
        
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
