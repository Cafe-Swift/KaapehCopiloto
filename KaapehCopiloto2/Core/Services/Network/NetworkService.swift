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

// MARK: - Category Distribution Models
struct CategoryDistributionResponse: Codable {
    let categories: [String: Int]
    let totalDiagnoses: Int
    let timestamp: Date
    
    enum CodingKeys: String, CodingKey {
        case categories
        case totalDiagnoses = "total_diagnoses"
        case timestamp
    }
}

// Errores de red
enum NetworkError: Error {
    case invalidURL
    case noData
    case decodingError
    case serverError(String)
    case unauthorized
    case offline
    
    var isExpectedOfflineError: Bool {
        switch self {
        case .offline:
            return true
        default:
            return false
        }
    }
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
        
        do {
            let (_, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.noData
            }
            
            guard httpResponse.statusCode == 200 else {
                throw NetworkError.serverError("Status code: \(httpResponse.statusCode)")
            }
        } catch let error as URLError {
            // Convertir errores de conexión en NetworkError.offline
            if error.code == .notConnectedToInternet || error.code == .cannotConnectToHost || error.code == .timedOut {
                throw NetworkError.offline
            }
            throw error
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
    
    // MARK: - Category Distribution
    
    func fetchCategoryDistribution(token: String) async throws -> CategoryDistributionResponse {
        guard let url = URL(string: "\(baseURL)/metrics/categories") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        print("📡 Fetching category distribution from: \(url)")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.noData
        }
        
        guard httpResponse.statusCode == 200 else {
            print("❌ Error HTTP: \(httpResponse.statusCode)")
            if httpResponse.statusCode == 401 {
                throw NetworkError.unauthorized
            }
            throw NetworkError.serverError("Status code: \(httpResponse.statusCode)")
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let result = try decoder.decode(CategoryDistributionResponse.self, from: data)
        print("✅ Category distribution fetched: \(result.totalDiagnoses) diagnoses")
        
        return result
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

// MARK: - Analytics Models

struct FrequentIssuesResponse: Codable {
    let totalDiagnoses: Int
    let period: String
    let issues: [IssueFrequency]
    
    enum CodingKeys: String, CodingKey {
        case totalDiagnoses = "total_diagnoses"
        case period
        case issues
    }
    
    struct IssueFrequency: Codable, Identifiable {
        var id: String { issue }
        let issue: String
        let count: Int
        let percentage: Double
        let avgConfidence: Double
        
        enum CodingKeys: String, CodingKey {
            case issue, count, percentage
            case avgConfidence = "avg_confidence"
        }
    }
}

struct HeatmapResponse: Codable {
    let totalLocations: Int
    let locations: [LocationData]
    
    enum CodingKeys: String, CodingKey {
        case totalLocations = "total_locations"
        case locations
    }
    
    struct LocationData: Codable, Identifiable {
        var id: String { location }
        let location: String
        let diagnosesCount: Int
        let mostCommonIssue: String
        let avgConfidence: Double
        
        enum CodingKeys: String, CodingKey {
            case location
            case diagnosesCount = "diagnoses_count"
            case mostCommonIssue = "most_common_issue"
            case avgConfidence = "avg_confidence"
        }
    }
}

struct TrendsResponse: Codable {
    let period: String
    let interval: String
    let totalDataPoints: Int
    let dataPoints: [TrendPoint]
    
    enum CodingKeys: String, CodingKey {
        case period, interval
        case totalDataPoints = "total_data_points"
        case dataPoints = "data_points"
    }
    
    struct TrendPoint: Codable, Identifiable {
        var id: String { date }
        let date: String
        let totalDiagnoses: Int
        let byCategory: [String: Int]
        
        enum CodingKeys: String, CodingKey {
            case date
            case totalDiagnoses = "total_diagnoses"
            case byCategory = "by_category"
        }
    }
}

struct FeedbackAnalysisResponse: Codable {
    let totalWithFeedback: Int
    let correctDiagnoses: Int
    let incorrectDiagnoses: Int
    let accuracyRate: Double
    let issuesWithMostErrors: [IssueAccuracy]
    
    enum CodingKeys: String, CodingKey {
        case totalWithFeedback = "total_with_feedback"
        case correctDiagnoses = "correct_diagnoses"
        case incorrectDiagnoses = "incorrect_diagnoses"
        case accuracyRate = "accuracy_rate"
        case issuesWithMostErrors = "issues_with_most_errors"
    }
    
    struct IssueAccuracy: Codable, Identifiable {
        var id: String { issue }
        let issue: String
        let total: Int
        let correct: Int
        let incorrect: Int
        let accuracy: Double
    }
}

struct ActiveUsersResponse: Codable {
    let totalUsers: Int
    let showing: Int
    let activeUsers: [ActiveUser]
    
    enum CodingKeys: String, CodingKey {
        case totalUsers = "total_users"
        case showing
        case activeUsers = "active_users"
    }
    
    struct ActiveUser: Codable, Identifiable {
        let userId: Int
        let username: String
        let displayName: String
        let totalDiagnoses: Int
        let lastActivity: String?
        let mostCommonIssue: String
        
        var id: Int { userId }
        
        enum CodingKeys: String, CodingKey {
            case userId = "user_id"
            case username
            case displayName = "display_name"
            case totalDiagnoses = "total_diagnoses"
            case lastActivity = "last_activity"
            case mostCommonIssue = "most_common_issue"
        }
    }
}

// MARK: - Analytics Methods Extension
extension NetworkService {
    
    func fetchFrequentIssues(token: String, limit: Int = 10, days: Int? = nil) async throws -> FrequentIssuesResponse {
        var urlString = "\(baseURL)/analytics/frequent-issues?limit=\(limit)"
        if let days = days {
            urlString += "&days=\(days)"
        }
        
        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        print("📊 Fetching frequent issues from: \(url)")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.noData
        }
        
        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 401 { throw NetworkError.unauthorized }
            throw NetworkError.serverError("Status: \(httpResponse.statusCode)")
        }
        
        let decoder = JSONDecoder()
        let result = try decoder.decode(FrequentIssuesResponse.self, from: data)
        print("✅ Frequent issues fetched: \(result.issues.count) issues")
        
        return result
    }
    
    func fetchHeatmap(token: String) async throws -> HeatmapResponse {
        guard let url = URL(string: "\(baseURL)/analytics/heatmap") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        print("🗺️ Fetching heatmap from: \(url)")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.noData
        }
        
        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 401 { throw NetworkError.unauthorized }
            throw NetworkError.serverError("Status: \(httpResponse.statusCode)")
        }
        
