import Foundation
import UIKit
import AVFoundation
import UniformTypeIdentifiers
import Vision

class MediaService {
    static let shared = MediaService()
    private let baseURL = "http://localhost:3000" // Asegúrate de que esta URL coincida con tu servidor
    
    // Límites de tamaño en bytes
    private let maxImageSize: Int64 = 10 * 1024 * 1024 // 10MB
    private let maxVideoSize: Int64 = 50 * 1024 * 1024 // 50MB
    private let maxAudioSize: Int64 = 10 * 1024 * 1024 // 10MB
    
    // Tipos de archivo permitidos
    private let allowedImageTypes = ["public.jpeg", "public.png", "public.gif"]
    private let allowedVideoTypes = ["public.movie", "public.video"]
    private let allowedAudioTypes = ["public.audio"]
    
    // Umbral de confianza para contenido inapropiado
    private let inappropriateContentThreshold: Float = 0.7
    
    private init() {}
    
    // MARK: - Validation Methods
    
    private func validateFileSize(at url: URL, maxSize: Int64) throws {
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        let fileSize = attributes[.size] as? Int64 ?? 0
        
        if fileSize > maxSize {
            throw MediaError.fileTooLarge
        }
    }
    
    private func validateFileType(at url: URL, allowedTypes: [String]) throws {
        guard let fileType = try? url.resourceValues(forKeys: [.typeIdentifierKey]).typeIdentifier,
              let utType = UTType(fileType) else {
            throw MediaError.invalidFileType
        }
        
        let isAllowed = allowedTypes.contains { type in
            UTType(type)?.conforms(to: utType) ?? false
        }
        
        if !isAllowed {
            throw MediaError.invalidFileType
        }
    }
    
    // MARK: - Upload Methods
    
    private func uploadMedia(data: Data, filename: String, mimeType: String, chatId: String, userId: String) async throws -> MediaResponse {
        let boundary = UUID().uuidString
        var request = URLRequest(url: URL(string: "\(baseURL)/upload-chat-media")!)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var bodyData = Data()
        
        // Añadir chatId
        bodyData.append("--\(boundary)\r\n".data(using: .utf8)!)
        bodyData.append("Content-Disposition: form-data; name=\"chatId\"\r\n\r\n".data(using: .utf8)!)
        bodyData.append("\(chatId)\r\n".data(using: .utf8)!)
        
        // Añadir userId
        bodyData.append("--\(boundary)\r\n".data(using: .utf8)!)
        bodyData.append("Content-Disposition: form-data; name=\"userId\"\r\n\r\n".data(using: .utf8)!)
        bodyData.append("\(userId)\r\n".data(using: .utf8)!)
        
        // Añadir archivo
        bodyData.append("--\(boundary)\r\n".data(using: .utf8)!)
        bodyData.append("Content-Disposition: form-data; name=\"chatMedia\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        bodyData.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        bodyData.append(data)
        bodyData.append("\r\n".data(using: .utf8)!)
        
        bodyData.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = bodyData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw MediaError.uploadFailed
        }
        
        let decoder = JSONDecoder()
        let result = try decoder.decode(MediaUploadResponse.self, from: data)
        return result.data
    }
    
    func uploadImage(_ image: UIImage, forChat chatId: String, userId: String) async throws -> MediaResponse {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw MediaError.invalidImageData
        }
        
        return try await uploadMedia(
            data: imageData,
            filename: "image.jpg",
            mimeType: "image/jpeg",
            chatId: chatId,
            userId: userId
        )
    }
    
    func uploadVideo(_ videoURL: URL, forChat chatId: String, userId: String) async throws -> MediaResponse {
        try validateFileSize(at: videoURL, maxSize: maxVideoSize)
        try validateFileType(at: videoURL, allowedTypes: allowedVideoTypes)
        
        let videoData = try Data(contentsOf: videoURL)
        return try await uploadMedia(
            data: videoData,
            filename: "video.mp4",
            mimeType: "video/mp4",
            chatId: chatId,
            userId: userId
        )
    }
    
    func uploadVoiceMessage(_ audioURL: URL, forChat chatId: String, userId: String) async throws -> MediaResponse {
        try validateFileSize(at: audioURL, maxSize: maxAudioSize)
        try validateFileType(at: audioURL, allowedTypes: allowedAudioTypes)
        
        let audioData = try Data(contentsOf: audioURL)
        return try await uploadMedia(
            data: audioData,
            filename: "voice.m4a",
            mimeType: "audio/m4a",
            chatId: chatId,
            userId: userId
        )
    }
    
    // MARK: - Content Analysis
    
    private func checkInappropriateContent(_ image: UIImage, userId: String) async throws {
        guard let cgImage = image.cgImage else {
            throw MediaError.invalidImageData
        }
        
        let request = VNClassifyImageRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        try handler.perform([request])
        
        guard let observations = request.results else {
            return
        }
        
        // Palabras clave que indican contenido inapropiado
        let inappropriateKeywords = ["adult", "nude", "naked", "porn", "explicit", "adult content"]
        
        for observation in observations {
            let label = observation.identifier.lowercased()
            if inappropriateKeywords.contains(where: { label.contains($0) }) && 
               observation.confidence > inappropriateContentThreshold {
                // Crear reporte de contenido inapropiado
                let description = "Intento de subir contenido inapropiado. Etiqueta detectada: \(label) con confianza: \(observation.confidence)"
                try await ReportService.shared.createReport(
                    userId: userId,
                    type: .inappropriateContent,
                    description: description
                )
                throw MediaError.inappropriateContent
            }
        }
    }
    
    func getMediaDuration(from url: URL) async throws -> Double {
        let asset = AVURLAsset(url: url)
        let duration = try await asset.load(.duration)
        return duration.seconds
    }
}

// MARK: - Models

struct MediaUploadResponse: Codable {
    let message: String
    let data: MediaResponse
}

struct MediaResponse: Codable {
    let url: String
    let type: String
    let duration: Double?
    let messageId: Int
}

// MARK: - Errors

enum MediaError: Error {
    case invalidImageData
    case uploadFailed
    case invalidResponse
    case fileTooLarge
    case invalidFileType
    case inappropriateContent
    
    var localizedDescription: String {
        switch self {
        case .invalidImageData:
            return "Datos de imagen inválidos"
        case .uploadFailed:
            return "Error al subir el archivo"
        case .invalidResponse:
            return "Respuesta inválida del servidor"
        case .fileTooLarge:
            return "El archivo es demasiado grande"
        case .invalidFileType:
            return "Tipo de archivo no permitido"
        case .inappropriateContent:
            return "El contenido de la imagen no es apropiado y ha sido reportado"
        }
    }
} 