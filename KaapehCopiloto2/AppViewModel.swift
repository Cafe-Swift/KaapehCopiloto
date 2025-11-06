//
//  AppViewModel.swift
//  KaapehCopiloto2
//
//  Created by Cafe Swift Team on 05/11/25.
//

import Foundation
import SwiftUI
import Combine

/// Main application view model 
@MainActor
@Observable
final class AppViewModel {
    var isCheckingAuth: Bool = true
    var authViewModel: AuthenticationViewModel
    
    // Servicios globales
    let accessibilityManager = AccessibilityManager.shared
    let syncService = BackgroundSyncService.shared
    
    init() {
        self.authViewModel = AuthenticationViewModel()
        Task {
            await checkAuthenticationStatus()
            // Iniciar sincronización automática en segundo plano
            await syncService.syncIfNeeded()
        }
    }
    
    /// Initialize app and check authentication (public method)
    func initializeApp() async {
        await checkAuthenticationStatus()
    }
    
    /// Check if user is already authenticated
    private func checkAuthenticationStatus() async {
        isCheckingAuth = true
        
        do {
            if let existingUser = try SwiftDataService.shared.fetchCurrentUserProfile() {
                authViewModel.currentUser = existingUser
                authViewModel.isAuthenticated = true
                
                // Cargar configuración de accesibilidad del usuario
                accessibilityManager.loadSettings(from: existingUser)
            }
        } catch {
            print("Error checking auth status: \(error.localizedDescription)")
        }
        
        // Small delay for smooth splash screen transition
        try? await Task.sleep(for: .seconds(0.5))
        isCheckingAuth = false
    }
    
    /// Refresh user data
    func refreshUserData() async {
        do {
            if let user = try SwiftDataService.shared.fetchCurrentUserProfile() {
                authViewModel.currentUser = user
                accessibilityManager.loadSettings(from: user)
            }
        } catch {
            print("Error refreshing user data: \(error.localizedDescription)")
        }
    }
}
