//
//  SettingsView.swift
//  KaapehCopiloto
//
//  Created by Cafe Swift on 29/10/25.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppStateViewModel
    
    @State private var largeTextEnabled = false
    @State private var highContrastEnabled = false
    @State private var voiceInteractionPreferred = false
    @State private var selectedLanguage = "es"
    
    var body: some View {
        NavigationStack {
            Form {
                // informacion usuario
                Section("Información del Usuario") {
                    HStack {
                        Text("Nombre de Usuario")
                        Spacer()
                        Text(appState.currentUser?.userName ?? "N/A")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Rol")
                        Spacer()
                        Text(appState.currentUser?.role ?? "N/A")
                            .foregroundStyle(.secondary)
                    }
                }
                
                //idioma
                Section("Idioma") {
                    Picker("Idioma Preferido", selection: $selectedLanguage) {
                        Text("Español").tag("es")
                        Text("Tsotsil").tag("tsz")
                    }
                    .accessibilityLabel("Selector de idioma preferido")
                }
                
                // accessibilidad
                Section("Accesibilidad") {
                    Toggle("Texto Grande", isOn: $largeTextEnabled)
                        .accessibilityLabel("Activar texto grande")
                    
                    Toggle("Alto Contraste", isOn: $highContrastEnabled)
                        .accessibilityLabel("Activar alto contraste")
                    
                    Toggle("Preferir Voz", isOn: $voiceInteractionPreferred)
                        .accessibilityLabel("Preferir interacción por voz")
                }
                
                // informacion de la app
                Section("Información") {
                    HStack {
                        Text("Versión")
                        Spacer()
                        Text("1.0.0 (Sprint 1)")
                            .foregroundStyle(.secondary)
                    }
                    
                    Link("Sobre Káapeh México", destination: URL(string: "https://www.kaapehmexico.org/")!)
                        .accessibilityLabel("Visitar sitio web de Káapeh México")
                }
                
                // cerrar sesión
                Section {
                    Button(role: .destructive, action: logout) {
                        HStack {
                            Spacer ()
                            Text("Cerrar Sesión")
                            Spacer ()
                        }
                    }
                    .accessibilityLabel("Cerrar sesión")
                }
            }
            .navigationTitle("Configuración")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Listo") {
                        saveSettings()
                        dismiss()
                    }
                    .accessibilityLabel("Guardar y cerrar")
                }
            }
            .onAppear(perform: loadSettings)
        }
    }
    
    private func loadSettings() {
        guard let user = appState.currentUser,
              let config = user.accessibilitySettings else { return }
        
        largeTextEnabled = config.largeTextEnabled
        highContrastEnabled = config.highContrastEnabled
        voiceInteractionPreferred = config.voiceInteractionPreferred
        selectedLanguage = user.preferredLanguage
    }
    
    private func saveSettings() {
        guard let user = appState.currentUser else { return }
        
        let config = AccessibilityConfig(
            largeTextEnabled: largeTextEnabled,
            highContrastEnabled: highContrastEnabled,
            voiceInteractionPreferred: voiceInteractionPreferred,
        )
        config.onboardingCompleted = true
        
        do {
            try SwiftDataService.shared.updateAccessibilitySettings(for: user, config: config)
            user.preferredLanguage = selectedLanguage
        } catch {
            print("Error guardando configuración: \(error)")
        }
    }
    
    private func logout() {
        appState.logout()
        dismiss()
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppStateViewModel())
}
