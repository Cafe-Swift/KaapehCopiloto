//
//  OnboardingView.swift
//  KaapehCopiloto
//
//  Created by Cafe Swift on 28/10/25.
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppStateViewModel
    @State private var currentPage = 0
    @State private var largeTextEnabled = false
    @State private var highContrastEnabled = false
    @State private var voiceInteractionPreferred = false
    
    var body: some View {
        TabView(selection: $currentPage) {
            // Página 1: Bienvenida
            welcomePage()
                .tag(0)
            
            // Página 2: Configuración de accesibilidad
            AccessibilityConfigPage(
                largeTextEnabled: $largeTextEnabled,
                highContrastEnabled: $highContrastEnabled,
                voiceInteractionPreferred: $voiceInteractionPreferred
            )
                .tag(1)
            
            // Página 3: Finalización
            CompletePage(
                largeTextEnabled: largeTextEnabled,
                highContrastEnabled: highContrastEnabled,
                voiceInteractionPreferred: voiceInteractionPreferred,
                onComplete: completeOnboarding
            )
                .tag(2)
        }
        .tabViewStyle(.page)
        .indexViewStyle(.page(backgroundDisplayMode: .always))
    }
    
    private func completeOnboarding() {
        let config = AccessibilityConfig(
            largeTextEnabled: largeTextEnabled,
            highContrastEnabled: highContrastEnabled,
            voiceInteractionPreferred: voiceInteractionPreferred
        )
        appState.completeOnboarding(accessibilityConfig: config)
    }
}

// welcome page
struct welcomePage: View {
    var body: some View {
        VStack (spacing: 30) {
            Spacer()
            
            Image(systemName: "hand.wave.fill")
                .font(.system(size: 100))
                .foregroundStyle(.green)
                .accessibilityLabel("Bienvenida")
            
            VStack (spacing: 15) {
                Text("¡Bienvenido!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .accessibilityAddTraits(.isHeader)
                
                Text("Vamos a personalizar tu experiencia para que sea más faicl de usar.")
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 40)
            }
            
            Text("Desliza para continuar →")
                .font(.caption)
                .foregroundStyle(.gray)
                .padding(.top, 20)
            
            Spacer()
        }
        .padding()
    }
}

// accessibility config page
struct AccessibilityConfigPage: View {
    @Binding var largeTextEnabled: Bool
    @Binding var highContrastEnabled: Bool
    @Binding var voiceInteractionPreferred: Bool
    
    var body: some View {
        VStack (spacing: 30) {
            Text("Configuración de Accesibilidad")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 40)
                .accessibilityAddTraits(.isHeader)
            
            VStack (spacing: 25) {
                // texto grande
                SettingToggleRow(
                    icon: "textformat.size",
                    title: "Texto Grande",
                    description: "Aumenta el tamaño del texto en toda la aplicación",
                    isOn: $largeTextEnabled
                )
                
                Divider()
                
                // alto contraste
                SettingToggleRow(
                    icon: "circle.lefthalf.fill",
                    title: "Alto Contraste",
                    description: "Mejora la visibilidad con colores más intensos",
                    isOn: $highContrastEnabled
                )
                
                Divider()
                
                // interacción por voz
                SettingToggleRow(
                    icon: "mic.fill",
                    title: "Preferir Voz",
                    description: "Habilita controles por voz y lectura de pantalla",
                    isOn: $voiceInteractionPreferred
                )
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(15)
            .shadow(radius: 5)
            .padding(.horizontal)
            
            Text("Puedes cambiar estas opciones después en Ajustes")
                .font(.caption)
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
        }
    }

}

// complete page
struct CompletePage: View {
    let largeTextEnabled: Bool
    let highContrastEnabled: Bool
    let voiceInteractionPreferred: Bool
    let onComplete: () -> Void
    
    var body: some View {
        VStack (spacing: 30) {
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 100))
                .foregroundStyle(.green)
                .accessibilityLabel("Icono de Completado")
            
            VStack(spacing: 15) {
                Text("¡Listo!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .accessibilityAddTraits(.isHeader)
                
                
                Text("Tu configuración ha sido guardada")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            
            // Resumen de configuración
            VStack (alignment: .leading, spacing: 10) {
                ConfigSummaryRow(
                    icon: "textformat.size",
                    text: "Texto Grande",
                    isEnabled: largeTextEnabled
                )
                ConfigSummaryRow (
                    icon: "circle.lefthalf.fill",
                    text: "Alto Contraste",
                    isEnabled: highContrastEnabled
                )
                ConfigSummaryRow (
                    icon: "mic.fill",
                    text: "Interracción por voz",
                    isEnabled: voiceInteractionPreferred
                )
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(10)
            .padding(.horizontal, 40)
            
            Button(action: onComplete) {
                Text("Comenzar")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(10)
            }
            .padding(.horizontal, 40)
            .padding(.top, 20)
            .accessibilityLabel("Botón Comenzar")
            .accessibilityHint("Toca para iniciar la aplicación")
            
            Spacer()
        }
    }
}

// helper views
struct SettingToggleRow: View {
    let icon: String
    let title: String
    let description: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack (spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.green)
                .frame(width: 30)
                .accessibilityHidden(true)
            
            VStack (alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .accessibilityLabel(title)
                .accessibilityValue(isOn ? "activado" : "desactivado")
        }
    }
}

struct ConfigSummaryRow: View {
    let icon: String
    let text: String
    let isEnabled: Bool
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(.green)
                .frame(width: 25)
                .accessibilityHidden(true)
            
            Text(text)
                .font(.subheadline)
            
            Spacer()
            
            Image(systemName: isEnabled ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(isEnabled ? .green : .gray)
                .accessibilityLabel(isEnabled ? "Activado" : "Desactivado")
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AppStateViewModel())
}
