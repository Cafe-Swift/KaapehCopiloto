//
//  DiagnosisRecord.swift
//  KaapehCopiloto
//
//  Created by Marco Antonio Torres Ramirez on 27/10/25.
//

import Foundation
import SwiftData

@Model
final class DiagnosisRecord {
    var recordId: UUID
    var timestamp: Date
    var imagePath: String? // Ruta local de la imagen
    var detectedIssue: String
    var confidence: Double
    var userFeedbackCorrect: Bool? // Feedback del usuario sobre la precisión del diagnóstico
    var userCorrectedIssue: String? // Diagnóstico corregido por el usuario
    var aiExplanation: String? // Explicación del diagnóstico generado por IA
    
    var userProfile: UserProfile?
    
    @Relationship(deleteRule: .cascade, inverse: \ActionItem.diagnosisRecord)
    var actionPlanItems: [ActionItem]?
    
    init(detectedIssue: String, confidence: Double, imagePath: String? = nil) {
        self.recordId = UUID()
        self.timestamp = Date()
        self.detectedIssue = detectedIssue
        self.confidence = confidence
        self.imagePath = imagePath
        self.actionPlanItems = []
    }
}
