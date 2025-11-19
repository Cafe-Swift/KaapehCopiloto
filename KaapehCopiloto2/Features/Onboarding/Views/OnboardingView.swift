//
//  OnboardingView.swift
//  KaapehCopiloto2
//
//  Created by Cafe Swift Team on 05/11/25.
//

import SwiftUI

struct OnboardingView: View {
    @Bindable var viewModel: OnboardingViewModel
    let user: UserProfile
    let onComplete: () -> Void
    
    var body: some View {
        ZStack {
            liquidGlassBackground
            
            VStack(spacing: 0) {
                // Progress indicator
                progressIndicator
                
                // Content
                TabView(selection: $viewModel.currentStep) {
                    WelcomeStepView()
                        .tag(0)
                    
                    LargeTextStepView(isEnabled: $viewModel.largeTextEnabled)
                        .tag(1)
                    
                    HighContrastStepView(isEnabled: $viewModel.highContrastEnabled)
                        .tag(2)
                    
                    VoiceInteractionStepView(isEnabled: $viewModel.voiceInteractionPreferred)
                        .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // Navigation buttons
                navigationButtons
            }
        }
        .environment(\.dynamicTypeSize, viewModel.largeTextEnabled ? .xxxLarge : .medium)
    }
    
    // MARK: - View Components
    
    private var liquidGlassBackground: some View {
        LinearGradient(
            colors: [
                Color(red: 0.3, green: 0.4, blue: 0.3),
                Color(red: 0.2, green: 0.3, blue: 0.4)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    private var progressIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<viewModel.totalSteps, id: \.self) { step in
                Capsule()
                    .fill(step <= viewModel.currentStep ? Color.white : Color.white.opacity(0.3))
                    .frame(height: 4)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
    }
    
    private var navigationButtons: some View {
        HStack(spacing: 16) {
            if viewModel.currentStep > 0 {
                Button {
                    viewModel.previousStep()
                } label: {
                    Text("Anterior")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .accessibilityLabel("Botón anterior")
            }
            
            Button {
                if viewModel.currentStep < viewModel.totalSteps - 1 {
                    viewModel.nextStep()
                } else {
                    Task {
                        await viewModel.completeOnboarding(for: user)
                        if viewModel.errorMessage == nil {
                            onComplete()
                        }
                    }
                }
            } label: {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text(viewModel.currentStep < viewModel.totalSteps - 1 ? "Siguiente" : "Comenzar")
                            .font(.headline)
                            .foregroundStyle(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white.opacity(0.4))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(viewModel.isLoading)
            .accessibilityLabel(viewModel.currentStep < viewModel.totalSteps - 1 ? "Botón siguiente" : "Botón comenzar")
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 40)
    }
}

// MARK: - Welcome Step View

struct WelcomeStepView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "hand.wave.fill")
                .resizable()
                .frame(width: 80, height: 80)
                .foregroundStyle(.white)
            
            Text("¡Bienvenido a Káapeh Copiloto!")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
            
            Text("Vamos a personalizar la aplicación para que sea más fácil de usar")
                .font(.title3)
                .foregroundStyle(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Bienvenido a Káapeh Copiloto. Vamos a personalizar la aplicación para que sea más fácil de usar")
    }
}

// MARK: - Preview

#Preview {
    OnboardingView(
        viewModel: OnboardingViewModel(),
        user: UserProfile(userName: "testuser"),
        onComplete: {}
    )
}
