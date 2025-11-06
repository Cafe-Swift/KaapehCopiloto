//
//  DiagnosisRecord.swift
//  KaapehCopiloto2
//
//  Created by Cafe Swift Team on 05/11/25.
//

import Foundation
import SwiftData

/// Diagnosis record model
@Model
final class DiagnosisRecord {
    var recordId: UUID
    var timestamp: Date
    var imagePath: String?
    var detectedIssue: String
    var confidence: Double
    var userFeedbackCorrect: Bool? // true = Sí, false = No, nil = Sin feedback
    var userCorrectedIssue: String?
    var aiExplanation: String?
    var isSynced: Bool // Track if synced to backend
    
    @Relationship(deleteRule: .cascade)
    var actionPlanItems: [ActionItem]?
    
    init(
        recordId: UUID = UUID(),
        timestamp: Date = Date(),
        imagePath: String? = nil,
        detectedIssue: String,
        confidence: Double,
        userFeedbackCorrect: Bool? = nil,
        userCorrectedIssue: String? = nil,
        aiExplanation: String? = nil,
        isSynced: Bool = false
    ) {
        self.recordId = recordId
        self.timestamp = timestamp
        self.imagePath = imagePath
        self.detectedIssue = detectedIssue
        self.confidence = confidence
        self.userFeedbackCorrect = userFeedbackCorrect
        self.userCorrectedIssue = userCorrectedIssue
        self.aiExplanation = aiExplanation
        self.isSynced = isSynced
        self.actionPlanItems = []
    }
    
    /// Get confidence as percentage string
    var confidencePercentage: String {
        String(format: "%.0f%%", confidence * 100)
    }
    
    /// Get formatted timestamp
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
    
    /// Update feedback
    func updateFeedback(isCorrect: Bool, correctedIssue: String? = nil) {
        self.userFeedbackCorrect = isCorrect
        self.userCorrectedIssue = correctedIssue
    }
    
    /// Mark as synced
    func markAsSynced() {
        self.isSynced = true
    }
    
    /// Check if has feedback
    var hasFeedback: Bool {
        userFeedbackCorrect != nil
    }
}
