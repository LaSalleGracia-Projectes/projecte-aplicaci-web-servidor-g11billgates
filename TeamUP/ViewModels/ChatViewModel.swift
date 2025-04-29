import Foundation
import SwiftUI
import PhotosUI
import AVFoundation

@MainActor
class ChatViewModel: NSObject, ObservableObject, AVAudioRecorderDelegate, AVAudioPlayerDelegate {
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
    private let reportedUserId: String
    private var recordingTimer: Timer?
    
    init(chatId: String, userId: String, userAge: Int, reportedUserId: String) {
        self.chatId = chatId
        self.userId = userId
        self.userAge = userAge
        self.reportedUserId = reportedUserId
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
            let mediaResponse = try await mediaService.uploadImage(image, forChat: chatId, userId: userId)
            let message = Message(
                content: "Imagen",
                type: .image,
                mediaURL: mediaResponse.url,
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
            let mediaResponse = try await mediaService.uploadVideo(videoURL, forChat: chatId, userId: userId)
            let duration = try await mediaService.getMediaDuration(from: videoURL)
            let message = Message(
                content: "Video",
                type: .video,
                mediaURL: mediaResponse.url,
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
    
    private func sendVoiceMessage(_ url: URL) async {
        isLoading = true
        do {
            // Create multipart form data
            let boundary = UUID().uuidString
            var request = URLRequest(url: URL(string: "\(API.baseURL)/upload-chat-media")!)
            request.httpMethod = "POST"
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            
            var body = Data()
            
            // Add chatId
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"chatId\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(chatId)\r\n".data(using: .utf8)!)
            
            // Add userId
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"userId\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(userId)\r\n".data(using: .utf8)!)
            
            // Add audio file
            let audioData = try Data(contentsOf: url)
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"chatMedia\"; filename=\"voice_message.m4a\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
            body.append(audioData)
            body.append("\r\n".data(using: .utf8)!)
            
            // End boundary
            body.append("--\(boundary)--\r\n".data(using: .utf8)!)
            
            request.httpBody = body
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            if httpResponse.statusCode == 200 {
                if let responseData = try? JSONDecoder().decode(MediaUploadResponse.self, from: data) {
                    let newMessage = Message(
                        content: "Mensaje de voz",
                        type: .voice,
                        mediaURL: responseData.data.url,
                        isFromCurrentUser: true,
                        timestamp: formatTimestamp(),
                        duration: responseData.data.duration
                    )
                    
                    await MainActor.run {
                        messages.append(newMessage)
                    }
                }
            } else {
                throw APIError.serverError(httpResponse.statusCode)
            }
            
            // Clean up
            try? FileManager.default.removeItem(at: url)
            
        } catch {
            errorMessage = "Error al enviar el mensaje de voz: \(error.localizedDescription)"
        }
        isLoading = false
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
    
    func cancelRecording() {
        audioRecorder?.stop()
        audioRecorder?.deleteRecording()
        isRecording = false
        recordingTimer?.invalidate()
        recordingTimer = nil
        audioURL = nil
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
    
    func stopAudio() {
        audioPlayer?.stop()
        audioPlayer = nil
    }
    
    func pauseAudio() {
        audioPlayer?.pause()
    }
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private func formatTimestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: Date())
    }
    
    func reportUser() async {
        isLoading = true
        do {
            let url = URL(string: "http://localhost:3000/report-user")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let body = [
                "userId": userId,
                "reportedUserId": reportedUserId,
                "chatId": chatId
            ]
            
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            let (_, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NSError(domain: "ChatViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
            }
            
            if httpResponse.statusCode != 200 {
                throw NSError(domain: "ChatViewModel", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Failed to report user"])
            }
            
            // Limpiar los mensajes después de reportar
            await MainActor.run {
                messages = []
            }
            
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
        }
        isLoading = false
    }
    
    // MARK: - AVAudioRecorderDelegate
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            errorMessage = "Error al finalizar la grabación"
        }
    }
    
    // MARK: - AVAudioPlayerDelegate
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if !flag {
            errorMessage = "Error al reproducir el audio"
        }
    }
} 
