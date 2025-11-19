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
            // Fondo dinámico según alto contraste
            accessibilityManager.backgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
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
        VStack(spacing: 16) {
            Image(systemName: "leaf.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundStyle(Color(red: 0.2, green: 0.5, blue: 0.3))
                .shadow(color: Color(red: 0.2, green: 0.5, blue: 0.3).opacity(0.3), radius: 10)
            
            Text("Káapeh Copiloto")
                .font(.system(size: accessibilityManager.titleFontSize, weight: .bold))
                .foregroundStyle(accessibilityManager.primaryTextColor)
            
            Text("Tu cafetal inteligente, en tu bolsillo")
                .font(.system(size: accessibilityManager.bodyFontSize))
                .foregroundStyle(accessibilityManager.secondaryTextColor)
                .multilineTextAlignment(.center)
        }
    }
    
    private var loginForm: some View {
        VStack(spacing: 20) {
            // Username field
            VStack(alignment: .leading, spacing: 8) {
                Text("Nombre de usuario")
                    .font(.system(size: accessibilityManager.bodyFontSize, weight: .semibold))
                    .foregroundStyle(accessibilityManager.primaryTextColor)
                
                TextField("Ingresa tu usuario", text: $viewModel.userName)
                    .textFieldStyle(.plain)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .font(.system(size: accessibilityManager.bodyFontSize))
                    .foregroundStyle(accessibilityManager.primaryTextColor)
                    .padding(16)
                    .background(accessibilityManager.cardBackgroundColor)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(red: 0.8, green: 0.8, blue: 0.8), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
            }
            
            // Login Button - Grande y visible
            Button {
                Task {
                    await viewModel.login()
                }
            } label: {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Iniciar Sesión")
                            .font(.system(size: accessibilityManager.bodyFontSize + 1, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    LinearGradient(
                        colors: viewModel.userName.isEmpty ?
                            [Color.gray.opacity(0.5), Color.gray.opacity(0.5)] :
                            [Color(red: 0.6, green: 0.4, blue: 0.2), Color(red: 0.4, green: 0.26, blue: 0.13)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: viewModel.userName.isEmpty ? .clear : .black.opacity(0.2), radius: 8, y: 4)
            }
            .disabled(viewModel.isLoading || viewModel.userName.isEmpty)
        }
        .padding(24)
        .background(accessibilityManager.cardBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.15), radius: 12, y: 6)
    }
    
    private var registerLink: some View {
        Button {
            showRegistration = true
        } label: {
            HStack(spacing: 8) {
                Text("¿No tienes cuenta?")
                    .foregroundStyle(Color(red: 0.4, green: 0.26, blue: 0.13))
                Text("Regístrate")
                    .fontWeight(.semibold)
                    .foregroundStyle(Color(red: 0.2, green: 0.13, blue: 0.07))
            }
            .font(.system(size: 16))
        }
    }
}

#Preview {
    LoginView(viewModel: AuthenticationViewModel())
}
