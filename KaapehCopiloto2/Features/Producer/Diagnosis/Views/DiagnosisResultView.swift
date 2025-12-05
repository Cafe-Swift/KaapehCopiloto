//
//  DiagnosisResultView.swift
//  KaapehCopiloto2
//
//  Created by Cafe Swift Team on 05/11/25.
//

import SwiftUI

struct DiagnosisResultView: View {
    let diagnosis: DiagnosisRecord
    let onFeedback: (Bool) -> Void
    let onDismiss: () -> Void
    
    @State private var showingFeedbackOptions = false
    @Environment(AccessibilityManager.self) private var accessibilityManager
    @ObservedObject private var translator = KaapehTranslator.shared
    
    var body: some View {
        ZStack {
            // Fondo degradado adaptable
            LinearGradient(
                colors: [
                    accessibilityManager.backgroundColor,
                    accessibilityManager.backgroundColor.opacity(0.95)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Header flotante moderno
                    modernHeader
                        .padding(.horizontal)
                        .padding(.top, 10)
                    
                    VStack(spacing: 24) {
                        // Result Header
                        resultHeader
                        
                        // Confidence Bar
                        confidenceBar
                        
                        // Feedback Section
                        if !diagnosis.hasFeedback {
                            feedbackSection
                        } else {
                            feedbackGivenSection
                        }
                        
                        // Diagnosis Info
                        if let explanation = diagnosis.aiExplanation {
                            diagnosisCard(explanation: explanation)
                        }
                    }
                    
                    Color.clear.frame(height: 20)
                }
                .padding(.bottom, 20)
            }
        }
        .navigationBarHidden(true)
    }
    
    // MARK: - Modern Header
    
