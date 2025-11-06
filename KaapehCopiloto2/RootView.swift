//
//  RootView.swift
//  KaapehCopiloto2
//
//  Created by Cafe Swift Team on 05/11/25.
//

import SwiftUI
import SwiftData

/// Vista raíz que maneja la navegación principal de la app
struct RootView: View {
    @Environment(AppViewModel.self) private var appViewModel
    @State private var showOnboarding = false
    
    var body: some View {
        Group {
            if appViewModel.isCheckingAuth {
                // Splash screen con loading
                SplashView()
            } else if !appViewModel.authViewModel.isAuthenticated {
                // Pantalla de autenticación
                LoginView(viewModel: appViewModel.authViewModel)
            } else if let user = appViewModel.authViewModel.currentUser {
                // Verificar si necesita onboarding
                if user.accessibilitySettings?.onboardingCompleted == false {
                    OnboardingView(
                        viewModel: OnboardingViewModel(),
                        user: user
                    ) {
                        showOnboarding = false
                    }
                } else {
                    // Pantalla principal según el rol
                    MainView(user: user)
                }
            }
        }
        .animation(.smooth(duration: 0.3), value: appViewModel.isCheckingAuth)
        .animation(.smooth(duration: 0.3), value: appViewModel.authViewModel.isAuthenticated)
    }
}

/// Vista de carga inicial
struct SplashView: View {
    var body: some View {
        ZStack {
            LiquidGlassBackground()
            
            VStack(spacing: AppTheme.Spacing.lg) {
                Image(systemName: "leaf.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .foregroundStyle(AppTheme.Colors.coffeeGreen)
                    .shadow(color: .black.opacity(0.3), radius: 20)
                
                Text("Káapeh Copiloto")
                    .font(AppTheme.Typography.largeTitle)
                    .foregroundStyle(.white)
                    .shadow(radius: 2)
                
                Text("Tu cafetal inteligente")
                    .font(AppTheme.Typography.body)
                    .foregroundStyle(.white.opacity(0.9))
                
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.5)
                    .padding(.top, AppTheme.Spacing.lg)
            }
        }
    }
}



#Preview {
    RootView()
        .environment(AppViewModel())
        .modelContainer(for: [UserProfile.self, AccessibilityConfig.self, DiagnosisRecord.self, ActionItem.self])
}
