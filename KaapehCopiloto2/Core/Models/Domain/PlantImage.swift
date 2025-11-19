//
//  PlantImage.swift
//  KaapehCopiloto2
//
//  Modelo para gestión de imágenes de plantas
//

import Foundation
import SwiftData
import UIKit

@Model
final class PlantImage {
    var id: String
    var imageData: Data? // Imagen comprimida
    var thumbnailData: Data? // Thumbnail para UI rápida
    var timestamp: Date
    
    // Metadata de captura
    var captureMethod: String // "camera", "library", "shared"
    var location: String? // Ubicación del cafetal (si el usuario la proporciona)
    
    // Resultados de análisis (si ya fue procesada)
    var isAnalyzed: Bool
    var diagnosisLabel: String? // "Roya del Café", "Sana", etc.
    var confidence: Double?
    var severity: String? // "leve", "moderada", "severa"
    
    // Relacionado con chat
    var associatedMessageID: UUID? // ID del ChatMessage que la usó
    
    init(
        id: String = UUID().uuidString,
        imageData: Data? = nil,
        thumbnailData: Data? = nil,
        captureMethod: String = "camera",
        location: String? = nil
    ) {
        self.id = id
        self.imageData = imageData
        self.thumbnailData = thumbnailData
        self.timestamp = Date()
        self.captureMethod = captureMethod
        self.location = location
        self.isAnalyzed = false
    }
}

// MARK: - Helper Extensions
extension PlantImage {
    /// Convierte Data a UIImage
    var uiImage: UIImage? {
        guard let data = imageData else { return nil }
        return UIImage(data: data)
    }
    
    /// Thumbnail como UIImage
    var thumbnailImage: UIImage? {
        guard let data = thumbnailData else { return nil }
        return UIImage(data: data)
    }
    
    /// Tamaño del archivo en MB
    var sizeInMB: Double {
        guard let data = imageData else { return 0 }
        return Double(data.count) / 1_048_576.0 // 1024 * 1024
    }
    
    /// Marca la imagen como analizada con resultados
    func markAsAnalyzed(label: String, confidence: Double, severity: String) {
        self.isAnalyzed = true
        self.diagnosisLabel = label
        self.confidence = confidence
        self.severity = severity
    }
    
    /// Badge de estado para UI
    var statusBadge: (emoji: String, text: String) {
        if !isAnalyzed {
            return ("⏳", "Pendiente")
        }
        
        guard let label = diagnosisLabel else {
            return ("❓", "Sin diagnóstico")
        }
        
        if label.lowercased().contains("sana") {
            return ("✅", "Planta Sana")
        } else if label.lowercased().contains("roya") {
            return ("🍂", "Roya detectada")
        } else if label.lowercased().contains("deficiencia") {
            return ("🌱", "Deficiencia nutricional")
        } else {
            return ("🔍", label)
        }
    }
}

// MARK: - Image Compression Helper
extension PlantImage {
    /// Crea una PlantImage desde UIImage con compresión automática
    static func from(
        uiImage: UIImage,
        captureMethod: String = "camera",
        location: String? = nil,
        compressionQuality: CGFloat = 0.7
    ) -> PlantImage? {
        // Comprimir imagen principal
        guard let imageData = uiImage.jpegData(compressionQuality: compressionQuality) else {
            return nil
        }
        
        // Crear thumbnail (300x300 max)
        let thumbnailSize = CGSize(width: 300, height: 300)
        let thumbnail = uiImage.preparingThumbnail(of: thumbnailSize)
        let thumbnailData = thumbnail?.jpegData(compressionQuality: 0.5)
        
        let plantImage = PlantImage(
            imageData: imageData,
            thumbnailData: thumbnailData,
            captureMethod: captureMethod,
            location: location
        )
        
        return plantImage
    }
}
