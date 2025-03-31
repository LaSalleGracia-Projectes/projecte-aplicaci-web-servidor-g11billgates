import Foundation
import UIKit
import AVFoundation

class MediaService {
    static let shared = MediaService()
    private let baseURL = "http://localhost:3000" // Asegúrate de que esta URL coincida con tu servidor
    
    private init() {}
    
    func uploadImage(_ image: UIImage, forChat chatId: String) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            throw MediaError.invalidImageData
        }
        
        let boundary = UUID().uuidString
        var request = URLRequest(url: URL(string: "\(baseURL)/upload-chat-media")!)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var bodyData = Data()
        
        // Añadir ID del chat
        bodyData.append("--\(boundary)\r\n".data(using: .utf8)!)
        bodyData.append("Content-Disposition: form-data; name=\"IDChat\"\r\n\r\n".data(using: .utf8)!)
        bodyData.append("\(chatId)\r\n".data(using: .utf8)!)
        
        // Añadir datos de la imagen
        bodyData.append("--\(boundary)\r\n".data(using: .utf8)!)
        bodyData.append("Content-Disposition: form-data; name=\"chatMedia\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
        bodyData.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        bodyData.append(imageData)
        bodyData.append("\r\n".data(using: .utf8)!)
        
        bodyData.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = bodyData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw MediaError.uploadFailed
        }
        
        let responseDict = try JSONSerialization.jsonObject(with: data) as? [String: [String: Any]]
        guard let archivo = responseDict?["archivo"] as? [String: Any],
              let mediaURL = archivo["URL"] as? String else {
            throw MediaError.invalidResponse
        }
        
        return mediaURL
    }
    
    func uploadVideo(_ videoURL: URL, forChat chatId: String) async throws -> String {
        let boundary = UUID().uuidString
        var request = URLRequest(url: URL(string: "\(baseURL)/upload-chat-media")!)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var bodyData = Data()
        
        // Añadir ID del chat
        bodyData.append("--\(boundary)\r\n".data(using: .utf8)!)
        bodyData.append("Content-Disposition: form-data; name=\"IDChat\"\r\n\r\n".data(using: .utf8)!)
        bodyData.append("\(chatId)\r\n".data(using: .utf8)!)
        
        // Añadir datos del video
        let videoData = try Data(contentsOf: videoURL)
        bodyData.append("--\(boundary)\r\n".data(using: .utf8)!)
        bodyData.append("Content-Disposition: form-data; name=\"chatMedia\"; filename=\"video.mp4\"\r\n".data(using: .utf8)!)
        bodyData.append("Content-Type: video/mp4\r\n\r\n".data(using: .utf8)!)
        bodyData.append(videoData)
        bodyData.append("\r\n".data(using: .utf8)!)
        
        bodyData.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = bodyData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw MediaError.uploadFailed
        }
        
        let responseDict = try JSONSerialization.jsonObject(with: data) as? [String: [String: Any]]
        guard let archivo = responseDict?["archivo"] as? [String: Any],
              let mediaURL = archivo["URL"] as? String else {
            throw MediaError.invalidResponse
        }
        
        return mediaURL
    }
    
    func uploadVoiceMessage(_ audioURL: URL, forChat chatId: String) async throws -> String {
        let boundary = UUID().uuidString
        var request = URLRequest(url: URL(string: "\(baseURL)/upload-chat-media")!)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var bodyData = Data()
        
        // Añadir ID del chat
        bodyData.append("--\(boundary)\r\n".data(using: .utf8)!)
        bodyData.append("Content-Disposition: form-data; name=\"IDChat\"\r\n\r\n".data(using: .utf8)!)
        bodyData.append("\(chatId)\r\n".data(using: .utf8)!)
        
        // Añadir datos del mensaje de voz
        let audioData = try Data(contentsOf: audioURL)
        bodyData.append("--\(boundary)\r\n".data(using: .utf8)!)
        bodyData.append("Content-Disposition: form-data; name=\"chatMedia\"; filename=\"voice.m4a\"\r\n".data(using: .utf8)!)
        bodyData.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
        bodyData.append(audioData)
        bodyData.append("\r\n".data(using: .utf8)!)
        
        bodyData.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = bodyData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw MediaError.uploadFailed
        }
        
        let responseDict = try JSONSerialization.jsonObject(with: data) as? [String: [String: Any]]
        guard let archivo = responseDict?["archivo"] as? [String: Any],
              let mediaURL = archivo["URL"] as? String else {
            throw MediaError.invalidResponse
        }
        
        return mediaURL
    }
    
    func getMediaDuration(from url: URL) async throws -> Double {
        let asset = AVURLAsset(url: url)
        let duration = try await asset.load(.duration)
        return duration.seconds
    }
}

enum MediaError: Error {
    case invalidImageData
    case uploadFailed
    case invalidResponse
    
    var localizedDescription: String {
        switch self {
        case .invalidImageData:
            return "Datos de imagen inválidos"
        case .uploadFailed:
            return "Error al subir el archivo"
        case .invalidResponse:
            return "Respuesta inválida del servidor"
        }
    }
} 