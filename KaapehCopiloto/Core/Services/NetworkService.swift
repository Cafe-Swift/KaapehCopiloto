//
//  NetworkService.swift
//  KaapehCopiloto
//
//  Created by Marco Antonio Torres Ramirez on 27/10/25.
//

import Foundation

enum NetworkError: Error, LocalizedError {
    case invalidURL
    case noData
    case decodingError
    case serverError(String)
    case httpError(statusCode: Int)
    case unknownError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL inválida."
        case .noData:
            return "No se recibieron datos del servidor."
        case .decodingError:
            return "Error al decodificar los datos."
        case .serverError(let message):
            return "Error del servidor: \(message)"
        case .httpError(let statusCode):
            return "Error HTTP con código: \(statusCode)"
        case .unknownError:
            return "Ocurrió un error desconocido."
        }
    }
}

class NetworkService {
    static let shared = NetworkService()
    
    // Para desarrollo local localhost:8000
    private let baseURL = "http://localhost:8000/api/v1"
    
    private init() {}
    
    // get request generico
    func get<T: Decodable>(endpoint: String, token: String? = nil) async throws -> T {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.serverError("Invalid response")
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.httpError(statusCode: httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            let decoded = try decoder.decode(T.self, from: data)
            return decoded
        } catch {
            print("Decoding error: \(error)")
            throw NetworkError.decodingError
        }
    }
    
    // post request generico
    func post<T: Decodable, U: Encodable>(endpoint: String, body: U, token: String? = nil) async throws -> T {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        request.httpBody = try encoder.encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.serverError("Invalid response")
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.httpError(statusCode: httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            let decoded = try decoder.decode(T.self, from: data)
            return decoded
        } catch {
            print("Decoding error: \(error)")
            throw NetworkError.decodingError
        }
    }
    
    // health check
    struct HealthResponse: Codable {
        let status: String
        let timestamp: String
    }
    
    func checkHealth() async throws -> HealthResponse {
        return try await get(endpoint: "/health")
    }
    
    // sync diagnosis data
    struct SyncRequest: Codable {
        let data: [SyncDataItem]
    }
    
    struct SyncDataItem: Codable {
        let detectedIssue: String
        let confidence: Double
        let userFeedbackCorrect: Bool?
        let timestamp: Date
        let preferredLanguage: String
        
        enum CodingKeys: String, CodingKey {
            case detectedIssue = "detected_issue"
            case confidence
            case userFeedbackCorrect = "user_feedback_correct"
            case timestamp
            case preferredLanguage = "preferred_language"
        }
    }
    
    struct SyncResponse: Codable {
        let message: String
        let recordsProcessed: Int
        
        enum CodingKeys: String, CodingKey {
            case message
            case recordsProcessed = "records_processed"
        }
    }
    
    func synvDiagnosisData(records: [DiagnosisRecord], preferredLanguage: String = "es") async throws -> SyncResponse {
        let syncData = records.map { record in
            SyncDataItem(
                detectedIssue: record.detectedIssue,
                confidence: record.confidence,
                userFeedbackCorrect: record.userFeedbackCorrect,
                timestamp: record.timestamp,
                preferredLanguage: preferredLanguage
            )
        }
        
        let request = SyncRequest(data: syncData)
        return try await post(endpoint: "/sync", body: request)
    }
    
    // fetch metrics for technicians
    struct MetricsResponse: Codable {
        let tpp: Double // Tasa de precision percibida
        let nas: Double // Nivel de adopcion de sugerencias
        let cpm: Double // Confiablilidad promedio del modelo
        let fdp: [String] // focos de duda principales
        let totalDiagnoses: Int
        let period: String
        
        enum CodingKeys: String, CodingKey {
            case tpp
            case nas
            case cpm
            case fdp
            case totalDiagnoses = "total_diagnoses"
            case period
        }
    }
    func fetchMetrics(token: String) async throws -> MetricsResponse {
        return try await get(endpoint: "/metrics", token: token)
    }
}
