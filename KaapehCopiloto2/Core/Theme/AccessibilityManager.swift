//
//  AccessibilityManager.swift
//  KaapehCopiloto2
//
//  Created by Cafe Swift Team on 06/11/25.
//

import SwiftUI

/// Manager global para aplicar configuraciones de accesibilidad en toda la app
@MainActor
@Observable
final class AccessibilityManager {
    static let shared = AccessibilityManager()
    
    // Configuraciones de accesibilidad
    var isLargeTextEnabled: Bool = false {
        didSet {
            applyTextSizeChanges()
        }
    }
    
    var isHighContrastEnabled: Bool = false {
        didSet {
            applyContrastChanges()
        }
    }
    
    var isVoiceInteractionPreferred: Bool = false {
        didSet {
            applyVoicePreferences()
        }
    }
    
    // Tamaños de fuente dinámicos
    var titleFontSize: CGFloat = 32
    var headlineFontSize: CGFloat = 20
    var bodyFontSize: CGFloat = 17
    var captionFontSize: CGFloat = 14
    
    // Colores con contraste ajustable
    var primaryTextColor: Color = Color(red: 0.2, green: 0.13, blue: 0.07)
    var secondaryTextColor: Color = Color(red: 0.4, green: 0.26, blue: 0.13)
    var backgroundColor: Color = Color(red: 0.98, green: 0.96, blue: 0.93)
    var cardBackgroundColor: Color = .white
    
    private init() {
        // Cargar configuración guardada
        loadSettings()
    }
    
    /// Carga las configuraciones desde el usuario actual
    func loadSettings(from user: UserProfile? = nil) {
        guard let user = user ?? (try? SwiftDataService.shared.fetchCurrentUserProfile()),
              let config = user.accessibilitySettings else {
            return
        }
        
        isLargeTextEnabled = config.largeTextEnabled
        isHighContrastEnabled = config.highContrastEnabled
        isVoiceInteractionPreferred = config.voiceInteractionPreferred
    }
    
    /// Actualiza todas las configuraciones de una vez
    func updateSettings(largeText: Bool, highContrast: Bool, voicePreferred: Bool) {
        isLargeTextEnabled = largeText
        isHighContrastEnabled = highContrast
        isVoiceInteractionPreferred = voicePreferred
    }
    
    // MARK: - Apply Changes
    
    private func applyTextSizeChanges() {
        if isLargeTextEnabled {
            // Aumentar tamaños en 50%
            titleFontSize = 48      // De 32 a 48
            headlineFontSize = 30   // De 20 a 30
            bodyFontSize = 25       // De 17 a 25
            captionFontSize = 20    // De 14 a 20
        } else {
            // Tamaños normales
            titleFontSize = 32
            headlineFontSize = 20
            bodyFontSize = 17
            captionFontSize = 14
        }
        
        print("✅ Texto grande: \(isLargeTextEnabled ? "ACTIVADO" : "Desactivado")")
    }
    
    private func applyContrastChanges() {
        if isHighContrastEnabled {
            // Colores con máximo contraste
            primaryTextColor = .black
            secondaryTextColor = Color(red: 0.3, green: 0.2, blue: 0.1)
            backgroundColor = .white
            cardBackgroundColor = Color(red: 0.95, green: 0.95, blue: 0.95)
        } else {
            // Colores normales (tema café)
            primaryTextColor = Color(red: 0.2, green: 0.13, blue: 0.07)
            secondaryTextColor = Color(red: 0.4, green: 0.26, blue: 0.13)
            backgroundColor = Color(red: 0.98, green: 0.96, blue: 0.93)
            cardBackgroundColor = .white
        }
        
        print("✅ Alto contraste: \(isHighContrastEnabled ? "ACTIVADO" : "Desactivado")")
    }
    
    private func applyVoicePreferences() {
        print("✅ Preferencia de voz: \(isVoiceInteractionPreferred ? "ACTIVADA" : "Desactivada")")
    }
}

// MARK: - View Modifier para aplicar accesibilidad

struct AccessibilityAwareModifier: ViewModifier {
    @Environment(AccessibilityManager.self) private var accessibilityManager
    
    let textStyle: TextStyle
    
    enum TextStyle {
        case title
        case headline
        case body
        case caption
    }
    
    func body(content: Content) -> some View {
        content
            .font(fontForStyle())
            .foregroundStyle(colorForStyle())
    }
    
    private func fontForStyle() -> Font {
        switch textStyle {
        case .title:
            return .system(size: accessibilityManager.titleFontSize, weight: .bold)
        case .headline:
            return .system(size: accessibilityManager.headlineFontSize, weight: .semibold)
        case .body:
            return .system(size: accessibilityManager.bodyFontSize)
        case .caption:
            return .system(size: accessibilityManager.captionFontSize)
        }
    }
    
    private func colorForStyle() -> Color {
        switch textStyle {
        case .title, .headline:
            return accessibilityManager.primaryTextColor
        case .body, .caption:
            return accessibilityManager.secondaryTextColor
        }
    }
}

// MARK: - View Extension

extension View {
    func accessibilityAwareText(_ style: AccessibilityAwareModifier.TextStyle) -> some View {
        self.modifier(AccessibilityAwareModifier(textStyle: style))
    }
}
