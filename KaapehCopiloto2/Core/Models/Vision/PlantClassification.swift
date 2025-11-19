//
//  PlantClassification.swift
//  KaapehCopiloto2
//
//  Modelos estructurados para clasificación de enfermedades de café
//

import Foundation
import FoundationModels

// MARK: - Classification Result (Core ML Output)

/// Resultado de clasificación del Core ML model
struct PlantClassificationResult: Codable, Equatable {
    /// Etiqueta de la enfermedad detectada
    let label: String
    
    /// Confianza de la predicción (0.0 - 1.0)
    let confidence: Double
    
    /// Bounding box de la región afectada [x, y, width, height]
    let boundingBox: [Double]?
    
    /// Timestamp de la clasificación
    let timestamp: Date
    
    init(label: String, confidence: Double, boundingBox: [Double]? = nil) {
        self.label = label
        self.confidence = confidence
        self.boundingBox = boundingBox
        self.timestamp = Date()
    }
}

// MARK: - @Generable Response (LLM Output)

/// Respuesta estructurada del asistente sobre diagnóstico de plantas
@Generable
struct PlantDiagnosisResponse: Equatable {
    /// Enfermedad identificada
    @Guide(description: "El nombre de la enfermedad o condición detectada en la planta de café")
    var detectedCondition: String
    
    /// Nivel de confianza en el diagnóstico
    @Guide(description: "Confianza del diagnóstico de 0.0 a 1.0")
    var confidence: Double
    
    /// Descripción de la enfermedad
    @Guide(description: "Explicación breve de qué es esta enfermedad y cómo se manifiesta")
    var description: String
    
    /// Tratamientos recomendados
    @Guide(description: "Lista de 2-4 tratamientos agroecológicos recomendados por Káapeh")
    var treatments: [String]
    
    /// Medidas preventivas
    @Guide(description: "Lista de 2-3 medidas para prevenir esta enfermedad")
    var preventiveMeasures: [String]
    
    /// Gravedad de la situación
    @Guide(description: "Nivel de urgencia: 'baja', 'media', 'alta'")
    var severity: String
    
    /// Fuentes de información consultadas
    @Guide(description: "Lista de documentos o manuales usados como referencia")
    var sources: [String]
}

// MARK: - Disease Categories

/// Categorías de enfermedades que el modelo puede detectar
enum CoffeeDiseaseCategory: String, CaseIterable, Codable {
    case roya = "Roya del Café"
    case broca = "Broca del Café"
    case cercospora = "Ojo de Gallo (Cercospora)"
    case nitrogenDeficiency = "Deficiencia de Nitrógeno"
    case healthy = "Planta Sana"
    case unknown = "No Identificado"
    
    var emoji: String {
        switch self {
        case .roya: return "🍂"
        case .broca: return "🐛"
        case .cercospora: return "👁️"
        case .nitrogenDeficiency: return "🟡"
        case .healthy: return "✅"
        case .unknown: return "❓"
        }
    }
    
    var searchKeywords: [String] {
        switch self {
        case .roya:
            return ["roya", "hemileia", "óxido", "polvillo"]
        case .broca:
            return ["broca", "hypothenemus", "gusano", "taladro"]
        case .cercospora:
            return ["cercospora", "ojo de gallo", "mancha circular"]
        case .nitrogenDeficiency:
            return ["nitrógeno", "amarillamiento", "clorosis", "deficiencia"]
        case .healthy:
            return ["sana", "saludable", "verde"]
        case .unknown:
            return []
        }
    }
}

// MARK: - Image Analysis Arguments

/// Argumentos para el tool de análisis de imágenes
@Generable
struct ImageAnalysisArguments: Equatable {
    /// ID único de la imagen a analizar
    @Guide(description: "El identificador único de la imagen que el usuario quiere analizar")
    var imageID: String
}

// MARK: - Diagnostic Record (SwiftData)

/// Registro histórico de diagnósticos (para SwiftData)
struct DiagnosticHistoryEntry: Codable, Identifiable {
    let id: UUID
    let date: Date
    let diseaseDetected: String
    let confidence: Double
    let imageData: Data?
    let treatments: [String]
    let userNotes: String?
    
    init(
        id: UUID = UUID(),
        date: Date = Date(),
        diseaseDetected: String,
        confidence: Double,
        imageData: Data? = nil,
        treatments: [String] = [],
        userNotes: String? = nil
    ) {
        self.id = id
        self.date = date
        self.diseaseDetected = diseaseDetected
        self.confidence = confidence
        self.imageData = imageData
        self.treatments = treatments
        self.userNotes = userNotes
    }
}

// MARK: - Helper Extensions

extension PlantClassificationResult {
    /// Categoriza el resultado en una enfermedad conocida
    var diseaseCategory: CoffeeDiseaseCategory {
        let lowercaseLabel = label.lowercased()
        
        for category in CoffeeDiseaseCategory.allCases {
            for keyword in category.searchKeywords {
                if lowercaseLabel.contains(keyword) {
                    return category
                }
            }
        }
        
        return .unknown
    }
    
    /// Indica si la confianza es suficientemente alta (>70%)
    var isConfident: Bool {
        confidence >= 0.70
    }
    
    /// Indicador de confianza en texto
    var confidenceLevel: String {
        switch confidence {
        case 0.9...:
            return "Muy alta"
        case 0.75..<0.9:
            return "Alta"
        case 0.6..<0.75:
            return "Media"
        default:
            return "Baja"
        }
    }
}

extension PlantDiagnosisResponse {
    /// Crea una respuesta de diagnóstico desde un resultado de clasificación
    static func from(
        classification: PlantClassificationResult,
        description: String,
        treatments: [String],
        preventiveMeasures: [String],
        sources: [String]
    ) -> PlantDiagnosisResponse {
        let severity: String
        if classification.confidence >= 0.85 {
            severity = classification.label.lowercased().contains("sana") ? "baja" : "alta"
        } else if classification.confidence >= 0.70 {
            severity = "media"
        } else {
            severity = "baja"
        }
        
        return PlantDiagnosisResponse(
            detectedCondition: classification.diseaseCategory.rawValue,
            confidence: classification.confidence,
            description: description,
            treatments: treatments,
            preventiveMeasures: preventiveMeasures,
            severity: severity,
            sources: sources
        )
    }
}
