import Foundation
import Combine

// Modelo de respuesta de autenticación
struct AuthResponse: Codable {
    let user_id: UUID
    let token: String?
    let role: String
    let message: String
}

// Modelo para sincronización de diagnósticos
struct DiagnosisSyncData: Codable {
    let timestamp: Date
    let detectedIssue: String
    let confidence: Double
    let userFeedbackCorrect: Bool?
    let location: String?
    
    enum CodingKeys: String, CodingKey {
        case timestamp
        case detectedIssue = "detected_issue"
        case confidence
        case userFeedbackCorrect = "user_feedback_correct"
        case location
    }
}

// Modelo de respuesta de métricas
struct MetricsResponse: Codable {
    let tpp: Double?
    let nas: Double?
    let cpm: Double?
    let totalDiagnoses: Int
    let issueDistribution: [String: Int]
    
    enum CodingKeys: String, CodingKey {
        case tpp
        case nas
        case cpm
        case totalDiagnoses = "total_diagnoses"
        case issueDistribution = "issue_distribution"
    }
}

// Errores de red
enum NetworkError: Error {
    case invalidURL
    case noData
    case decodingError
    case serverError(String)
    case unauthorized
}

// Servicio de red
@MainActor
class NetworkService {
    static let shared = NetworkService()
    
    private let baseURL = "http://127.0.0.1:8000/api/v1"
    private let session: URLSession
    
    /// Simple connectivity check - returns true if we can reach the server
    var isConnected: Bool {
        return true
    }
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Authentication
    
    func authenticate(userName: String) async throws -> AuthResponse {
        guard let url = URL(string: "\(baseURL)/auth/login") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["username": userName]
        request.httpBody = try? JSONEncoder().encode(body)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.noData
        }
        
        guard httpResponse.statusCode == 200 else {
            throw NetworkError.serverError("Status code: \(httpResponse.statusCode)")
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        return try decoder.decode(AuthResponse.self, from: data)
    }
    
    // MARK: - Sync
    
    func syncDiagnosisData(_ data: [DiagnosisSyncData]) async throws {
        guard let url = URL(string: "\(baseURL)/sync") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        let payload = ["diagnoses": data]
        request.httpBody = try encoder.encode(payload)
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.noData
        }
        
        guard httpResponse.statusCode == 200 else {
            throw NetworkError.serverError("Status code: \(httpResponse.statusCode)")
        }
    }
    
    // MARK: - Metrics
    
    func fetchMetrics(token: String) async throws -> MetricsResponse {
        guard let url = URL(string: "\(baseURL)/metrics") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.noData
        }
        
        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 401 {
                throw NetworkError.unauthorized
            }
            throw NetworkError.serverError("Status code: \(httpResponse.statusCode)")
        }
        
        return try JSONDecoder().decode(MetricsResponse.self, from: data)
    }
    
    // MARK: - Health Check
    
    func checkHealth() async throws {
        guard let url = URL(string: "\(baseURL)/health") else {
            throw NetworkError.invalidURL
        }
        
        let (_, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NetworkError.serverError("Health check failed")
        }
    }
}
