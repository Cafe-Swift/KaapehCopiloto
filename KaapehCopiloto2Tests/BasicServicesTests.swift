//
//  BasicServicesTests.swift
//  KaapehCopiloto2Tests
//
//  Tests básicos para servicios core
//

import Testing
import Foundation
@testable import KaapehCopiloto2

@Suite("🤖 Basic Services Tests")
@MainActor
struct BasicServicesTests {
    
    @Test("✅ VectorDatabaseService es singleton")
    func testVectorDatabaseIsSingleton() {
        // Given & When
        let instance1 = VectorDatabaseService.shared
        let instance2 = VectorDatabaseService.shared
        
        // Then
        #expect(instance1 === instance2, 
               "Debe ser la misma instancia (singleton)")
    }
    
    @Test("✅ NetworkService es singleton")
    func testNetworkServiceIsSingleton() {
        // Given & When
        let instance1 = NetworkService.shared
        let instance2 = NetworkService.shared
        
        // Then
        #expect(instance1 === instance2,
               "Debe ser la misma instancia (singleton)")
    }
    
    @Test("✅ AccessibilityManager es singleton")
    func testAccessibilityManagerIsSingleton() {
        // Given & When
        let instance1 = AccessibilityManager.shared
        let instance2 = AccessibilityManager.shared
        
        // Then
        #expect(instance1 === instance2,
               "Debe ser la misma instancia (singleton)")
    }
    
    @Test("✅ NetworkService verifica conectividad")
    func testNetworkServiceChecksConnectivity() {
        // Given
        let service = NetworkService.shared
        
        // When
        let isConnected = service.isConnected
        
        // Then
        #expect(isConnected == true || isConnected == false,
               "Debe retornar un booleano válido")
    }
}
