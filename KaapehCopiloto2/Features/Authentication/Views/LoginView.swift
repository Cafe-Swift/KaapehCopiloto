//
//  LoginView.swift
//  KaapehCopiloto2
//
//  Created by Cafe Swift Team on 05/11/25.
//

import SwiftUI

struct LoginView: View {
    @Bindable var viewModel: AuthenticationViewModel
    @State private var showRegistration = false
    @Environment(AccessibilityManager.self) private var accessibilityManager
    
    var body: some View {
        ZStack {
            // Fondo moderno degradado suave
            LinearGradient(
                colors: [
                    Color(red: 0.98, green: 0.96, blue: 0.93),
                    Color(red: 0.95, green: 0.93, blue: 0.90),
                    Color(red: 0.92, green: 0.90, blue: 0.87)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Logo and Title
                logoSection
                
                Spacer()
                
                // Login Form
                loginForm
                
                // Register Link
                registerLink
                
                Spacer()
            }
            .padding(24)
        }
        .sheet(isPresented: $showRegistration) {
            RegistrationView(viewModel: viewModel)
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK", role: .cancel) {
                viewModel.errorMessage = nil
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Components
    
    private var logoSection: some View {
        VStack(spacing: 20) {
            // Logo circular grande con gradiente
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.Colors.coffeeGreen, AppTheme.Colors.coffeeGreen.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .shadow(color: AppTheme.Colors.coffeeGreen.opacity(0.4), radius: 16, y: 8)
                
                Image(systemName: "leaf.fill")
                    .font(.system(size: 56, weight: .semibold))
                    .foregroundStyle(.white)
            }
            
            Text("Káapeh Copiloto")
                .font(.system(size: accessibilityManager.titleFontSize + 4, weight: .bold))
                .foregroundStyle(accessibilityManager.primaryTextColor)
            
            Text("Tu cafetal inteligente, en tu bolsillo")
                .font(.system(size: accessibilityManager.bodyFontSize))
                .foregroundStyle(accessibilityManager.secondaryTextColor)
                .multilineTextAlignment(.center)
        }
    }
    
    private var loginForm: some View {
        VStack(spacing: 24) {
            // Username field con Liquid Glass
            LiquidGlassTextField(
                placeholder: "Ingresa tu usuario",
                icon: "person.fill",
                text: $viewModel.userName,
                accessibilityManager: accessibilityManager
            )
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            
            // Login Button moderno
            LiquidGlassButton(
                title: viewModel.isLoading ? "Iniciando..." : "Iniciar Sesión",
                icon: viewModel.isLoading ? nil : "arrow.right.circle.fill",
                style: .primary,
                accessibilityManager: accessibilityManager
            ) {
                Task {
                    await viewModel.login()
                }
            }
            .disabled(viewModel.isLoading || viewModel.userName.isEmpty)
            .sensoryFeedback(.success, trigger: viewModel.isAuthenticated)
            .opacity(viewModel.userName.isEmpty ? 0.5 : 1.0)
            .animation(.easeInOut, value: viewModel.userName.isEmpty)
        }
        .padding(28)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.15), radius: 12, y: 6)
        )
    }
    
    private var registerLink: some View {
        Button {
            showRegistration = true
        } label: {
            HStack(spacing: 8) {
                Text("¿No tienes cuenta?")
                    .foregroundStyle(accessibilityManager.secondaryTextColor)
                Text("Regístrate")
                    .fontWeight(.bold)
                    .foregroundStyle(AppTheme.Colors.coffeeGreen)
            }
            .font(.system(size: accessibilityManager.bodyFontSize))
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
            )
        }
        .sensoryFeedback(.selection, trigger: showRegistration)
    }
}

#Preview {
    LoginView(viewModel: AuthenticationViewModel())
}
