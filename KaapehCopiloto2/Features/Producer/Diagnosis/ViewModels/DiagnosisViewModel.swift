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
        
        // Simular procesamiento de Core ML (implementación posterior)
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 segundos
        
        // Mock diagnosis result
        let mockIssues = [
            ("Roya del Café", 0.92),
            ("Planta Sana", 0.88),
            ("Deficiencia de Nitrógeno", 0.85)
        ]
        
        let randomResult = mockIssues.randomElement() ?? mockIssues[0]
        
        do {
            let diagnosis = try dataService.createDiagnosisRecord(
                for: user,
                detectedIssue: randomResult.0,
                confidence: randomResult.1,
                imagePath: nil // TODO: Guardar imagen en Sprint 2
            )
            
            currentDiagnosis = diagnosis
        } catch {
            errorMessage = "Error al guardar diagnóstico: \(error.localizedDescription)"
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
