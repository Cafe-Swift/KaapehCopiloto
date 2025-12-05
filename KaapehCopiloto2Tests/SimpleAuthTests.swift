//
//  SimpleAuthTests.swift
//  KaapehCopiloto2Tests
//
//  Tests simplificados de autenticación que compilan correctamente
//

import Testing
import SwiftData
@testable import KaapehCopiloto2

@Suite("🔐 Authentication Tests")
@MainActor
struct SimpleAuthTests {
    
    @Test("✅ Registro de usuario exitoso")
    func testUserRegistration() async throws {
        // Given
        let viewModel = AuthenticationViewModel()
        viewModel.userName = "test_user"
        viewModel.selectedRole = "Productor"
        viewModel.selectedLanguage = "es"
        
        // When
        await viewModel.register()
        
        // Then
        #expect(viewModel.isAuthenticated == true, "Usuario debe estar autenticado")
        #expect(viewModel.currentUser != nil, "Debe existir un usuario")
        #expect(viewModel.errorMessage == nil, "No debe haber errores")
    }
    
    @Test("❌ Registro falla con username vacío")
    func testRegistrationFailsWithEmptyUsername() async throws {
        // Given
        let viewModel = AuthenticationViewModel()
        viewModel.userName = ""
        viewModel.selectedRole = "Productor"
        
        // When
        await viewModel.register()
        
        // Then
        #expect(viewModel.isAuthenticated == false, "No debe autenticarse")
        #expect(viewModel.errorMessage != nil, "Debe haber error")
    }
    
    @Test("✅ Login exitoso")
    func testSuccessfulLogin() async throws {
        // Given - Primero registrar
        let registerVM = AuthenticationViewModel()
        registerVM.userName = "existing_user"
        registerVM.selectedRole = "Productor"
        await registerVM.register()
        
        // When - Hacer login
        let loginVM = AuthenticationViewModel()
        loginVM.userName = "existing_user"
        await loginVM.login()
        
        // Then
        #expect(loginVM.isAuthenticated == true, "Debe autenticarse")
    }
    
    @Test("🚪 Logout limpia datos")
    func testLogoutClearsData() async throws {
        // Given
        let viewModel = AuthenticationViewModel()
        viewModel.userName = "test_user"
        viewModel.selectedRole = "Productor"
        await viewModel.register()
        
        #expect(viewModel.isAuthenticated == true)
        
        // When
        viewModel.logout()
        
        // Then
        #expect(viewModel.isAuthenticated == false, "Debe estar desautenticado")
        #expect(viewModel.currentUser == nil, "Usuario debe ser nil")
    }
}
