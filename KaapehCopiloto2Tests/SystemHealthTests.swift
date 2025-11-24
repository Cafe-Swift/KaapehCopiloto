//
//  SystemHealthTests.swift
//  KaapehCopiloto2Tests
//
//  Created by Test Suite on 23/11/25.
//

import Testing
import Foundation
import SwiftData
import SwiftUI
@testable import KaapehCopiloto2

@MainActor
struct SystemHealthTests {
    
    // MARK: - Service Availability Tests
    
    @Test("Check if core services are accessible")
    func testCoreServicesAccessibility() {
        // Test singleton services can be accessed
        let networkService = NetworkService.shared
        let accessibilityManager = AccessibilityManager.shared
        let vectorDB = VectorDatabaseService.shared
        
        #expect(networkService.isConnected == true)
        // Services are non-optional singletons, just verify they exist
        _ = accessibilityManager
        _ = vectorDB
    }
    
    @Test("EmbeddingService can initialize")
    func testEmbeddingServiceInit() {
        let service = EmbeddingService()
        #expect(service != nil)
    }
    
    @Test("Theme colors are defined")
    func testThemeColors() {
        // Verificar que los colores principales están definidos
        let coffeeBrown = AppTheme.Colors.coffeeBrown
        let coffeeGreen = AppTheme.Colors.coffeeGreen
        
        // Colors are non-optional, just verify they exist
        _ = coffeeBrown
        _ = coffeeGreen
    }
    
    @Test("SwiftData models can be initialized")
    func testSwiftDataModelsInit() throws {
        let schema = Schema([
            UserProfile.self,
            AccessibilityConfig.self,
            DiagnosisRecord.self,
            ActionItem.self
        ])
        
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        
        // Container is non-optional, just verify it was created
        _ = container
    }
}
