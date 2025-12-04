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
        print("🔄 Refrescando todos los datos del dashboard...")
        
        // Intentar sincronizar primero con el backend
        await syncWithBackend()
        
        // Recargar todos los analytics avanzados
        await loadAdvancedAnalytics()
        
        print("✅ Datos refrescados correctamente")
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
            
            // Cargar analytics avanzadas
            await loadAdvancedAnalytics()
            
        } catch {
            errorMessage = "Error al sincronizar: \(error.localizedDescription)"
            print("❌ Error de sincronización: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Category Distribution
    
    func loadCategoryDistribution() async {
        isLoadingCategories = true
        
        // Intentar primero cargar desde backend
        if let token = authToken {
            do {
                print("🔄 Cargando distribución de categorías desde backend...")
                let response = try await networkService.fetchCategoryDistribution(token: token)
                
                self.categoryDistribution = response.categories
                print("✅ Categorías cargadas desde backend:")
                for (category, count) in response.categories.sorted(by: { $0.key < $1.key }) {
                    print("   • \(category): \(count)")
                }
                isLoadingCategories = false
                return
            } catch {
                print("⚠️ Error al cargar desde backend: \(error). Usando datos locales...")
            }
        }
        
        // FALLBACK: Calcular desde SwiftData local
        print("📊 Calculando categorías desde SwiftData local...")
        do {
            let allDiagnoses = try dataService.fetchAllDiagnoses(limit: 1000)
            var distribution: [String: Int] = [:]
            
            for diagnosis in allDiagnoses {
                // Agrupar por categoría basada en el tipo de problema
                let category = categorizeIssue(diagnosis.detectedIssue)
                distribution[category, default: 0] += 1
            }
            
            self.categoryDistribution = distribution
            print("✅ Categorías calculadas localmente: \(distribution.count) categorías")
            for (category, count) in distribution.sorted(by: { $0.key < $1.key }) {
                print("   • \(category): \(count)")
            }
        } catch {
            print("❌ Error al calcular categorías locales: \(error)")
            self.categoryDistribution = [:]
        }
        
        isLoadingCategories = false
    }
    
    /// Helper para categorizar problemas
    private func categorizeIssue(_ issue: String) -> String {
        let lowercased = issue.lowercased()
        
        if lowercased.contains("roya") {
            return "Enfermedades"
        } else if lowercased.contains("sano") || lowercased.contains("sana") {
            return "Plantas Sanas"
        } else if lowercased.contains("nitrógeno") || lowercased.contains("nitrogen") ||
                  lowercased.contains("deficiencia") {
            return "Deficiencias Nutricionales"
        } else if lowercased.contains("plaga") || lowercased.contains("insecto") {
            return "Plagas"
        } else {
            return "Otros"
        }
    }
    
    // MARK: - Advanced Analytics Methods
    
    func loadAdvancedAnalytics() async {
        isLoadingAnalytics = true
        
        // Intentar primero cargar desde backend
        if let token = authToken {
            do {
                print("🔄 Cargando analytics avanzadas desde backend...")
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
                
                print("✅ Analytics avanzadas cargadas desde backend:")
                print("   • Frequent Issues: \(frequentIssues.count)")
                print("   • Heatmap Locations: \(heatmapLocations.count)")
                print("   • Trend Points: \(trends?.dataPoints.count ?? 0)")
                print("   • Active Users: \(activeUsers.count)")
                
                isLoadingAnalytics = false
                return
            } catch {
                print("⚠️ Error cargando desde backend: \(error). Calculando desde datos locales...")
            }
        }
        
        // FALLBACK: Calcular desde SwiftData local
        print("📊 Calculando analytics desde SwiftData local...")
        await loadLocalAnalytics()
        isLoadingAnalytics = false
    }
    
    /// Calcula analytics avanzadas desde SwiftData local
    private func loadLocalAnalytics() async {
        do {
            let allDiagnoses = try dataService.fetchAllDiagnoses(limit: 1000)
            print("📊 Diagnósticos locales encontrados: \(allDiagnoses.count)")
            
            // 1. Calcular problemas frecuentes
            var issueCount: [String: Int] = [:]
            for diagnosis in allDiagnoses {
                issueCount[diagnosis.detectedIssue, default: 0] += 1
            }
            
            let total = Double(allDiagnoses.count)
            
            // Calcular confianza promedio por issue
            var issueConfidence: [String: (sum: Double, count: Int)] = [:]
            for diagnosis in allDiagnoses {
                let issue = diagnosis.detectedIssue
                if let existing = issueConfidence[issue] {
                    issueConfidence[issue] = (existing.sum + diagnosis.confidence, existing.count + 1)
                } else {
                    issueConfidence[issue] = (diagnosis.confidence, 1)
                }
            }
            
            self.frequentIssues = issueCount.map { issue, count in
                let avgConf = issueConfidence[issue].map { $0.sum / Double($0.count) } ?? 0.0
                return FrequentIssuesResponse.IssueFrequency(
                    issue: issue,
                    count: count,
                    percentage: total > 0 ? Double(count) / total : 0.0,
                    avgConfidence: avgConf
                )
            }
            .sorted { $0.count > $1.count }
            .prefix(10)
            .map { $0 }
            
            print("✅ Problemas frecuentes calculados: \(self.frequentIssues.count)")
            
            // 2. Calcular ubicaciones (heatmap)
            var locationData: [String: (count: Int, issues: [String], confidenceSum: Double)] = [:]
            for diagnosis in allDiagnoses where diagnosis.hasLocation {
                let locationName = diagnosis.locationName ?? "Ubicación desconocida"
                if var existing = locationData[locationName] {
                    existing.count += 1
                    existing.issues.append(diagnosis.detectedIssue)
                    existing.confidenceSum += diagnosis.confidence
                    locationData[locationName] = existing
                } else {
                    locationData[locationName] = (1, [diagnosis.detectedIssue], diagnosis.confidence)
                }
            }
            
            self.heatmapLocations = locationData.map { location, data in
                // Encontrar el issue más común en esta ubicación
                let issueCounts = Dictionary(grouping: data.issues, by: { $0 }).mapValues { $0.count }
                let mostCommon = issueCounts.max(by: { $0.value < $1.value })?.key ?? "Desconocido"
                let avgConf = data.count > 0 ? data.confidenceSum / Double(data.count) : 0.0
                
                return HeatmapResponse.LocationData(
                    location: location,
                    diagnosesCount: data.count,
                    mostCommonIssue: mostCommon,
                    avgConfidence: avgConf
                )
            }
            .sorted { $0.diagnosesCount > $1.diagnosesCount }
            
            print("✅ Ubicaciones calculadas: \(self.heatmapLocations.count)")
            
            // 3. Calcular tendencias (últimos 30 días)
            let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
            let recentDiagnoses = allDiagnoses.filter { $0.timestamp >= thirtyDaysAgo }
            
            var dailyCounts: [String: Int] = [:]
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            
            for diagnosis in recentDiagnoses {
                let dateString = dateFormatter.string(from: diagnosis.timestamp)
                dailyCounts[dateString, default: 0] += 1
            }
            
            // Agrupar también por categoría para cada punto
            var dailyByCategory: [String: [String: Int]] = [:]
            for diagnosis in recentDiagnoses {
                let dateString = dateFormatter.string(from: diagnosis.timestamp)
                let category = categorizeIssue(diagnosis.detectedIssue)
                
                if dailyByCategory[dateString] == nil {
                    dailyByCategory[dateString] = [:]
                }
                dailyByCategory[dateString]![category, default: 0] += 1
            }
            
            let trendPoints = dailyCounts.map { date, count in
                let byCategory = dailyByCategory[date] ?? [:]
                return TrendsResponse.TrendPoint(
                    date: date,
                    totalDiagnoses: count,
                    byCategory: byCategory
                )
            }
            .sorted { $0.date < $1.date }
            
            self.trends = TrendsResponse(
                period: "30 días",
                interval: "day",
                totalDataPoints: trendPoints.count,
                dataPoints: trendPoints
            )
            print("✅ Tendencias calculadas: \(trendPoints.count) puntos")
            
            // 4. Calcular análisis de feedback
            let withFeedback = allDiagnoses.filter { $0.userFeedbackCorrect != nil }
            let correctDiagnoses = withFeedback.filter { $0.userFeedbackCorrect == true }.count
            let incorrectDiagnoses = withFeedback.filter { $0.userFeedbackCorrect == false }.count
            let totalWithFeedback = withFeedback.count
            
            // Calcular accuracy por issue
            var issueAccuracy: [String: (total: Int, correct: Int, incorrect: Int)] = [:]
            for diagnosis in withFeedback {
                let issue = diagnosis.detectedIssue
                let isCorrect = diagnosis.userFeedbackCorrect == true
                
                if var existing = issueAccuracy[issue] {
                    existing.total += 1
                    if isCorrect {
                        existing.correct += 1
                    } else {
                        existing.incorrect += 1
                    }
                    issueAccuracy[issue] = existing
                } else {
                    issueAccuracy[issue] = (1, isCorrect ? 1 : 0, isCorrect ? 0 : 1)
                }
            }
            
            let issuesWithErrors = issueAccuracy.map { issue, data in
                let accuracy = data.total > 0 ? Double(data.correct) / Double(data.total) : 0.0
                return FeedbackAnalysisResponse.IssueAccuracy(
                    issue: issue,
                    total: data.total,
                    correct: data.correct,
                    incorrect: data.incorrect,
                    accuracy: accuracy
                )
            }
            .sorted { $0.incorrect > $1.incorrect }
            .prefix(5)
            .map { $0 }
            
            self.feedbackAnalysis = FeedbackAnalysisResponse(
                totalWithFeedback: totalWithFeedback,
                correctDiagnoses: correctDiagnoses,
                incorrectDiagnoses: incorrectDiagnoses,
                accuracyRate: totalWithFeedback > 0 ? Double(correctDiagnoses) / Double(totalWithFeedback) : 0.0,
                issuesWithMostErrors: Array(issuesWithErrors)
            )
            
            print("✅ Feedback calculado: \(correctDiagnoses) correctos, \(incorrectDiagnoses) incorrectos")
            
            // 5. Calcular usuarios activos
            var userActivity: [UUID: (userName: String, count: Int, lastDate: Date, issues: [String])] = [:]
            for diagnosis in allDiagnoses {
                if let profile = diagnosis.userProfile {
                    let userId = profile.userId
                    let userName = profile.userName
                    
                    if var existing = userActivity[userId] {
                        existing.count += 1
                        existing.lastDate = max(existing.lastDate, diagnosis.timestamp)
                        existing.issues.append(diagnosis.detectedIssue)
                        userActivity[userId] = existing
                    } else {
                        userActivity[userId] = (userName, 1, diagnosis.timestamp, [diagnosis.detectedIssue])
                    }
                }
            }
            
            let dateFormatter2 = ISO8601DateFormatter()
            self.activeUsers = userActivity.map { userId, activity in
                // Encontrar el issue más común para este usuario
                let issueCounts = Dictionary(grouping: activity.issues, by: { $0 }).mapValues { $0.count }
                let mostCommon = issueCounts.max(by: { $0.value < $1.value })?.key ?? "Desconocido"
                
                // Generar un ID numérico a partir del UUID (solo para cumplir con la API)
                let userIdInt = abs(userId.hashValue)
                
                return ActiveUsersResponse.ActiveUser(
                    userId: userIdInt,
                    username: activity.userName,
                    displayName: activity.userName,
                    totalDiagnoses: activity.count,
                    lastActivity: dateFormatter2.string(from: activity.lastDate),
                    mostCommonIssue: mostCommon
                )
            }
            .sorted { $0.totalDiagnoses > $1.totalDiagnoses }
            .prefix(20)
            .map { $0 }
            
            print("✅ Usuarios activos calculados: \(self.activeUsers.count)")
            
            print("🎉 Analytics locales calculadas exitosamente")
            
        } catch {
            print("❌ Error al calcular analytics locales: \(error)")
            self.errorMessage = "Error al calcular estadísticas locales"
        }
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
