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
    let knowledgeBaseInitializer = KnowledgeBaseInitializer()
    
    // Estado de la base de conocimiento
    var isInitializingKnowledge = false
    var knowledgeBaseReady = false
    var knowledgeBaseProgress: Double = 0.0
    
    init() {
        self.authViewModel = AuthenticationViewModel()
        Task {
            await checkAuthenticationStatus()
            // Iniciar sincronización automática en segundo plano
            await syncService.syncIfNeeded()
            // Inicializar base de conocimiento
            await initializeKnowledgeBase()
        }
    }
    
    /// Initialize app and check authentication (public method)
    func initializeApp() async {
        await checkAuthenticationStatus()
        await initializeKnowledgeBase()
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
    
    /// Inicializar base de conocimiento RAG
    private func initializeKnowledgeBase() async {
        isInitializingKnowledge = true
        knowledgeBaseReady = false
        
        print("🚀 Iniciando carga de base de conocimiento...")
        
        do {
            try await knowledgeBaseInitializer.initialize()
            knowledgeBaseReady = true
            knowledgeBaseProgress = 1.0
            print("✅ Base de conocimiento lista con \(knowledgeBaseInitializer.totalChunksIndexed) chunks")
        } catch {
            print("❌ Error inicializando base de conocimiento: \(error.localizedDescription)")
            knowledgeBaseReady = false
            knowledgeBaseProgress = 0.0
        }
        
        isInitializingKnowledge = false
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
