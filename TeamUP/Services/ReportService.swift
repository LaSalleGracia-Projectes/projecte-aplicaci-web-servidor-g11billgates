import Foundation

class ReportService {
    static let shared = ReportService()
    private let baseURL = "http://localhost:3000"
    
    private init() {}
    
    func createReport(userId: String, type: Report.ReportType, description: String) async throws {
        let report = Report(
            id: UUID().uuidString,
            userId: userId,
            type: type,
            description: description,
            timestamp: Date(),
            status: .pending
        )
        
        let url = URL(string: "\(baseURL)/reports")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        request.httpBody = try encoder.encode(report)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw ReportError.failedToCreate
        }
    }
}

enum ReportError: Error {
    case failedToCreate
    
    var localizedDescription: String {
        switch self {
        case .failedToCreate:
            return "Error al crear el reporte"
        }
    }
} 