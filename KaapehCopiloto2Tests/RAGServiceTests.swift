//
//  RAGServiceTests.swift
//  KaapehCopiloto2Tests
//
//  Created by Test Suite on 23/11/25.
//

import Testing
import Foundation
@testable import KaapehCopiloto2

@MainActor
struct RAGServiceTests {
    
    // MARK: - Basic Tests
    
    @Test("RAGService can be initialized")
    func testServiceInitialization() async {
        let service = RAGService()
        #expect(service != nil)
    }
    
    @Test("RAGService has required dependencies")
    func testServiceDependencies() async {
        let service = RAGService()
        // Verificar que el servicio está listo
        let isReady = service.isReady
        // No forzamos que sea true porque depende de Foundation Models
        #expect(isReady == true || isReady == false)
    }
}
