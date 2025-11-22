//
//  DiagnosisViewModel.swift
//  KaapehCopiloto2
//
//  Created by Cafe Swift Team on 05/11/25.
//

import Foundation
import SwiftUI
import AVFoundation
import Combine

@MainActor
@Observable
final class DiagnosisViewModel {
    var user: UserProfile
    var selectedImage: UIImage?
    var isProcessing: Bool = false
    var currentDiagnosis: DiagnosisRecord?
    var errorMessage: String?
    
    private let dataService = SwiftDataService.shared
    
    init(user: UserProfile) {
        self.user = user
    }
    
    // MARK: - Image Processing
    
    func processImage(_ image: UIImage) async {
        isProcessing = true
        errorMessage = nil
        selectedImage = image
        
        print("📸 Procesando imagen con modelo CoreML...")
        
        do {
            // USAR EL CLASIFICADOR REAL DE COREML
            let classificationResult = try await CoffeeDiseaseClassifierService.shared.classify(image: image)
            
            print("✅ Clasificación completada:")
            print("   - Problema detectado: \(classificationResult.label)")
            print("   - Confianza: \(String(format: "%.2f%%", classificationResult.confidence * 100))")
            
            // Guardar el diagnóstico en SwiftData
            let diagnosis = try dataService.createDiagnosisRecord(
                for: user,
                detectedIssue: classificationResult.label,
                confidence: classificationResult.confidence,
                imagePath: nil // TODO: Implementar guardado de imagen en Sprint 2
            )
            
            currentDiagnosis = diagnosis
            
            print("💾 Diagnóstico guardado exitosamente en SwiftData")
            
        } catch {
            print("❌ Error en procesamiento de imagen: \(error)")
            errorMessage = "Error al procesar la imagen: \(error.localizedDescription)"
            
            // En caso de error, crear un diagnóstico genérico
            do {
                let fallbackDiagnosis = try dataService.createDiagnosisRecord(
                    for: user,
                    detectedIssue: "Error en clasificación",
                    confidence: 0.0,
                    imagePath: nil
                )
                currentDiagnosis = fallbackDiagnosis
            } catch {
                print("❌ Error al guardar diagnóstico fallback: \(error)")
            }
        }
        
        isProcessing = false
    }
    
    // MARK: - Feedback
    
    func submitFeedback(isCorrect: Bool, correctedIssue: String? = nil) async {
        guard let diagnosis = currentDiagnosis else { return }
        
        do {
            try dataService.updateDiagnosisFeedback(
                record: diagnosis,
                isCorrect: isCorrect,
                correctedIssue: correctedIssue
            )
        } catch {
            errorMessage = "Error al guardar feedback: \(error.localizedDescription)"
        }
    }
    
    func reset() {
        selectedImage = nil
        currentDiagnosis = nil
        errorMessage = nil
    }
}
