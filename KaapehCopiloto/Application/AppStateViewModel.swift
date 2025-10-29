//
//  AppStateViewModel.swift
//  KaapehCopiloto
//
//  Created by Cafe Swift on 27/10/25.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class AppStateViewModel: ObservableObject {
    @Published var currentUser: UserProfile?
    @Published var isAuthenticated: Bool = false
    @Published var needsOnboarding: Bool = true
    @Published var isLoading: Bool = true
    
    private let dataService = SwiftDataService.shared
    
    init() {
        checkAuthenticationStatus()
    }
    
    func checkAuthenticationStatus() {
        isLoading = true
        
        // Verificar si existe un usuario en la base de datos local
        if let user = dataService.fetchCurrentUser() {
            currentUser = user
            isAuthenticated = true
            needsOnboarding = !(user.accessibilitySettings?.onboardingCompleted ?? false)
        } else {
            isAuthenticated = false
            needsOnboarding = true
        }
        
        isLoading = false
    }
    
    func register(userName: String, role: String, preferredLanguage: String) {
        do {
            let newUser = try dataService.createUserProfile(
                userName: userName,
                role: role,
                preferredLanguage: preferredLanguage
            )
            currentUser = newUser
            isAuthenticated = true
            needsOnboarding = true
        } catch {
            print("Error registering user: \(error)")
        }
    }
    
    func completeOnboarding(accessibilityConfig: AccessibilityConfig) {
        guard let user = currentUser else { return }
        
        do {
            accessibilityConfig.onboardingCompleted = true
            try dataService.updateAccessibilitySettings(for: user, config: accessibilityConfig)
            needsOnboarding = false
        } catch {
            print("Error completing onboarding: \(error)")
        }
    }
    
    func logout() {
        // Para MVP, reseteamos el estado
        // En producción, aquí ira la lógica de cerrar sesión
        currentUser = nil
        isAuthenticated = false
        needsOnboarding = true
    }
}
