//
//  DiagnosePlantIntent.swift
//  KaapehCopiloto2
//
//  App Intent para diagnóstico de plantas vía Siri
//
//

import AppIntents
import SwiftUI

/// Intent para iniciar diagnóstico de planta desde Siri
struct DiagnosePlantIntent: AppIntent {
    // MARK: - Metadata
    
    static var title: LocalizedStringResource = "Diagnosticar Planta de Café"
    
    static var description = IntentDescription(
        """
        Inicia un diagnóstico de planta de café usando la cámara y análisis de IA. \
        El asistente te guiará para tomar una foto y te dará recomendaciones de tratamiento.
        """
    )
    
    static var openAppWhenRun: Bool = true
    
    // MARK: - Parameters
    
    // Opcional: El usuario puede especificar qué tipo de análisis quiere
    @Parameter(title: "Tipo de Análisis")
    var analysisType: AnalysisTypeEnum?
    
    // MARK: - Perform
    
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        // Notificar al sistema que se debe abrir la vista de diagnóstico
        NotificationCenter.default.post(
            name: .startDiagnosisFromIntent,
            object: nil,
            userInfo: ["analysisType": analysisType?.rawValue ?? "general"]
        )
        
        // Mensaje de confirmación para Siri
        let dialog = IntentDialog(
            "Abriendo Káapeh Copiloto para diagnosticar tu planta. Prepara la cámara para tomar una foto."
        )
        
        return .result(dialog: dialog)
    }
}

/// Tipos de análisis disponibles
enum AnalysisTypeEnum: String, AppEnum {
    case general = "General"
    case disease = "Enfermedad"
    case nutrient = "Nutrición"
    case health = "Salud General"
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Tipo de Análisis"
    
    static var caseDisplayRepresentations: [AnalysisTypeEnum: DisplayRepresentation] = [
        .general: "Análisis General",
        .disease: "Detectar Enfermedad",
        .nutrient: "Deficiencia de Nutrientes",
        .health: "Evaluación de Salud"
    ]
}

// MARK: - Notification Extension

extension Notification.Name {
    static let startDiagnosisFromIntent = Notification.Name("startDiagnosisFromIntent")
}
