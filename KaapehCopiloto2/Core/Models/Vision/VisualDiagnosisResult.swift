//
//  VisualDiagnosisResult.swift
//  KaapehCopiloto2
//
//  Resultado del análisis visual de plantas
//

import Foundation
import FoundationModels

/// Resultado de la clasificación visual de enfermedades de plantas
@Generable
struct VisualDiagnosisResult: Equatable {
    @Guide(description: "Nombre de la enfermedad o condición detectada (ej: 'Roya del café', 'Deficiencia de nitrógeno').")
    var label: String
    
    @Guide(description: "Nivel de confianza de 0.0 a 1.0")
    var confidence: Double
    
    @Guide(description: "Descripción visual breve de lo que se observa en la imagen.")
    var visualDescription: String
    
    @Guide(description: "Severidad: 'leve', 'moderada', 'severa' o 'ninguna'")
    var severity: String
    
    @Guide(description: "Acción inmediata que el caficultor debe tomar hoy.")
    var immediateAction: String
}

extension VisualDiagnosisResult {
    /// Badge de severidad con color
    var severityBadge: (color: String, emoji: String) {
        switch severity.lowercased() {
        case "severa":
            return ("red", "🔴")
        case "moderada":
            return ("orange", "🟠")
        case "leve":
            return ("yellow", "🟡")
        default: // "ninguna" o sana
            return ("green", "🟢")
        }
    }
}
