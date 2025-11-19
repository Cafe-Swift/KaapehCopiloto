//
//  OnboardingStepViews.swift
//  KaapehCopiloto2
//
//  Created by Cafe Swift Team on 05/11/25.
//

import SwiftUI

// MARK: - Large Text Step View

struct LargeTextStepView: View {
    @Binding var isEnabled: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "textformat.size")
                .resizable()
                .frame(width: 70, height: 70)
                .foregroundStyle(.white)
            
            Text("Texto grande")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            
            Text("¿Prefieres que el texto sea más grande para leer con mayor facilidad?")
                .font(isEnabled ? .title3 : .body)
                .foregroundStyle(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Toggle("Activar texto grande", isOn: $isEnabled)
                .toggleStyle(SwitchToggleStyle(tint: .green))
                .padding(.horizontal, 60)
                .foregroundStyle(.white)
        }
        .padding()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Texto grande. ¿Prefieres que el texto sea más grande para leer con mayor facilidad?")
    }
}

// MARK: - High Contrast Step View

struct HighContrastStepView: View {
    @Binding var isEnabled: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "circle.lefthalf.filled")
                .resizable()
                .frame(width: 70, height: 70)
                .foregroundStyle(.white)
            
            Text("Alto contraste")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            
            Text("¿Necesitas mayor contraste en los colores para ver mejor?")
                .font(.title3)
                .foregroundStyle(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Toggle("Activar alto contraste", isOn: $isEnabled)
                .toggleStyle(SwitchToggleStyle(tint: .green))
                .padding(.horizontal, 60)
                .foregroundStyle(.white)
        }
        .padding()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Alto contraste. ¿Necesitas mayor contraste en los colores para ver mejor?")
    }
}

// MARK: - Voice Interaction Step View

struct VoiceInteractionStepView: View {
    @Binding var isEnabled: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "mic.fill")
                .resizable()
                .frame(width: 70, height: 70)
                .foregroundStyle(.white)
            
            Text("Interacción por voz")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            
            Text("¿Te gustaría usar comandos de voz para interactuar con la aplicación?")
                .font(.title3)
                .foregroundStyle(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Toggle("Activar interacción por voz", isOn: $isEnabled)
                .toggleStyle(SwitchToggleStyle(tint: .green))
                .padding(.horizontal, 60)
                .foregroundStyle(.white)
        }
        .padding()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Interacción por voz. ¿Te gustaría usar comandos de voz para interactuar con la aplicación?")
    }
}

#Preview("Large Text") {
    ZStack {
        Color.black
        LargeTextStepView(isEnabled: Binding.constant(false))
    }
}

#Preview("High Contrast") {
    ZStack {
        Color.black
        HighContrastStepView(isEnabled: Binding.constant(false))
    }
}

#Preview("Voice") {
    ZStack {
        Color.black
        VoiceInteractionStepView(isEnabled: Binding.constant(false))
    }
}
