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
    
    // MARK: - Validation
    
    private func validateFileSize(at url: URL, maxSize: Int64) throws {
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        let fileSize = attributes[.size] as? Int64 ?? 0
        
        if fileSize > maxSize {
            throw MediaError.fileTooLarge
        }
    }
    
    private func validateImage(_ image: UIImage, userId: String) async throws {
        let imageSize = image.jpegData(compressionQuality: 1.0)?.count ?? 0
        if imageSize > maxImageSize {
            throw MediaError.fileTooLarge
        }
        
        // Verificar contenido inapropiado
        try await checkInappropriateContent(image, userId: userId)
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
    
    // MARK: - Content Analysis
    
    private func checkInappropriateContent(_ image: UIImage, userId: String) async throws {
        guard let cgImage = image.cgImage else {
            throw MediaError.invalidImageData
        }
        
        let request = VNClassifyImageRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        try handler.perform([request])
        
        guard let observations = request.results as? [VNClassificationObservation] else {
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
    
    // MARK: - Public Methods
    
    func uploadImage(_ image: UIImage, forChat chatId: String, userId: String) async throws -> String {
        try await validateImage(image, userId: userId)
        
        // Ajustar calidad de compresión según el tamaño
        var compressionQuality: CGFloat = 0.7
        var imageData = image.jpegData(compressionQuality: compressionQuality)
        
        // Reducir calidad si el archivo sigue siendo muy grande
        while let data = imageData, data.count > maxImageSize && compressionQuality > 0.1 {
            compressionQuality -= 0.1
            imageData = image.jpegData(compressionQuality: compressionQuality)
        }
        
        guard let finalImageData = imageData else {
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
        bodyData.append(finalImageData)
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
        try validateFileSize(at: videoURL, maxSize: maxVideoSize)
        try validateFileType(at: videoURL, allowedTypes: allowedVideoTypes)
        
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
        try validateFileSize(at: audioURL, maxSize: maxAudioSize)
        try validateFileType(at: audioURL, allowedTypes: allowedAudioTypes)
        
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