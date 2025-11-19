//
//  OnboardingViewModel.swift
//  KaapehCopiloto2
//
//  Created by Cafe Swift Team on 05/11/25.
//

import Foundation
import SwiftUI
import Combine

@MainActor
@Observable
final class OnboardingViewModel {
    var currentStep: Int = 0
    var largeTextEnabled: Bool = false
    var highContrastEnabled: Bool = false
    var voiceInteractionPreferred: Bool = false
    var isLoading: Bool = false
    var errorMessage: String?
    
    private let dataService = SwiftDataService.shared
    
    let totalSteps = 4
    
    var canProceed: Bool {
        return currentStep < totalSteps - 1
    }
    
    // MARK: - Navigation
    
    func nextStep() {
        if currentStep < totalSteps - 1 {
            currentStep += 1
        }
    }
    
    func previousStep() {
        if currentStep > 0 {
            currentStep -= 1
        }
    }
    
    // MARK: - Completion
    
    func completeOnboarding(for user: UserProfile) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try dataService.updateAccessibilityConfig(
                for: user,
                largeText: largeTextEnabled,
                highContrast: highContrastEnabled,
                voicePreferred: voiceInteractionPreferred,
                onboardingCompleted: true
            )
        } catch {
            errorMessage = "Error al guardar configuración: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}
