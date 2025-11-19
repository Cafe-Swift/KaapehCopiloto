//
//  testt.swift
//  testt
//
//  Created by Marco Antonio Torres Ramirez on 11/11/25.
//

import Testing
import SwiftData
@testable import KaapehCopiloto2

@MainActor
struct SwiftDataServiceTests {
    
    var modelContainer: ModelContainer
    var context: ModelContext
    var service: SwiftDataService
    
    init() throws {
        let schema = Schema([
            UserProfile.self,
            AccessibilityConfig.self,
            DiagnosisRecord.self,
            ActionItem.self
        ])
        
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [config])
        context = ModelContext(modelContainer)
        service = SwiftDataService(modelContext: context)
    }
    
    // MARK: - User Profile Tests
    
    @Test("Create user profile successfully")
    func testCreateUserProfile() throws {
        // Given
        let username = "test_user"
        let role = "Productor"
        let language = "es"
        
        // When
        let profile = try service.createUserProfile(
            userName: username,
            role: role,
            language: language
        )
        
        // Then
        #expect(profile.userName == username)
        #expect(profile.role == role)
        #expect(profile.preferredLanguage == language)
        #expect(profile.accessibilitySettings != nil)
    }
    
    @Test("Fetch current user profile")
    func testFetchCurrentUserProfile() throws {
        // Given - Create a user first
        _ = try service.createUserProfile(
            userName: "test_user",
            role: "Productor",
            language: "es"
        )
        
        // When
        let fetchedProfile = try service.fetchCurrentUserProfile()
        
        // Then
        #expect(fetchedProfile != nil)
        #expect(fetchedProfile?.userName == "test_user")
    }
    
    @Test("Update accessibility config")
    func testUpdateAccessibilityConfig() throws {
        // Given
        let profile = try service.createUserProfile(
            userName: "test_user",
            role: "Productor",
            language: "es"
        )
        
        // When
        try service.updateAccessibilityConfig(
            for: profile,
            largeText: true,
            highContrast: true,
            voicePreferred: false,
            onboardingCompleted: true
        )
        
        // Then
        #expect(profile.accessibilitySettings?.largeTextEnabled == true)
        #expect(profile.accessibilitySettings?.highContrastEnabled == true)
        #expect(profile.accessibilitySettings?.voiceInteractionPreferred == false)
        #expect(profile.accessibilitySettings?.onboardingCompleted == true)
    }
    
    // MARK: - Diagnosis Tests
    
    @Test("Create diagnosis record")
    func testCreateDiagnosisRecord() throws {
        // Given
        let profile = try service.createUserProfile(
            userName: "test_user",
            role: "Productor",
            language: "es"
        )
        
        // When
        let diagnosis = try service.createDiagnosisRecord(
            for: profile,
            detectedIssue: "Roya del Café",
            confidence: 0.92
        )
        
        // Then
        #expect(diagnosis.detectedIssue == "Roya del Café")
        #expect(diagnosis.confidence == 0.92)
        #expect(diagnosis.userFeedbackCorrect == nil)
        #expect(diagnosis.isSynced == false)
    }
    
    @Test("Update diagnosis feedback")
    func testUpdateDiagnosisFeedback() throws {
        // Given
        let profile = try service.createUserProfile(
            userName: "test_user",
            role: "Productor",
            language: "es"
        )
        let diagnosis = try service.createDiagnosisRecord(
            for: profile,
            detectedIssue: "Roya del Café",
            confidence: 0.92
        )
        
        // When
        try service.updateDiagnosisFeedback(
            record: diagnosis,
            isCorrect: true,
            correctedIssue: nil
        )
        
        // Then
        #expect(diagnosis.userFeedbackCorrect == true)
        #expect(diagnosis.userCorrectedIssue == nil)
    }
    
    @Test("Fetch diagnosis history")
    func testFetchDiagnosisHistory() throws {
        // Given
        let profile = try service.createUserProfile(
            userName: "test_user",
            role: "Productor",
            language: "es"
        )
        
        // Create multiple diagnoses
        _ = try service.createDiagnosisRecord(
            for: profile,
            detectedIssue: "Roya del Café",
            confidence: 0.92
        )
        _ = try service.createDiagnosisRecord(
            for: profile,
            detectedIssue: "Planta Sana",
            confidence: 0.88
        )
        
        // When
        let history = try service.fetchDiagnosisHistory(for: profile, limit: 10)
        
        // Then
        #expect(history.count == 2)
    }
    
    // MARK: - Metrics Tests
    
    @Test("Calculate TPP with feedback")
    func testCalculateTPP() throws {
        // Given
        let profile = try service.createUserProfile(
            userName: "test_user",
            role: "Productor",
            language: "es"
        )
        
        // Create diagnoses with feedback
        let diagnosis1 = try service.createDiagnosisRecord(
            for: profile,
            detectedIssue: "Roya del Café",
            confidence: 0.92
        )
        try service.updateDiagnosisFeedback(record: diagnosis1, isCorrect: true)
        
        let diagnosis2 = try service.createDiagnosisRecord(
            for: profile,
            detectedIssue: "Planta Sana",
            confidence: 0.88
        )
        try service.updateDiagnosisFeedback(record: diagnosis2, isCorrect: true)
        
        let diagnosis3 = try service.createDiagnosisRecord(
            for: profile,
            detectedIssue: "Deficiencia de Nitrógeno",
            confidence: 0.75
        )
        try service.updateDiagnosisFeedback(record: diagnosis3, isCorrect: false)
        
        // When
        let tpp = try service.calculateTPP()
        
        // Then
        // 2 correct out of 3 = 66.67%
        #expect(tpp > 66.0)
        #expect(tpp < 67.0)
    }
    
    @Test("Calculate CPM")
    func testCalculateCPM() throws {
        // Given
        let profile = try service.createUserProfile(
            userName: "test_user",
            role: "Productor",
            language: "es"
        )
        
        _ = try service.createDiagnosisRecord(
            for: profile,
            detectedIssue: "Roya del Café",
            confidence: 0.90
        )
        _ = try service.createDiagnosisRecord(
            for: profile,
            detectedIssue: "Planta Sana",
            confidence: 0.80
        )
        
        // When
        let cpm = try service.calculateCPM()
        
        // Then
        // Average: (0.90 + 0.80) / 2 = 0.85 = 85%
        #expect(cpm == 85.0)
    }
    
    @Test("Mark diagnosis as synced")
    func testMarkDiagnosisAsSynced() throws {
        // Given
        let profile = try service.createUserProfile(
            userName: "test_user",
            role: "Productor",
            language: "es"
        )
        let diagnosis = try service.createDiagnosisRecord(
            for: profile,
            detectedIssue: "Roya del Café",
            confidence: 0.92
        )
        
        // When
        try service.markDiagnosisAsSynced(diagnosis)
        
        // Then
        #expect(diagnosis.isSynced == true)
    }
}

