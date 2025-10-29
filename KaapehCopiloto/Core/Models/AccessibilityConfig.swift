//
//  AccessibilityConfig.swift
//  KaapehCopiloto
//
//  Created by Cafe Swift on 27/10/25.
//

import Foundation
import SwiftData

@Model
final class AccessibilityConfig {
    var largeTextEnabled: Bool = false
    var highContrastEnabled: Bool = false
    var voiceInteractionPreferred: Bool = false
    var onboardingCompleted: Bool = false
    
    var userProfile: UserProfile?
    
    init(largeTextEnabled: Bool = false,
         highContrastEnabled: Bool = false,
         voiceInteractionPreferred: Bool = false) {
        self.largeTextEnabled = largeTextEnabled
        self.highContrastEnabled = highContrastEnabled
        self.voiceInteractionPreferred = voiceInteractionPreferred
        self.onboardingCompleted = false
    }
}
