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
    
    @Environment(\.dismiss) private var dismiss
    @State private var showingFeedbackOptions = false
    
    var body: some View {
        ZStack {
            // Fondo crema limpio (consistente con toda la app)
            Color(red: 0.98, green: 0.96, blue: 0.93)
                .ignoresSafeArea()
            
            ScrollView {
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
                    
                    // Action Button
                    Button {
                        dismiss()
                    } label: {
                        Text("Continuar")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(
                                    colors: [Color(red: 0.6, green: 0.4, blue: 0.2), Color(red: 0.4, green: 0.26, blue: 0.13)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 24)
            }
        }
        .navigationTitle("Detalle")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color(red: 0.4, green: 0.26, blue: 0.13), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
    
    // MARK: - View Components
    
    private var resultHeader: some View {
        VStack(spacing: 16) {
            // Ícono grande con fondo circular de color
            Image(systemName: iconForIssue(diagnosis.detectedIssue))
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .foregroundStyle(.white)
                .frame(width: 120, height: 120)
                .background(colorForIssue(diagnosis.detectedIssue))
                .clipShape(Circle())
                .shadow(color: colorForIssue(diagnosis.detectedIssue).opacity(0.3), radius: 12, y: 6)
            
            Text(diagnosis.detectedIssue)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(Color(red: 0.2, green: 0.13, blue: 0.07))
                .multilineTextAlignment(.center)
            
            Text(diagnosis.formattedDate)
                .font(.subheadline)
                .foregroundStyle(Color(red: 0.4, green: 0.26, blue: 0.13))
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
        .padding(.horizontal)
    }
    
    private var confidenceBar: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Nivel de Confianza")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color(red: 0.2, green: 0.13, blue: 0.07))
                
                Spacer()
                
                Text(diagnosis.confidencePercentage)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(colorForIssue(diagnosis.detectedIssue))
            }
            
            // Barra de progreso
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Fondo de la barra
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 12)
                    
                    // Barra de progreso con color
                    RoundedRectangle(cornerRadius: 8)
                        .fill(colorForIssue(diagnosis.detectedIssue))
                        .frame(width: geometry.size.width * diagnosis.confidence, height: 12)
                }
            }
            .frame(height: 12)
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
        .padding(.horizontal)
    }
    
    private var feedbackSection: some View {
        VStack(spacing: 16) {
            Text("¿El diagnóstico fue correcto?")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color(red: 0.2, green: 0.13, blue: 0.07))
            
            HStack(spacing: 16) {
                // Botón SÍ
                Button {
                    onFeedback(true)
                    showingFeedbackOptions = false
                } label: {
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 40))
                        Text("Sí, correcto")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .foregroundStyle(.white)
                    .background(
                        LinearGradient(
                            colors: [Color(red: 0.2, green: 0.6, blue: 0.3), Color(red: 0.15, green: 0.5, blue: 0.25)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: Color(red: 0.2, green: 0.5, blue: 0.3).opacity(0.3), radius: 8, y: 4)
                }
                
                // Botón NO
                Button {
                    onFeedback(false)
                    showingFeedbackOptions = true
                } label: {
                    VStack(spacing: 12) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 40))
                        Text("No, incorrecto")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .foregroundStyle(.white)
                    .background(
                        LinearGradient(
                            colors: [Color.red.opacity(0.8), Color.red.opacity(0.6)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: Color.red.opacity(0.3), radius: 8, y: 4)
                }
            }
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
        .padding(.horizontal)
    }
    
    private var feedbackGivenSection: some View {
        VStack(spacing: 12) {
            Image(systemName: diagnosis.userFeedbackCorrect == true ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 40))
                .foregroundStyle(diagnosis.userFeedbackCorrect == true ? Color(red: 0.2, green: 0.5, blue: 0.3) : .red)
            
            Text(diagnosis.userFeedbackCorrect == true ? "Gracias por confirmar" : "Gracias por tu retroalimentación")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color(red: 0.2, green: 0.13, blue: 0.07))
            
            Text("Tu feedback nos ayuda a mejorar")
                .font(.caption)
                .foregroundStyle(Color(red: 0.4, green: 0.26, blue: 0.13))
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
        .padding(.horizontal)
    }
    
    private func diagnosisCard(explanation: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Explicación", systemImage: "info.circle.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color(red: 0.2, green: 0.13, blue: 0.07))
            
            Text(explanation)
                .font(.body)
                .foregroundStyle(Color(red: 0.3, green: 0.2, blue: 0.1))
                .lineSpacing(4)
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
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

#Preview {
    NavigationStack {
        DiagnosisResultView(
            diagnosis: DiagnosisRecord(
                timestamp: Date(),
                detectedIssue: "Planta Sana",
                confidence: 0.88
            ),
            onFeedback: { _ in }
        )
    }
}
