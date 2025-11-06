//
//  SettingsView.swift
//  KaapehCopiloto2
//
//  Created by Cafe Swift Team on 05/11/25.
//

import SwiftUI

struct SettingsView: View {
    let user: UserProfile
    @Environment(\.dismiss) private var dismiss
    @Environment(AppViewModel.self) private var appViewModel
    @Environment(AccessibilityManager.self) private var accessibilityManager
    @State private var viewModel: SettingsViewModel
    
    init(user: UserProfile) {
        self.user = user
        self._viewModel = State(initialValue: SettingsViewModel(user: user))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Fondo dinámico basado en configuración de accesibilidad
                accessibilityManager.backgroundColor
                    .ignoresSafeArea()
                
                Form {
                    accessibilitySection
                    languageSection
                    accountSection
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Configuración")
            .font(.system(size: accessibilityManager.headlineFontSize, weight: .bold))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color(red: 0.4, green: 0.26, blue: 0.13), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Listo") {
                        dismiss()
                    }
                    .foregroundStyle(.white)
                }
            }
        }
    }
    
    private var accessibilitySection: some View {
        Section {
            Toggle("Texto Grande", isOn: $viewModel.largeTextEnabled)
                .font(.system(size: accessibilityManager.bodyFontSize))
                .foregroundStyle(accessibilityManager.primaryTextColor)
                .tint(Color(red: 0.4, green: 0.26, blue: 0.13))
                .onChange(of: viewModel.largeTextEnabled) { _, newValue in
                    Task { await viewModel.saveSettings() }
                }
            
            Toggle("Alto Contraste", isOn: $viewModel.highContrastEnabled)
                .font(.system(size: accessibilityManager.bodyFontSize))
                .foregroundStyle(accessibilityManager.primaryTextColor)
                .tint(Color(red: 0.4, green: 0.26, blue: 0.13))
                .onChange(of: viewModel.highContrastEnabled) { _, newValue in
                    Task { await viewModel.saveSettings() }
                }
            
            Toggle("Interacción por Voz", isOn: $viewModel.voiceInteractionPreferred)
                .font(.system(size: accessibilityManager.bodyFontSize))
                .foregroundStyle(accessibilityManager.primaryTextColor)
                .tint(Color(red: 0.4, green: 0.26, blue: 0.13))
                .onChange(of: viewModel.voiceInteractionPreferred) { _, newValue in
                    Task { await viewModel.saveSettings() }
                }
        } header: {
            Text("Accesibilidad")
                .font(.system(size: accessibilityManager.captionFontSize, weight: .semibold))
                .foregroundStyle(Color(red: 0.4, green: 0.26, blue: 0.13))
        }
        .listRowBackground(accessibilityManager.cardBackgroundColor)
    }
    
    private var languageSection: some View {
        Section {
            Picker("Idioma", selection: $viewModel.selectedLanguage) {
                Text("Español").tag("es")
                Text("Tsotsil").tag("tsz")
            }
            .font(.system(size: accessibilityManager.bodyFontSize))
            .foregroundStyle(accessibilityManager.primaryTextColor)
            .tint(Color(red: 0.4, green: 0.26, blue: 0.13))
            .onChange(of: viewModel.selectedLanguage) { _, newValue in
                Task { await viewModel.saveSettings() }
            }
        } header: {
            Text("Idioma")
                .font(.system(size: accessibilityManager.captionFontSize, weight: .semibold))
                .foregroundStyle(Color(red: 0.4, green: 0.26, blue: 0.13))
        }
        .listRowBackground(accessibilityManager.cardBackgroundColor)
    }
    
    private var accountSection: some View {
        Section {
            HStack {
                Text("Usuario")
                    .font(.system(size: accessibilityManager.bodyFontSize))
                    .foregroundStyle(accessibilityManager.primaryTextColor)
                Spacer()
                Text(user.userName)
                    .font(.system(size: accessibilityManager.bodyFontSize))
                    .foregroundStyle(accessibilityManager.secondaryTextColor)
            }
            
            HStack {
                Text("Rol")
                    .font(.system(size: accessibilityManager.bodyFontSize))
                    .foregroundStyle(accessibilityManager.primaryTextColor)
                Spacer()
                Text(user.role)
                    .font(.system(size: accessibilityManager.bodyFontSize))
                    .foregroundStyle(accessibilityManager.secondaryTextColor)
            }
            
            Button(role: .destructive) {
                appViewModel.authViewModel.logout()
                dismiss()
            } label: {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("Cerrar Sesión")
                }
                .font(.system(size: accessibilityManager.bodyFontSize))
            }
        } header: {
            Text("Cuenta")
                .font(.system(size: accessibilityManager.captionFontSize, weight: .semibold))
                .foregroundStyle(Color(red: 0.4, green: 0.26, blue: 0.13))
        }
        .listRowBackground(accessibilityManager.cardBackgroundColor)
    }
}

@MainActor
@Observable
final class SettingsViewModel {
    let user: UserProfile
    var largeTextEnabled: Bool
    var highContrastEnabled: Bool
    var voiceInteractionPreferred: Bool
    var selectedLanguage: String
    
    private let dataService = SwiftDataService.shared
    private let accessibilityManager = AccessibilityManager.shared
    
    init(user: UserProfile) {
        self.user = user
        self.largeTextEnabled = user.accessibilitySettings?.largeTextEnabled ?? false
        self.highContrastEnabled = user.accessibilitySettings?.highContrastEnabled ?? false
        self.voiceInteractionPreferred = user.accessibilitySettings?.voiceInteractionPreferred ?? false
        self.selectedLanguage = user.preferredLanguage
    }
    
    func saveSettings() async {
        do {
            try dataService.updateAccessibilityConfig(
                for: user,
                largeText: largeTextEnabled,
                highContrast: highContrastEnabled,
                voicePreferred: voiceInteractionPreferred
            )
            user.preferredLanguage = selectedLanguage
            
            accessibilityManager.updateSettings(
                largeText: largeTextEnabled,
                highContrast: highContrastEnabled,
                voicePreferred: voiceInteractionPreferred
            )
            
            print("✅ Configuración guardada y aplicada visualmente")
            print("   📏 Tamaño fuente título: \(accessibilityManager.titleFontSize)pt")
            print("   🎨 Color texto: \(largeTextEnabled ? "Negro puro" : "Café")")
            
        } catch {
            print("Error saving settings: \(error)")
        }
    }
}
