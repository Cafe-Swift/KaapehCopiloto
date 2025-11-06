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
        } catch {
            errorMessage = "Error al sincronizar: \(error.localizedDescription)"
            print("❌ Error de sincronización: \(error)")
        }
        
        isLoading = false
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
