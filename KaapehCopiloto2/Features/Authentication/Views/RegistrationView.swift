//
//  RegistrationView.swift
//  KaapehCopiloto2
//
//  Created by Cafe Swift Team on 05/11/25.
//

import SwiftUI

struct RegistrationView: View {
    @Bindable var viewModel: AuthenticationViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(AccessibilityManager.self) private var accessibilityManager
    @ObservedObject private var translator = KaapehTranslator.shared
    
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
            
            VStack(spacing: 0) {
                // Header flotante moderno
                HStack {
                    LiquidGlassCircleButton(
                        icon: "xmark",
                        size: 44,
                        backgroundColor: .white,
                        foregroundColor: AppTheme.Colors.coffeeBrown
                    ) {
                        dismiss()
                    }
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                ScrollView {
                    VStack(spacing: 32) {
                        modernHeaderSection
                        modernFormSection
                        modernRegisterButton
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
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
    
    // MARK: - View Components
    
    private var modernHeaderSection: some View {
        VStack(spacing: 20) {
            // Ícono circular grande con gradiente
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.Colors.coffeeBrown, AppTheme.Colors.coffeeBrown.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .shadow(color: AppTheme.Colors.coffeeBrown.opacity(0.4), radius: 16, y: 8)
                
                Image(systemName: "person.crop.circle.badge.plus")
                    .font(.system(size: 48, weight: .semibold))
                    .foregroundStyle(.white)
            }
            
            Text(translator.t("Crear cuenta"))
                .font(.system(size: accessibilityManager.titleFontSize + 2, weight: .bold, design: .rounded))
                .foregroundStyle(accessibilityManager.primaryTextColor)
            
            Text(translator.t("Únete a Káapeh Copiloto"))
                .font(.system(size: accessibilityManager.bodyFontSize))
                .foregroundStyle(accessibilityManager.secondaryTextColor)
        }
    }
    
    private var modernFormSection: some View {
        VStack(spacing: 24) {
            // Nombre de usuario con LiquidGlassTextField
            LiquidGlassTextField(
                placeholder: translator.t("Ingresa tu nombre"),
                icon: "person.fill",
                text: $viewModel.userName,
                accessibilityManager: accessibilityManager
            )
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .textContentType(.username)
            
            // Rol con estilo moderno
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: accessibilityManager.captionFontSize))
                        .foregroundStyle(AppTheme.Colors.coffeeBrown)
                    
                    Text(translator.t("Rol"))
                        .font(.system(size: accessibilityManager.bodyFontSize, weight: .semibold))
                        .foregroundStyle(accessibilityManager.primaryTextColor)
                }
                
                Picker("Rol", selection: $viewModel.selectedRole) {
                    ForEach(viewModel.availableRoles, id: \.self) { role in
                        Text(role).tag(role)
                    }
                }
                .pickerStyle(.segmented)
                .padding(4)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
                )
                .accessibilityLabel("Selector de rol")
                .accessibilityHint("Elige si eres Productor o Técnico")
            }
            
            // Idioma con estilo moderno
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "globe")
                        .font(.system(size: accessibilityManager.captionFontSize))
                        .foregroundStyle(AppTheme.Colors.coffeeBrown)
                    
                    Text(translator.t("Idioma Preferido"))
                        .font(.system(size: accessibilityManager.bodyFontSize, weight: .semibold))
                        .foregroundStyle(accessibilityManager.primaryTextColor)
                }
                
                Picker("Idioma", selection: $viewModel.selectedLanguage) {
                    ForEach(viewModel.availableLanguages, id: \.0) { code, name in
                        Text(name).tag(code)
                    }
                }
                .pickerStyle(.segmented)
                .padding(4)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
                )
                .accessibilityLabel("Selector de idioma")
                .accessibilityHint("Elige tu idioma preferido")
            }
        }
        .padding(28)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.15), radius: 12, y: 6)
        )
    }
    
    private var modernRegisterButton: some View {
        LiquidGlassButton(
            title: viewModel.isLoading ? translator.t("Creando cuenta...") : translator.t("Registrarme"),
            icon: viewModel.isLoading ? nil : "checkmark.circle.fill",
            style: .primary,
            accessibilityManager: accessibilityManager
        ) {
            Task {
                await viewModel.register()
                if viewModel.isAuthenticated {
                    dismiss()
                }
            }
        }
        .disabled(viewModel.isLoading || viewModel.userName.isEmpty)
        .opacity(viewModel.userName.isEmpty ? 0.5 : 1.0)
        .animation(.easeInOut, value: viewModel.userName.isEmpty)
        .sensoryFeedback(.success, trigger: viewModel.isAuthenticated)
        .accessibilityLabel("Botón de registro")
        .accessibilityHint(viewModel.userName.isEmpty ? "Ingresa un nombre de usuario primero" : "Toca para crear tu cuenta")
    }
}

#Preview {
    RegistrationView(viewModel: AuthenticationViewModel())
}
