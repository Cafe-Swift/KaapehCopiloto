//
//  NetworkServiceTests.swift
//  KaapehCopiloto2Tests
//
//  Created by Test Suite on 23/11/25.
//

import Testing
import Foundation
@testable import KaapehCopiloto2

@MainActor
struct NetworkServiceTests {
    
    var service: NetworkService
    
    init() {
        service = NetworkService.shared
    }
    
    // MARK: - Basic Tests
    
    @Test("NetworkService singleton is accessible")
    func testServiceInitialization() {
        #expect(service.isConnected == true)
    }
}