    private var modernHeader: some View {
        HStack {
            LiquidGlassCircleButton(
                icon: "xmark",
                size: 44,
                backgroundColor: accessibilityManager.cardBackgroundColor,
                foregroundColor: AppTheme.Colors.coffeeBrown
            ) {
                onDismiss()
            }
            
            Spacer()
            
            Text(translator.t("Detalle del Diagnóstico"))
                .font(.system(size: accessibilityManager.headlineFontSize, weight: .bold))
                .foregroundStyle(accessibilityManager.primaryTextColor)
            
            Spacer()
            
            // Espacio para mantener el título centrado
            Color.clear.frame(width: 44, height: 44)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.15), radius: 12, y: 6)
        )
    }
    
    // MARK: - View Components
    
    private var resultHeader: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                colorForIssue(diagnosis.detectedIssue),
                                colorForIssue(diagnosis.detectedIssue).opacity(0.7)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .shadow(color: colorForIssue(diagnosis.detectedIssue).opacity(0.4), radius: 16, y: 8)
                
                Image(systemName: iconForIssue(diagnosis.detectedIssue))
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .foregroundStyle(.white)
            }
            
            Text(diagnosis.detectedIssue)
                .font(.system(size: accessibilityManager.titleFontSize, weight: .bold))
                .foregroundStyle(accessibilityManager.primaryTextColor)
                .multilineTextAlignment(.center)
            
            Text(diagnosis.formattedDate)
                .font(.system(size: accessibilityManager.captionFontSize))
                .foregroundStyle(accessibilityManager.secondaryTextColor)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.15), radius: 12, y: 6)
        )
        .padding(.horizontal)
    }
    
    private var confidenceBar: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Nivel de Confianza", systemImage: "gauge.with.dots.needle.67percent")
                    .font(.system(size: accessibilityManager.headlineFontSize, weight: .semibold))
                    .foregroundStyle(accessibilityManager.primaryTextColor)
                
                Spacer()
                
                Text(diagnosis.confidencePercentage)
                    .font(.system(size: accessibilityManager.headlineFontSize, weight: .bold))
                    .foregroundStyle(colorForIssue(diagnosis.detectedIssue))
            }
            
            // Barra de progreso moderna
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Fondo de la barra con glassmorphism
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                        .frame(height: 16)
                    
                    // Barra de progreso con degradado
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [
                                    colorForIssue(diagnosis.detectedIssue),
                                    colorForIssue(diagnosis.detectedIssue).opacity(0.7)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * diagnosis.confidence, height: 16)
                        .shadow(color: colorForIssue(diagnosis.detectedIssue).opacity(0.3), radius: 4, y: 2)
                }
            }
            .frame(height: 16)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.15), radius: 12, y: 6)
        )
        .padding(.horizontal)
    }
    
    private var feedbackSection: some View {
        VStack(spacing: 16) {
            Label("¿El diagnóstico fue correcto?", systemImage: "questionmark.bubble.fill")
                .font(.system(size: accessibilityManager.headlineFontSize, weight: .semibold))
                .foregroundStyle(accessibilityManager.primaryTextColor)
            
            HStack(spacing: 16) {
                // Botón SÍ
                Button {
                    onFeedback(true)
                    showingFeedbackOptions = false
                } label: {
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 48))
                        Text(translator.t("Sí, correcto"))
                            .font(.system(size: accessibilityManager.bodyFontSize, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 28)
                    .foregroundStyle(.white)
                    .background(
                        LinearGradient(
                            colors: [
                                AppTheme.Colors.coffeeGreen,
                                AppTheme.Colors.coffeeGreen.opacity(0.8)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: AppTheme.Colors.coffeeGreen.opacity(0.4), radius: 12, y: 6)
                }
                .sensoryFeedback(.success, trigger: diagnosis.userFeedbackCorrect)
                
                // Botón NO
                Button {
                    onFeedback(false)
                    showingFeedbackOptions = true
                } label: {
                    VStack(spacing: 12) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 48))
                        Text(translator.t("No, incorrecto"))
                            .font(.system(size: accessibilityManager.bodyFontSize, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 28)
                    .foregroundStyle(.white)
                    .background(
                        LinearGradient(
                            colors: [Color.red.opacity(0.9), Color.red.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: Color.red.opacity(0.4), radius: 12, y: 6)
                }
                .sensoryFeedback(.impact(weight: .medium), trigger: showingFeedbackOptions)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.15), radius: 12, y: 6)
        )
        .padding(.horizontal)
    }
    
    private var feedbackGivenSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: diagnosis.userFeedbackCorrect == true ?
                            [AppTheme.Colors.coffeeGreen, AppTheme.Colors.coffeeGreen.opacity(0.7)] :
                            [Color.red.opacity(0.9), Color.red.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .shadow(
                        color: (diagnosis.userFeedbackCorrect == true ? AppTheme.Colors.coffeeGreen : Color.red).opacity(0.4),
                        radius: 12,
                        y: 6
                    )
                
                Image(systemName: diagnosis.userFeedbackCorrect == true ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.white)
            }
            
            Text(diagnosis.userFeedbackCorrect == true ? "Gracias por confirmar" : "Gracias por tu retroalimentación")
                .font(.system(size: accessibilityManager.headlineFontSize, weight: .semibold))
                .foregroundStyle(accessibilityManager.primaryTextColor)
            
            Text(translator.t("Tu feedback nos ayuda a mejorar"))
                .font(.system(size: accessibilityManager.captionFontSize))
                .foregroundStyle(accessibilityManager.secondaryTextColor)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.15), radius: 12, y: 6)
        )
        .padding(.horizontal)
    }
    
    private func diagnosisCard(explanation: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(AppTheme.Colors.coffeeBrown)
                
                Text(translator.t("Explicación"))
                    .font(.system(size: accessibilityManager.headlineFontSize, weight: .semibold))
                    .foregroundStyle(accessibilityManager.primaryTextColor)
            }
            
            Text(explanation)
                .font(.system(size: accessibilityManager.bodyFontSize))
                .foregroundStyle(accessibilityManager.secondaryTextColor)
                .lineSpacing(6)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.15), radius: 12, y: 6)
        )
        .padding(.horizontal)
    }
    
    // MARK: - Helper Functions
    
    private func iconForIssue(_ issue: String) -> String {
        switch issue.lowercased() {
        case let x where x.contains("roya"):
            return "exclamationmark.triangle.fill"
        case let x where x.contains("sano") || x.contains("sana"):
            return "checkmark.seal.fill"
        case let x where x.contains("nitrógeno") || x.contains("nitrogen"):
            return "leaf.fill"
        default:
            return "questionmark.circle.fill"
        }
    }
    
    private func colorForIssue(_ issue: String) -> Color {
        switch issue.lowercased() {
        case let x where x.contains("roya"):
            return .orange
        case let x where x.contains("sano") || x.contains("sana"):
            return Color(red: 0.2, green: 0.5, blue: 0.3)
        case let x where x.contains("nitrógeno") || x.contains("nitrogen"):
            return .yellow.opacity(0.8)
        default:
            return .blue
        }
    }
}

// MARK: - Supporting Views

struct DetailRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    @Environment(AccessibilityManager.self) private var accessibilityManager
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13))
                    .foregroundStyle(accessibilityManager.secondaryTextColor)
                
                Text(value)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(accessibilityManager.primaryTextColor)
            }
            
            Spacer()
        }
    }
}

#Preview {
    NavigationStack {
        DiagnosisResultView(
            diagnosis: DiagnosisRecord(
                timestamp: Date(),
                detectedIssue: "Planta Sana",
                confidence: 0.88
            ),
            onFeedback: { _ in },
            onDismiss: { }
        )
    }
}
