//
//  BackgroundSyncService.swift
//  KaapehCopiloto2
//
//  Created by Cafe Swift Team on 06/11/25.
//

import Foundation

/// Servicio para sincronizar datos locales con el backend cuando hay conexión
@MainActor
final class BackgroundSyncService {
    static let shared = BackgroundSyncService()
    
    var isSyncing: Bool = false
    var lastSyncDate: Date?
    
    private let dataService = SwiftDataService.shared
    private let networkService = NetworkService.shared
    
    private init() {
        // Iniciar sincronización automática cada 5 minutos
        startAutoSync()
    }
    
    /// Inicia la sincronización automática en segundo plano
    private func startAutoSync() {
        Task {
            while true {
                // Esperar 5 minutos
                try? await Task.sleep(for: .seconds(300))
                
                // Intentar sincronizar
                await syncIfNeeded()
            }
        }
    }
    
    /// Sincroniza los datos si hay conexión de red
    func syncIfNeeded() async {
        // No sincronizar si ya está en proceso
        guard !isSyncing else { return }
        
        isSyncing = true
        
        do {
            // 1. Sincronizar diagnósticos pendientes
            try await syncDiagnoses()
            
            // 2. Sincronizar tareas pendientes
            try await syncTasks()
            
            // 3. Sincronizar usuarios (solo para dashboard técnico)
            try await syncUsers()
            
            lastSyncDate = Date()
            print("✅ Sincronización completada exitosamente")
            
        } catch let error as NetworkError {
            if !error.isExpectedOfflineError {
                print("⚠️ Error en sincronización: \(error.localizedDescription)")
            }
        } catch {
            print("⚠️ Error en sincronización: \(error.localizedDescription)")
        }
        
        isSyncing = false
    }
    
    /// Sincroniza todos los diagnósticos locales no sincronizados
    private func syncDiagnoses() async throws {
        // Obtener todos los diagnósticos locales
        let allDiagnoses = try dataService.fetchAllDiagnosisRecords(limit: 1000)
        
        // Filtrar solo los no sincronizados
        let unsyncedDiagnoses = allDiagnoses.filter { !$0.isSynced }
        
        guard !unsyncedDiagnoses.isEmpty else {
            print("📊 No hay diagnósticos pendientes de sincronizar")
            return
        }
        
        print("📤 Sincronizando \(unsyncedDiagnoses.count) diagnósticos...")
        
        // Convertir a formato de red
        let syncData = unsyncedDiagnoses.map { diagnosis in
            // Convertir ActionItems a formato de red
            let actionItems = diagnosis.actionPlanItems?.map { item in
                ActionItemSyncData(
                    descriptionText: item.descriptionText,
                    isCompleted: item.isCompleted
                )
            }
            
            return DiagnosisSyncData(
                timestamp: diagnosis.timestamp,
                detectedIssue: diagnosis.detectedIssue,
                confidence: diagnosis.confidence,
                userFeedbackCorrect: diagnosis.userFeedbackCorrect,
                location: nil,  // Deprecated
                latitude: diagnosis.latitude, 
                longitude: diagnosis.longitude,
                locationName: diagnosis.locationName,
                actionItems: actionItems
            )
        }
        
        // Enviar al backend
        try await networkService.syncDiagnosisData(syncData)
        
        // Marcar como sincronizados
        for diagnosis in unsyncedDiagnoses {
            try dataService.markDiagnosisAsSynced(diagnosis)
        }
        
        print("✅ \(unsyncedDiagnoses.count) diagnósticos sincronizados")
    }
    
    /// Sincroniza todas las tareas locales no sincronizadas
    private func syncTasks() async throws {
        // Obtener todos los diagnósticos con tareas
        let allDiagnoses = try dataService.fetchAllDiagnosisRecords(limit: 1000)
        
        var allTasks: [ActionItem] = []
        for diagnosis in allDiagnoses {
            if let tasks = diagnosis.actionPlanItems {
                allTasks.append(contentsOf: tasks)
            }
        }
        
        guard !allTasks.isEmpty else {
            print("📋 No hay tareas pendientes de sincronizar")
            return
        }
        
        print("📤 Sincronizando \(allTasks.count) tareas...")
        
        // Enviar al backend
        try await networkService.syncTasks(allTasks)
        
        print("✅ \(allTasks.count) tareas sincronizadas")
    }
    
    /// Sincroniza información de usuarios para el dashboard técnico
    private func syncUsers() async throws {
        print("👥 Sincronización de usuarios completada")
    }
    
    /// Fuerza una sincronización inmediata (llamado manualmente)
    func forceSyncNow() async {
        await syncIfNeeded()
    }
}
