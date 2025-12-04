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

    var userProfile: UserProfile?
    
    @Relationship(deleteRule: .cascade)
    var actionPlanItems: [ActionItem]?
    
    // MARK: - Ubicación Geográfica
    /// Latitud de donde se tomó el diagnóstico
    var latitude: Double?
    
    /// Longitud de donde se tomó el diagnóstico
    var longitude: Double?
    
    /// Nombre del lugar (opcional) - e.g., "Parcela Norte", "Finca San José"
    var locationName: String?
    
    init(
        recordId: UUID = UUID(),
        timestamp: Date = Date(),
        imagePath: String? = nil,
        detectedIssue: String,
        confidence: Double,
        userFeedbackCorrect: Bool? = nil,
        userCorrectedIssue: String? = nil,
        aiExplanation: String? = nil,
        isSynced: Bool = false,
        userProfile: UserProfile? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        locationName: String? = nil
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
        self.userProfile = userProfile
        self.actionPlanItems = []
        self.latitude = latitude
        self.longitude = longitude
        self.locationName = locationName
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
    
    // MARK: - Ubicación Helpers
    
    /// Verifica si este diagnóstico tiene ubicación válida
    var hasLocation: Bool {
        guard let lat = latitude, let lon = longitude else { return false }
        // Validar que las coordenadas estén en rangos válidos
        return lat >= -90 && lat <= 90 && lon >= -180 && lon <= 180
    }
    
    /// Obtiene las coordenadas como tupla (para MapKit)
    var coordinates: (latitude: Double, longitude: Double)? {
        guard let lat = latitude, let lon = longitude, hasLocation else { return nil }
        return (lat, lon)
    }
    
    /// Descripción de la ubicación para mostrar al usuario
    var locationDescription: String {
        if let name = locationName, !name.isEmpty {
            return name
        } else if hasLocation {
            return String(format: "Lat: %.4f, Lon: %.4f", latitude!, longitude!)
        } else {
            return "Ubicación no disponible"
        }
    }
}
