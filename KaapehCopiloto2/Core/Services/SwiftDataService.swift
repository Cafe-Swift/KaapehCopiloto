//
//  SwiftDataService.swift
//  KaapehCopiloto2
//
//  Created by Cafe Swift Team on 05/11/25.
//

import Foundation
import SwiftData

/// Servicio centralizado para gestionar operaciones de SwiftData
@MainActor
final class SwiftDataService {
    static let shared = SwiftDataService()
    
    private(set) var modelContainer: ModelContainer?
    private(set) var modelContext: ModelContext?
    
    private init() {}
    
    /// Inicializador público para inyección de dependencias
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.modelContainer = modelContext.container
    }
    
    /// Configura el servicio con un contenedor existente
    func configure(with container: ModelContainer) {
        self.modelContainer = container
        self.modelContext = ModelContext(container)
        self.modelContext?.autosaveEnabled = true
    }
    
    // MARK: - User Profile Operations
    
    /// Crea un nuevo perfil de usuario
    func createUserProfile(userName: String, role: String, language: String) throws -> UserProfile {
        guard let context = modelContext else {
            throw DataServiceError.contextNotAvailable
        }
        
        let profile = UserProfile(
            userName: userName,
            role: role,
            preferredLanguage: language
        )
        
        let accessibilityConfig = AccessibilityConfig()
        profile.accessibilitySettings = accessibilityConfig
        
        context.insert(profile)
        
        try context.save()
        
        return profile
    }
    
    /// Obtiene el perfil del usuario actual
    func fetchCurrentUserProfile() throws -> UserProfile? {
        guard let context = modelContext else {
            throw DataServiceError.contextNotAvailable
        }
        
        let descriptor = FetchDescriptor<UserProfile>(
            sortBy: [SortDescriptor(\.lastLoginAt, order: .reverse)]
        )
        
        let profiles = try context.fetch(descriptor)
        return profiles.first
    }
    
    /// Método alternativo para obtener el perfil actual (alias)
    func getCurrentUserProfile() throws -> UserProfile? {
        return try fetchCurrentUserProfile()
    }
    
    /// Obtiene todos los perfiles de usuario (para autenticación offline)
    func fetchAllUserProfiles() throws -> [UserProfile] {
        guard let context = modelContext else {
            throw DataServiceError.contextNotAvailable
        }
        
        let descriptor = FetchDescriptor<UserProfile>(
            sortBy: [SortDescriptor(\.lastLoginAt, order: .reverse)]
        )
        
        return try context.fetch(descriptor)
    }
    
    /// Actualiza la configuración de accesibilidad
    func updateAccessibilityConfig(
        for profile: UserProfile,
        largeText: Bool? = nil,
        highContrast: Bool? = nil,
        voicePreferred: Bool? = nil,
        onboardingCompleted: Bool? = nil
    ) throws {
        guard let context = modelContext else {
            throw DataServiceError.contextNotAvailable
        }
        
        if profile.accessibilitySettings == nil {
            let config = AccessibilityConfig()
            profile.accessibilitySettings = config
        }
        
        if let largeText = largeText {
            profile.accessibilitySettings?.largeTextEnabled = largeText
        }
        if let highContrast = highContrast {
            profile.accessibilitySettings?.highContrastEnabled = highContrast
        }
        if let voicePreferred = voicePreferred {
            profile.accessibilitySettings?.voiceInteractionPreferred = voicePreferred
        }
        if let onboardingCompleted = onboardingCompleted {
            profile.accessibilitySettings?.onboardingCompleted = onboardingCompleted
        }
        
        try context.save()
    }
    
    // MARK: - Diagnosis Operations
    
    /// Crea un nuevo registro de diagnóstico
    func createDiagnosisRecord(
        for profile: UserProfile,
        detectedIssue: String,
        confidence: Double,
        imagePath: String? = nil
    ) throws -> DiagnosisRecord {
        guard let context = modelContext else {
            throw DataServiceError.contextNotAvailable
        }
        
        let record = DiagnosisRecord(
            imagePath: imagePath,
            detectedIssue: detectedIssue,
            confidence: confidence
        )
        
        context.insert(record)
        
        try context.save()
        
        return record
    }
    
    /// Actualiza el feedback del usuario en un diagnóstico
    func updateDiagnosisFeedback(
        record: DiagnosisRecord,
        isCorrect: Bool,
        correctedIssue: String? = nil
    ) throws {
        guard let context = modelContext else {
            throw DataServiceError.contextNotAvailable
        }
        
        record.userFeedbackCorrect = isCorrect
        record.userCorrectedIssue = correctedIssue
        
        try context.save()
    }
    
    /// Obtiene el historial de diagnósticos de un usuario
    func fetchDiagnosisHistory(for profile: UserProfile, limit: Int = 50) throws -> [DiagnosisRecord] {
        guard let context = modelContext else {
            throw DataServiceError.contextNotAvailable
        }
        
        var descriptor = FetchDescriptor<DiagnosisRecord>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        
        descriptor.fetchLimit = limit
        
        return try context.fetch(descriptor)
    }
    
    /// Obtiene todos los diagnósticos sin filtrar por usuario
    func fetchAllDiagnosisRecords(limit: Int = 100) throws -> [DiagnosisRecord] {
        guard let context = modelContext else {
            throw DataServiceError.contextNotAvailable
        }
        
        var descriptor = FetchDescriptor<DiagnosisRecord>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        
        descriptor.fetchLimit = limit
        
        return try context.fetch(descriptor)
    }
    
    // MARK: - Action Items Operations
    
    /// Crea items de acción para un diagnóstico
    func createActionItems(for diagnosis: DiagnosisRecord, descriptions: [String]) throws {
        guard let context = modelContext else {
            throw DataServiceError.contextNotAvailable
        }
        
        for description in descriptions {
            let item = ActionItem(descriptionText: description)
            context.insert(item)
        }
        
        try context.save()
    }
    
    /// Marca un item de acción como completado
    func toggleActionItemCompletion(item: ActionItem) throws {
        guard let context = modelContext else {
            throw DataServiceError.contextNotAvailable
        }
        
        item.isCompleted.toggle()
        try context.save()
    }
    
    /// Marca un diagnóstico como sincronizado con el backend
    func markDiagnosisAsSynced(_ diagnosis: DiagnosisRecord) throws {
        guard let context = modelContext else {
            throw DataServiceError.contextNotAvailable
        }
        
        diagnosis.isSynced = true
        try context.save()
    }
    
    // MARK: - Metrics (for Technician Dashboard)
    
    /// Calcula la Tasa de Precisión Percibida (TPP)
    func calculateTPP() throws -> Double {
        guard let context = modelContext else {
            throw DataServiceError.contextNotAvailable
        }
        
        let descriptor = FetchDescriptor<DiagnosisRecord>(
            predicate: #Predicate { record in
                record.userFeedbackCorrect != nil
            }
        )
        
        let recordsWithFeedback = try context.fetch(descriptor)
        
        guard !recordsWithFeedback.isEmpty else { return 0.0 }
        
        let correctCount = recordsWithFeedback.filter { $0.userFeedbackCorrect == true }.count
        return Double(correctCount) / Double(recordsWithFeedback.count) * 100.0
    }
    
    /// Calcula la Confiabilidad Promedio del Modelo (CPM)
    func calculateCPM() throws -> Double {
        guard let context = modelContext else {
            throw DataServiceError.contextNotAvailable
        }
        
        let descriptor = FetchDescriptor<DiagnosisRecord>()
        let allRecords = try context.fetch(descriptor)
        
        guard !allRecords.isEmpty else { return 0.0 }
        
        let totalConfidence = allRecords.reduce(0.0) { $0 + $1.confidence }
        return (totalConfidence / Double(allRecords.count)) * 100.0
    }
}

// MARK: - Error Types

enum DataServiceError: LocalizedError {
    case configurationFailed(Error)
    case contextNotAvailable
    case saveFailed(Error)
    case fetchFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .configurationFailed(let error):
            return "Failed to configure SwiftData: \(error.localizedDescription)"
        case .contextNotAvailable:
            return "SwiftData context is not available"
        case .saveFailed(let error):
            return "Failed to save data: \(error.localizedDescription)"
        case .fetchFailed(let error):
            return "Failed to fetch data: \(error.localizedDescription)"
        }
    }
}
