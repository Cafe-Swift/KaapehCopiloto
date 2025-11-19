//
//  AuthenticationViewModel.swift
//  KaapehCopiloto2
//
//  Created by Cafe Swift Team on 05/11/25.
//

import Foundation
import SwiftUI
import Combine

@MainActor
@Observable
final class AuthenticationViewModel {
    var userName: String = ""
    var selectedRole: String = "Productor"
    var selectedLanguage: String = "es"
    var isLoading: Bool = false
    var errorMessage: String?
    var isAuthenticated: Bool = false
    var currentUser: UserProfile?
    
    private let dataService = SwiftDataService.shared
    private let networkService = NetworkService.shared
    
    let availableRoles = ["Productor", "Técnico"]
    let availableLanguages = [
        ("es", "Español"),
        ("tsz", "Tsotsil")
    ]
    
    // MARK: - Authentication
    
    func login() async {
        guard !userName.isEmpty else {
            errorMessage = "Por favor ingresa un nombre de usuario"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Autenticación 100% OFFLINE usando solo SwiftData local
            // Buscar usuario existente por nombre de usuario
            let allProfiles = try dataService.fetchAllUserProfiles()
            
            if let existingUser = allProfiles.first(where: { $0.userName == userName }) {
                // Usuario encontrado - iniciar sesión
                existingUser.lastLoginAt = Date()
                currentUser = existingUser
                selectedRole = existingUser.role
                selectedLanguage = existingUser.preferredLanguage
                isAuthenticated = true
            } else {
                // Usuario no existe - mostrar error
                errorMessage = "Usuario '\(userName)' no encontrado. Por favor regístrate primero."
                isLoading = false
                return
            }
            
        } catch {
            errorMessage = "Error al cargar datos locales: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func register() async {
        guard !userName.isEmpty else {
            errorMessage = "Por favor ingresa un nombre de usuario"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Verificar si el usuario ya existe localmente
            let allProfiles = try dataService.fetchAllUserProfiles()
            
            if let existingUser = allProfiles.first(where: { $0.userName == userName }) {
                // Si el usuario ya existe, iniciamos sesión automáticamente
                currentUser = existingUser
                isAuthenticated = true
                isLoading = false
                return
            }
            
            // Crear usuario localmente (offline-first)
            currentUser = try dataService.createUserProfile(
                userName: userName,
                role: selectedRole,
                language: selectedLanguage
            )
            
            isAuthenticated = true
            
        } catch {
            errorMessage = "Error al registrar: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func logout() {
        isAuthenticated = false
        currentUser = nil
        userName = ""
    }
}
