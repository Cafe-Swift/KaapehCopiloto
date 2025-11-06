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
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Fondo dinámico según alto contraste
                accessibilityManager.backgroundColor
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        headerSection
                        formSection
                        registerButton
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color(red: 0.4, green: 0.26, blue: 0.13), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.white)
                    }
                    .accessibilityLabel("Cerrar registro")
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
    }
    
    // MARK: - View Components
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.crop.circle.badge.plus")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .foregroundStyle(Color(red: 0.4, green: 0.26, blue: 0.13))
                .shadow(color: Color(red: 0.4, green: 0.26, blue: 0.13).opacity(0.3), radius: 8, y: 4)
            
            Text("Crear Cuenta")
                .font(.system(size: accessibilityManager.titleFontSize, weight: .bold, design: .rounded))
                .foregroundStyle(accessibilityManager.primaryTextColor)
            
            Text("Únete a Káapeh Copiloto")
                .font(.system(size: accessibilityManager.bodyFontSize))
                .foregroundStyle(accessibilityManager.secondaryTextColor)
        }
    }
    
    private var formSection: some View {
        VStack(spacing: 20) {
            // Nombre de usuario
            VStack(alignment: .leading, spacing: 8) {
                Text("Nombre de usuario")
                    .font(.system(size: accessibilityManager.bodyFontSize, weight: .semibold))
                    .foregroundStyle(accessibilityManager.primaryTextColor)
                
                TextField("Ingresa tu nombre de usuario", text: $viewModel.userName)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .textContentType(.username)
                    .font(.system(size: accessibilityManager.bodyFontSize))
                    .padding()
                    .background(accessibilityManager.cardBackgroundColor)
                    .foregroundStyle(accessibilityManager.primaryTextColor)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(red: 0.4, green: 0.26, blue: 0.13).opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
                    .accessibilityLabel("Campo de nombre de usuario")
                    .accessibilityHint("Ingresa tu nombre de usuario")
            }
            
            // Rol
            VStack(alignment: .leading, spacing: 8) {
                Text("Rol")
                    .font(.system(size: accessibilityManager.bodyFontSize, weight: .semibold))
                    .foregroundStyle(accessibilityManager.primaryTextColor)
                
                Picker("Rol", selection: $viewModel.selectedRole) {
                    ForEach(viewModel.availableRoles, id: \.self) { role in
                        Text(role).tag(role)
                    }
                }
                .pickerStyle(.segmented)
                .background(accessibilityManager.cardBackgroundColor)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
                .accessibilityLabel("Selector de rol")
                .accessibilityHint("Elige si eres Productor o Técnico")
            }
            
            // Idioma
            VStack(alignment: .leading, spacing: 8) {
                Text("Idioma Preferido")
                    .font(.system(size: accessibilityManager.bodyFontSize, weight: .semibold))
                    .foregroundStyle(accessibilityManager.primaryTextColor)
                
                Picker("Idioma", selection: $viewModel.selectedLanguage) {
                    ForEach(viewModel.availableLanguages, id: \.0) { code, name in
                        Text(name).tag(code)
                    }
                }
                .pickerStyle(.segmented)
                .background(accessibilityManager.cardBackgroundColor)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
                .accessibilityLabel("Selector de idioma")
                .accessibilityHint("Elige tu idioma preferido")
            }
        }
        .padding(24)
        .background(accessibilityManager.cardBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.1), radius: 12, y: 6)
    }
    
    private var registerButton: some View {
        Button {
            Task {
                await viewModel.register()
                if viewModel.isAuthenticated {
                    dismiss()
                }
            }
        } label: {
            HStack {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Registrarme")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                Group {
                    if viewModel.userName.isEmpty {
                        Color.gray.opacity(0.4)
                    } else {
                        LinearGradient(
                            colors: [Color(red: 0.6, green: 0.4, blue: 0.2), Color(red: 0.4, green: 0.26, blue: 0.13)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: viewModel.userName.isEmpty ? .clear : .black.opacity(0.2), radius: 8, y: 4)
        }
        .disabled(viewModel.isLoading || viewModel.userName.isEmpty)
        .opacity(viewModel.userName.isEmpty ? 0.6 : 1.0)
        .accessibilityLabel("Botón de registro")
        .accessibilityHint(viewModel.userName.isEmpty ? "Ingresa un nombre de usuario primero" : "Toca para crear tu cuenta")
    }
}

#Preview {
    RegistrationView(viewModel: AuthenticationViewModel())
}