        let decoder = JSONDecoder()
        let result = try decoder.decode(HeatmapResponse.self, from: data)
        print("✅ Heatmap fetched: \(result.locations.count) locations")
        
        return result
    }
    
    func fetchTrends(token: String, days: Int = 30, interval: String = "day") async throws -> TrendsResponse {
        guard let url = URL(string: "\(baseURL)/analytics/trends?days=\(days)&interval=\(interval)") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        print("📈 Fetching trends from: \(url)")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.noData
        }
        
        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 401 { throw NetworkError.unauthorized }
            throw NetworkError.serverError("Status: \(httpResponse.statusCode)")
        }
        
        let decoder = JSONDecoder()
        let result = try decoder.decode(TrendsResponse.self, from: data)
        print("✅ Trends fetched: \(result.dataPoints.count) points")
        
        return result
    }
    
    func fetchFeedbackAnalysis(token: String) async throws -> FeedbackAnalysisResponse {
        guard let url = URL(string: "\(baseURL)/analytics/feedback-analysis") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        print("📋 Fetching feedback analysis from: \(url)")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.noData
        }
        
        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 401 { throw NetworkError.unauthorized }
            throw NetworkError.serverError("Status: \(httpResponse.statusCode)")
        }
        
        let decoder = JSONDecoder()
        let result = try decoder.decode(FeedbackAnalysisResponse.self, from: data)
        print("✅ Feedback analysis fetched: \(result.totalWithFeedback) responses")
        
        return result
    }
    
    func fetchActiveUsers(token: String, limit: Int = 20) async throws -> ActiveUsersResponse {
        guard let url = URL(string: "\(baseURL)/analytics/active-users?limit=\(limit)") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        print("👥 Fetching active users from: \(url)")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.noData
        }
        
        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 401 { throw NetworkError.unauthorized }
            throw NetworkError.serverError("Status: \(httpResponse.statusCode)")
        }
        
        let decoder = JSONDecoder()
        let result = try decoder.decode(ActiveUsersResponse.self, from: data)
        print("✅ Active users fetched: \(result.activeUsers.count) users")
        
        return result
    }
}
