//
//  HapticFeedback.swift
//  KaapehCopiloto2
//
//  Sistema centralizado de feedback háptico para toda la app
//

import SwiftUI

/// Tipos de feedback háptico personalizados para Káapeh
enum HapticFeedback {
    // MARK: - Success/Completion
    case success       // Tarea completada, acción exitosa
    case taskComplete  // Tarea específicamente marcada como completada
    
    // MARK: - Warnings/Errors
    case warning       // Advertencia suave
    case error         // Error o acción fallida
    
    // MARK: - Selection/Navigation
    case selection     // Cambio de tab, selección de opción
    case lightSelection // Selección suave (filtros, chips)
    
    // MARK: - Impact
    case lightImpact   // Tap en botones pequeños
    case mediumImpact  // Tap en botones principales
    case heavyImpact   // Acciones importantes (enviar mensaje, guardar)
    
    // MARK: - Voice Specific
    case voiceStart    // Iniciar grabación de voz
    case voiceStop     // Detener grabación
    case voiceProcessing // Mensaje enviado, procesando
    
    // MARK: - SwiftUI SensoryFeedback
    
    /// Convierte el HapticFeedback a SensoryFeedback nativo de iOS 17+
    var sensoryFeedback: SensoryFeedback {
        switch self {
        // Success
        case .success:
            return .success
        case .taskComplete:
            return .success
            
        // Warnings/Errors
        case .warning:
            return .warning
        case .error:
            return .error
            
        // Selection
        case .selection:
            return .selection
        case .lightSelection:
            return .selection
            
        // Impact
        case .lightImpact:
            return .impact(weight: .light, intensity: 0.7)
        case .mediumImpact:
            return .impact(weight: .medium, intensity: 0.8)
        case .heavyImpact:
            return .impact(weight: .heavy, intensity: 1.0)
            
        // Voice
        case .voiceStart:
            return .start // iOS 17+ feedback para inicio de acción
        case .voiceStop:
            return .stop // iOS 17+ feedback para fin de acción
        case .voiceProcessing:
            return .impact(weight: .medium, intensity: 0.9)
        }
    }
    
    // MARK: - Trigger Method
    
    /// Dispara el feedback háptico inmediatamente usando UIKit
    func trigger() {
        HapticManager.shared.generate(self)
    }
}

// MARK: - View Extension para uso fácil

extension View {
    /// Agrega feedback háptico a una vista con trigger personalizado
    /// - Parameters:
    ///   - feedback: Tipo de feedback háptico
    ///   - trigger: Valor que dispara el feedback cuando cambia
    /// - Returns: Vista modificada con feedback háptico
    func haptic<T: Equatable>(_ feedback: HapticFeedback, trigger: T) -> some View {
        self.sensoryFeedback(feedback.sensoryFeedback, trigger: trigger)
    }
    
    /// Agrega feedback háptico simple a un botón
    /// - Parameter feedback: Tipo de feedback háptico
    /// - Returns: Vista modificada con feedback háptico
    func buttonHaptic(_ feedback: HapticFeedback = .lightImpact) -> some View {
        self.sensoryFeedback(feedback.sensoryFeedback, trigger: UUID())
    }
}

// MARK: - Haptic Feedback Helper (Legacy UIKit Support)

/// Helper para feedback háptico usando UIKit (fallback para casos especiales)
final class HapticManager {
    static let shared = HapticManager()
    
    private init() {}
    
    /// Genera feedback háptico usando UIKit
    func generate(_ feedback: HapticFeedback) {
        switch feedback {
        case .success, .taskComplete:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
        case .warning:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
            
        case .error:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
            
        case .selection, .lightSelection:
            let generator = UISelectionFeedbackGenerator()
            generator.selectionChanged()
            
        case .lightImpact:
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            
        case .mediumImpact, .voiceProcessing:
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            
        case .heavyImpact, .voiceStart, .voiceStop:
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.impactOccurred()
        }
    }
}
