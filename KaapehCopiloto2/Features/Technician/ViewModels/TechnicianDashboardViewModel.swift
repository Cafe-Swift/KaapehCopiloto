//
//  TechnicianDashboardViewModel.swift
//  KaapehCopiloto2
//
//  Created by Cafe Swift Team on 05/11/25.
//

import Foundation
import SwiftUI
import Combine

// Helper struct for issue distribution
struct IssueDistributionItem: Identifiable {
    let id = UUID()
    let issue: String
    let count: Int
}

@MainActor
@Observable
final class TechnicianDashboardViewModel {
    var tpp: Double = 0.0
    var cpm: Double = 0.0
    var totalDiagnoses: Int = 0
    var diagnosesWithFeedback: Int = 0
    var issueDistribution: [IssueDistributionItem] = []
    var isLoading: Bool = false
    var errorMessage: String?
    var showLogoutConfirmation: Bool = false
    var shouldLogout: Bool = false
    
    // MARK: - Category Distribution Properties
    var categoryDistribution: [String: Int] = [:]
    var isLoadingCategories: Bool = false
    
    // MARK: - Analytics Properties
    var frequentIssues: [FrequentIssuesResponse.IssueFrequency] = []
    var heatmapLocations: [HeatmapResponse.LocationData] = []
    var trends: TrendsResponse?
    var feedbackAnalysis: FeedbackAnalysisResponse?
    var activeUsers: [ActiveUsersResponse.ActiveUser] = []
    var isLoadingAnalytics = false
    
    private let dataService: SwiftDataService
    private let networkService = NetworkService.shared
    private var authToken: String?
    private weak var authViewModel: AuthenticationViewModel?
    
    init(swiftDataService: SwiftDataService, authToken: String? = nil, authViewModel: AuthenticationViewModel? = nil) {
        self.dataService = swiftDataService
        self.authToken = authToken
        self.authViewModel = authViewModel
    }
    
    func loadMetrics(diagnoses: [DiagnosisRecord]) async {
        isLoading = true
        
        do {
            tpp = try dataService.calculateTPP()
            cpm = try dataService.calculateCPM()
            totalDiagnoses = diagnoses.count
            
            // Calculate diagnoses with feedback
            diagnosesWithFeedback = diagnoses.filter { $0.userFeedbackCorrect != nil }.count
            
            // Calculate issue distribution
            var distribution: [String: Int] = [:]
            for diagnosis in diagnoses {
                distribution[diagnosis.detectedIssue, default: 0] += 1
            }
            
            issueDistribution = distribution.map { IssueDistributionItem(issue: $0.key, count: $0.value) }
                .sorted { $0.count > $1.count }
            
        } catch {
            errorMessage = "Error al cargar métricas: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func refreshData() async {
    }
    
    func syncWithBackend() async {
        isLoading = true
        errorMessage = nil
        
        // Verificar que tenemos un token de autenticación
        guard let token = authToken else {
            errorMessage = "No hay sesión activa. Por favor, inicia sesión nuevamente."
            isLoading = false
            return
        }
        
        do {
            // Obtener todas las métricas del backend con el token de autenticación
            let metrics = try await networkService.fetchMetrics(token: token)
            
            // Actualizar las métricas locales con los datos del servidor
            self.tpp = metrics.tpp ?? 0.0
            self.cpm = metrics.cpm ?? 0.0
            self.totalDiagnoses = metrics.totalDiagnoses
            
            print("✅ Sincronización exitosa con el backend")
            
            // También cargar distribución de categorías
            await loadCategoryDistribution()
            
            // 🆕 Cargar analytics avanzadas
            await loadAdvancedAnalytics()
            
        } catch {
            errorMessage = "Error al sincronizar: \(error.localizedDescription)"
            print("❌ Error de sincronización: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Category Distribution
    
    func loadCategoryDistribution() async {
        guard let token = authToken else {
            print("⚠️ No hay token para cargar categorías")
            return
        }
        
        isLoadingCategories = true
        
        do {
            print("🔄 Cargando distribución de categorías...")
            let response = try await networkService.fetchCategoryDistribution(token: token)
            
            self.categoryDistribution = response.categories
            print("✅ Categorías cargadas:")
            for (category, count) in response.categories.sorted(by: { $0.key < $1.key }) {
                print("   • \(category): \(count)")
            }
        } catch {
            print("❌ Error al cargar categorías: \(error)")
            self.categoryDistribution = [:]
        }
        
        isLoadingCategories = false
    }
    
    
    // MARK: - 🆕 Advanced Analytics Methods
    
    func loadAdvancedAnalytics() async {
        guard let token = authToken else {
            print("⚠️ No hay token para analytics")
            return
        }
        
        print("🔄 Cargando analytics avanzadas...")
        isLoadingAnalytics = true
        
        do {
            // Cargar en paralelo para máxima eficiencia
            async let issuesTask = networkService.fetchFrequentIssues(token: token, limit: 10, days: 30)
            async let heatmapTask = networkService.fetchHeatmap(token: token)
            async let trendsTask = networkService.fetchTrends(token: token, days: 30, interval: "day")
            async let feedbackTask = networkService.fetchFeedbackAnalysis(token: token)
            async let usersTask = networkService.fetchActiveUsers(token: token, limit: 20)
            
            let (issuesResponse, heatmapResponse, trendsResponse, feedbackResponse, usersResponse) = 
                try await (issuesTask, heatmapTask, trendsTask, feedbackTask, usersTask)
            
            self.frequentIssues = issuesResponse.issues
            self.heatmapLocations = heatmapResponse.locations
            self.trends = trendsResponse
            self.feedbackAnalysis = feedbackResponse
            self.activeUsers = usersResponse.activeUsers
            
            print("✅ Analytics avanzadas cargadas:")
            print("   • Frequent Issues: \(frequentIssues.count)")
            print("   • Heatmap Locations: \(heatmapLocations.count)")
            print("   • Trend Points: \(trends?.dataPoints.count ?? 0)")
            print("   • Active Users: \(activeUsers.count)")
            
        } catch {
            print("❌ Error cargando analytics: \(error)")
            self.errorMessage = "Error cargando estadísticas avanzadas"
        }
        
        isLoadingAnalytics = false
    }
    
    func logout() {
        // Mostrar confirmación antes de cerrar sesión
        showLogoutConfirmation = true
    }
    
    func confirmLogout() {
        authViewModel?.logout()
        
        shouldLogout = true
        print("✅ Sesión cerrada correctamente")
    }
}
