//
//  ProducerHomeViewModel.swift
//  KaapehCopiloto2
//
//  Created by Cafe Swift on 05/11/2025.
//

import Foundation
import SwiftUI
import Combine

@MainActor
@Observable
final class ProducerHomeViewModel {
    // MARK: - Published Properties
    var isLoading: Bool = false
    var errorMessage: String?
    var showError: Bool = false
    var recentDiagnoses: [DiagnosisRecord] = []
    var userProfile: UserProfile
    
    // MARK: - Services
    private(set) var swiftDataService: SwiftDataService
    private let networkService: NetworkService
    
    // MARK: - Initialization
    init(user: UserProfile, swiftDataService: SwiftDataService, networkService: NetworkService? = nil) {
        self.userProfile = user
        self.swiftDataService = swiftDataService
        self.networkService = networkService ?? NetworkService.shared
    }
    
    // MARK: - Methods
    
    /// Load user profile and recent diagnoses
    func loadData() {
        Task {
            isLoading = true
            defer { isLoading = false }
            
            do {
                // Load recent diagnoses (last 5) for THIS specific user
                recentDiagnoses = try swiftDataService.fetchDiagnosisHistory(for: userProfile, limit: 5)
            } catch {
                showErrorMessage("Error al cargar datos: \(error.localizedDescription)")
            }
        }
    }
    
    /// Sync data with backend when connection is available
    func syncDataIfPossible() {
        Task {
            do {
                // Get unsynced diagnoses for THIS specific user
                let unsyncedDiagnoses = recentDiagnoses.filter { !$0.isSynced }
                
                guard !unsyncedDiagnoses.isEmpty else { return }
                
                // Convert to sync format
                let syncData: [DiagnosisSyncData] = unsyncedDiagnoses.map { record in
                    DiagnosisSyncData(
                        timestamp: record.timestamp,
                        detectedIssue: record.detectedIssue,
                        confidence: record.confidence,
                        userFeedbackCorrect: record.userFeedbackCorrect,
                        location: nil
                    )
                }
                
                // Attempt to sync
                try await networkService.syncDiagnosisData(syncData)
                
                // Mark as synced
                for diagnosis in unsyncedDiagnoses {
                    try swiftDataService.markDiagnosisAsSynced(diagnosis)
                }
                
                print("✅ Datos sincronizados exitosamente")
            } catch {
                // Sync failure is not critical - app works offline
                print("⚠️ No se pudo sincronizar (esperado en modo offline): \(error.localizedDescription)")
            }
        }
    }
    
    /// Get greeting message based on time of day
    func getGreeting() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        let displayName = userProfile.displayName ?? extractNameFromUserName(userProfile.userName)
        
        switch hour {
        case 0..<12:
            return "Buenos días, \(displayName)"
        case 12..<18:
            return "Buenas tardes, \(displayName)"
        default:
            return "Buenas noches, \(displayName)"
        }
    }
    
    /// Extrae el nombre del formato "nombre@device-id"
    private func extractNameFromUserName(_ userName: String) -> String {
        if let atIndex = userName.firstIndex(of: "@") {
            return String(userName[..<atIndex])
        }
        return userName
    }
    
    /// Get summary statistics
    func getTotalDiagnoses() -> Int {
        do {
            return try swiftDataService.fetchDiagnosisHistory(for: userProfile, limit: 1000).count
        } catch {
            return 0
        }
    }
    
    func getPendingTasks() -> Int {
        return recentDiagnoses.reduce(0) { total, diagnosis in
            total + (diagnosis.actionPlanItems?.filter { !$0.isCompleted }.count ?? 0)
        }
    }
    
    // MARK: - Private Helpers
    
    private func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true
    }
}
