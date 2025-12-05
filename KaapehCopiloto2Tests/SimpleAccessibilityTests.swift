//
//  SimpleAccessibilityTests.swift
//  KaapehCopiloto2Tests
//
//  Tests simplificados de accesibilidad
//

import Testing
import SwiftUI
@testable import KaapehCopiloto2

@Suite("♿️ Accessibility Tests")
@MainActor
struct SimpleAccessibilityTests {
    
    @Test("✅ AccessibilityManager es singleton")
    func testAccessibilityManagerSingleton() {
        let instance1 = AccessibilityManager.shared
        let instance2 = AccessibilityManager.shared
        
        #expect(instance1 === instance2, "Debe ser singleton")
    }
    
    @Test("✅ Texto grande cambia tamaños")
    func testLargeTextChangesSizes() {
        let manager = AccessibilityManager.shared
        let initialSize = manager.bodyFontSize
        
        manager.isLargeTextEnabled = true
        
        #expect(manager.bodyFontSize > initialSize, "Tamaño debe aumentar")
        
        // Cleanup
        manager.isLargeTextEnabled = false
    }
    
    @Test("✅ Alto contraste cambia colores")
    func testHighContrastChangesColors() {
        let manager = AccessibilityManager.shared
        
        manager.isHighContrastEnabled = true
        
        #expect(manager.primaryTextColor == .black, "Color debe ser negro")
        
        // Cleanup
        manager.isHighContrastEnabled = false
    }
    
    @Test("✅ Tema tiene colores definidos")
    func testThemeColors() {
        let coffeeBrown = AppTheme.Colors.coffeeBrown
        let coffeeGreen = AppTheme.Colors.coffeeGreen
        
        _ = coffeeBrown
        _ = coffeeGreen
        
        #expect(true, "Colores deben existir")
    }
    
    @Test("✅ Haptic feedback está definido")
    func testHapticFeedback() {
        let success = HapticFeedback.success
        let error = HapticFeedback.error
        
        _ = success
        _ = error
        
        #expect(true, "Haptic feedback debe existir")
    }
}
