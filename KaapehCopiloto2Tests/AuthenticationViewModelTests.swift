//
//  AuthenticationViewModelTests.swift
//  KaapehCopiloto2Tests
//
//  Created by Cafe Swift Team on 06/11/25.
//

import Testing
import SwiftData
@testable import KaapehCopiloto2

@MainActor
struct AuthenticationViewModelTests {
    
    @Test("Register new user successfully")
    func testRegisterNewUser() async throws {
        // Given
        let viewModel = AuthenticationViewModel()
        viewModel.userName = "test_user"
        viewModel.selectedRole = "Productor"
        viewModel.selectedLanguage = "es"
        
        // When
        await viewModel.register()
        
        // Then
        #expect(viewModel.isAuthenticated == true)
        #expect(viewModel.currentUser != nil)
        #expect(viewModel.currentUser?.userName == "test_user")
        #expect(viewModel.errorMessage == nil)
    }
    
    @Test("Register fails with empty username")
    func testRegisterFailsWithEmptyUsername() async throws {
        // Given
        let viewModel = AuthenticationViewModel()
        viewModel.userName = ""
        
        // When
        await viewModel.register()
        
        // Then
        #expect(viewModel.isAuthenticated == false)
        #expect(viewModel.currentUser == nil)
        #expect(viewModel.errorMessage != nil)
    }
    
    @Test("Logout clears user data")
    func testLogout() async throws {
        // Given
        let viewModel = AuthenticationViewModel()
        viewModel.userName = "test_user"
        await viewModel.register()
        
        #expect(viewModel.isAuthenticated == true)
        
        // When
        viewModel.logout()
        
        // Then
        #expect(viewModel.isAuthenticated == false)
        #expect(viewModel.currentUser == nil)
        #expect(viewModel.userName == "")
    }
}
