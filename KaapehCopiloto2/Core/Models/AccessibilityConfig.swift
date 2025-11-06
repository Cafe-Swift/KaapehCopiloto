//
//  AccessibilityConfig.swift
//  KaapehCopiloto2
//
//  Created by Cafe Swift Team on 05/11/25.
//

import Foundation
import SwiftData

/// Accessibility configuration model
@Model
final class AccessibilityConfig {
    var largeTextEnabled: Bool
    var highContrastEnabled: Bool
    var voiceInteractionPreferred: Bool
    var onboardingCompleted: Bool
    var lastModified: Date
    
    init(
        largeTextEnabled: Bool = false,
        highContrastEnabled: Bool = false,
        voiceInteractionPreferred: Bool = false,
        onboardingCompleted: Bool = false,
        lastModified: Date = Date()
    ) {
        self.largeTextEnabled = largeTextEnabled
        self.highContrastEnabled = highContrastEnabled
        self.voiceInteractionPreferred = voiceInteractionPreferred
        self.onboardingCompleted = onboardingCompleted
        self.lastModified = lastModified
    }
    
    /// Update configuration and mark as modified
    func updateSettings(
        largeText: Bool? = nil,
        highContrast: Bool? = nil,
        voicePreferred: Bool? = nil,
        onboardingDone: Bool? = nil
    ) {
        if let largeText = largeText { self.largeTextEnabled = largeText }
        if let highContrast = highContrast { self.highContrastEnabled = highContrast }
        if let voicePreferred = voicePreferred { self.voiceInteractionPreferred = voicePreferred }
        if let onboardingDone = onboardingDone { self.onboardingCompleted = onboardingDone }
        self.lastModified = Date()
    }
    
    /// Complete onboarding
    func completeOnboarding() {
        self.onboardingCompleted = true
        self.lastModified = Date()
    }
}
