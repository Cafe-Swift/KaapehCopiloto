//
//  DiagnosisFlowTests.swift
//  KaapehCopiloto2Tests
//
//  Created by Test Suite on 23/11/25.
//

import Testing
import Foundation
import SwiftData
@testable import KaapehCopiloto2

@MainActor
struct DiagnosisFlowTests {
    
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
    
    @Test("Complete diagnosis flow from creation to feedback")
    func testCompleteDiagnosisFlow() throws {
        // Given
        let profile = try service.createUserProfile(
            userName: "test_user",
            role: "Productor",
            language: "es"
        )
        
        // When - Step 1: Create diagnosis
        let diagnosis = try service.createDiagnosisRecord(
            for: profile,
            detectedIssue: "Roya del Café",
            confidence: 0.95
        )
        
        // Then - Verify initial state
        #expect(diagnosis.detectedIssue == "Roya del Café")
        #expect(diagnosis.confidence == 0.95)
        #expect(diagnosis.userFeedbackCorrect == nil)
        #expect(!diagnosis.isSynced)
        
        // When - Step 2: User provides feedback
        try service.updateDiagnosisFeedback(
            record: diagnosis,
            isCorrect: true,
            correctedIssue: nil
        )
        
        // Then - Verify feedback recorded
        #expect(diagnosis.userFeedbackCorrect == true)
        
        // When - Step 3: Mark as synced
        try service.markDiagnosisAsSynced(diagnosis)
        
        // Then - Verify sync status
        #expect(diagnosis.isSynced == true)
    }
    
    @Test("Diagnosis with incorrect feedback and correction")
    func testDiagnosisWithCorrection() throws {
        // Given
        let profile = try service.createUserProfile(
            userName: "test_user",
            role: "Productor",
            language: "es"
        )
        
        let diagnosis = try service.createDiagnosisRecord(
            for: profile,
            detectedIssue: "Deficiencia de Nitrógeno",
            confidence: 0.75
        )
        
        // When - User says it's wrong and provides correction
        try service.updateDiagnosisFeedback(
            record: diagnosis,
            isCorrect: false,
            correctedIssue: "Deficiencia de Potasio"
        )
        
        // Then
        #expect(diagnosis.userFeedbackCorrect == false)
        #expect(diagnosis.userCorrectedIssue == "Deficiencia de Potasio")
    }
    
    @Test("Multiple diagnoses for same user")
    func testMultipleDiagnoses() throws {
        // Given
        let profile = try service.createUserProfile(
            userName: "test_user",
            role: "Productor",
            language: "es"
        )
        
        // When - Create multiple diagnoses
        let issues = ["Roya del Café", "Planta Sana", "Deficiencia de Nitrógeno"]
        var diagnoses: [DiagnosisRecord] = []
        
        for issue in issues {
            let diagnosis = try service.createDiagnosisRecord(
                for: profile,
                detectedIssue: issue,
                confidence: Double.random(in: 0.7...0.95)
            )
            diagnoses.append(diagnosis)
        }
        
        // Then
        let history = try service.fetchDiagnosisHistory(for: profile, limit: 10)
        #expect(history.count == 3)
        #expect(diagnoses.allSatisfy { $0.userProfile?.userId == profile.userId })
    }
    
    @Test("Diagnosis confidence levels")
    func testDiagnosisConfidenceLevels() throws {
        // Given
        let profile = try service.createUserProfile(
            userName: "test_user",
            role: "Productor",
            language: "es"
        )
        
        let confidenceLevels = [0.5, 0.7, 0.85, 0.95]
        
        for confidence in confidenceLevels {
            // When
            let diagnosis = try service.createDiagnosisRecord(
                for: profile,
                detectedIssue: "Test Issue",
                confidence: confidence
            )
            
            // Then
            #expect(diagnosis.confidence == confidence)
            #expect(diagnosis.confidence >= 0.0 && diagnosis.confidence <= 1.0)
        }
    }
    
    @Test("Diagnosis history ordering")
    func testDiagnosisHistoryOrdering() async throws {
        // Given
        let profile = try service.createUserProfile(
            userName: "test_user",
            role: "Productor",
            language: "es"
        )
        
        // When - Create diagnoses in sequence
        _ = try service.createDiagnosisRecord(
            for: profile,
            detectedIssue: "First",
            confidence: 0.9
        )
        
        // Wait a tiny bit to ensure different timestamps
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        _ = try service.createDiagnosisRecord(
            for: profile,
            detectedIssue: "Second",
            confidence: 0.9
        )
        
        // Then - Most recent should be first
        let history = try service.fetchDiagnosisHistory(for: profile, limit: 10)
        #expect(history.first?.detectedIssue == "Second")
        #expect(history.last?.detectedIssue == "First")
    }
    
    @Test("Diagnosis metrics calculation with mixed feedback")
    func testMetricsWithMixedFeedback() throws {
        // Given
        let profile = try service.createUserProfile(
            userName: "test_user",
            role: "Productor",
            language: "es"
        )
        
        // Create 10 diagnoses with 70% correct feedback
        for i in 0..<10 {
            let diagnosis = try service.createDiagnosisRecord(
                for: profile,
                detectedIssue: "Issue \(i)",
                confidence: 0.9
            )
            
            let isCorrect = i < 7 // First 7 are correct
            try service.updateDiagnosisFeedback(
                record: diagnosis,
                isCorrect: isCorrect
            )
        }
        
        // When
        let tpp = try service.calculateTPP()
        
        // Then - Should be 70%
        #expect(tpp >= 69.0 && tpp <= 71.0)
    }
}
