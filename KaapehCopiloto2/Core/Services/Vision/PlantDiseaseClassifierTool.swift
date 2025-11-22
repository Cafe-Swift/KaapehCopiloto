//
//  PlantDiseaseClassifierTool.swift
//  KaapehCopiloto2
//
//  Tool para clasificación de enfermedades usando Core ML
//

import Foundation
import FoundationModels
import CoreML
import Vision
import UIKit

// MARK: - Image Provider Protocol

/// Protocolo para proveer imágenes al clasificador
protocol ImageProvider: Sendable {
    func getImage(id: String) async -> UIImage?
}

// MARK: - Plant Disease Classifier Tool

/// Tool de Foundation Models para clasificación de enfermedades de café
struct PlantDiseaseClassifierTool: Tool {
    let name = "classify_coffee_disease"
    
    let description = """
    Analiza una imagen de planta de café y detecta enfermedades.
    """
    
    private let imageProvider: ImageProvider
    private let minimumConfidence: Double
    
    init(imageProvider: ImageProvider, minimumConfidence: Double = 0.5) {
        self.imageProvider = imageProvider
        self.minimumConfidence = minimumConfidence
    }
    
    func call(arguments: ImageAnalysisArguments) async throws -> VisualDiagnosisResult {
        guard let image = await imageProvider.getImage(id: arguments.imageID) else {
            return VisualDiagnosisResult(
                label: "Error",
                confidence: 0.0,
                visualDescription: "No se pudo cargar la imagen.",
                severity: "ninguna",
                immediateAction: "Por favor, intenta tomar otra foto."
            )
        }
        
        let result = await classifyPlantDisease(image: image)
        return result
    }
    
    private func classifyPlantDisease(image: UIImage) async -> VisualDiagnosisResult {
        do {
            // Usar el servicio real de clasificación
            let classificationResult = try await CoffeeDiseaseClassifierService.shared.classify(image: image)
            return classificationResult.toVisualDiagnosisResult()
        } catch {
            // Retornar error si falla la clasificación
            return VisualDiagnosisResult(
                label: "Error en clasificación",
                confidence: 0.0,
                visualDescription: "No se pudo procesar la imagen. Error: \(error.localizedDescription)",
                severity: "ninguna",
                immediateAction: "Por favor, intenta tomar otra foto con mejor iluminación."
            )
        }
    }
}

// MARK: - Image Provider Implementation

actor SimpleImageProvider: ImageProvider {
    private var images: [String: UIImage] = [:]
    
    func storeImage(_ image: UIImage, id: String) {
        images[id] = image
    }
    
    func getImage(id: String) async -> UIImage? {
        return images[id]
    }
}
