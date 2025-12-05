//
//  OnboardingView.swift
//  KaapehCopiloto2
//
//  Created by Cafe Swift Team on 05/11/25.
//

import SwiftUI

struct OnboardingView: View {
    @Bindable var viewModel: OnboardingViewModel
    @Environment(AccessibilityManager.self) private var accessibilityManager
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
                Color(red: 0.98, green: 0.96, blue: 0.93),
                Color(red: 0.95, green: 0.93, blue: 0.90),
                Color(red: 0.92, green: 0.90, blue: 0.87)
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
                    .fill(step <= viewModel.currentStep ? AppTheme.Colors.coffeeBrown : AppTheme.Colors.coffeeBrown.opacity(0.3))
                    .frame(height: 6)
                    .frame(maxWidth: .infinity)
                    .shadow(color: step <= viewModel.currentStep ? AppTheme.Colors.coffeeBrown.opacity(0.3) : .clear, radius: 4, y: 2)
            }
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
        )
        .padding(.horizontal, 24)
        .padding(.top, 10)
    }
    
    private var navigationButtons: some View {
        HStack(spacing: 16) {
            if viewModel.currentStep > 0 {
                LiquidGlassCircleButton(
                    icon: "chevron.left",
                    size: 56,
                    backgroundColor: .white,
                    foregroundColor: AppTheme.Colors.coffeeBrown
                ) {
                    viewModel.previousStep()
                }
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
                HStack(spacing: 12) {
                    Text(viewModel.currentStep < viewModel.totalSteps - 1 ? "Siguiente" : "Completar")
                        .font(.system(size: 18, weight: .bold))
                    
                    Image(systemName: viewModel.currentStep < viewModel.totalSteps - 1 ? "chevron.right" : "checkmark.circle.fill")
                        .font(.system(size: 20, weight: .bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    LinearGradient(
                        colors: [AppTheme.Colors.coffeeBrown, AppTheme.Colors.coffeeBrown.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: AppTheme.Colors.coffeeBrown.opacity(0.4), radius: 12, y: 6)
            }
            .sensoryFeedback(.success, trigger: viewModel.currentStep)
            .accessibilityLabel(viewModel.currentStep < viewModel.totalSteps - 1 ? "Botón siguiente" : "Botón completar")
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
                .foregroundStyle(AppTheme.Colors.coffeeBrown)
            
            Text("¡Bienvenido a Káapeh Copiloto!")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.Colors.coffeeBrown)
                .multilineTextAlignment(.center)
            
            Text("Vamos a personalizar la aplicación para que sea más fácil de usar")
                .font(.title3)
                .foregroundStyle(AppTheme.Colors.coffeeBrown.opacity(0.8))
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
