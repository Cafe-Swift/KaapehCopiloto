//
//  DiagnosisResultView.swift
//  KaapehCopiloto
//
//  Created by Marco Cafe Swift on 29/10/25.
//

import SwiftUI

struct DiagnosisResultView: View {
    @Environment(\.dismiss) var dismiss
    let result: DiagnosisResult
    @State private var userFeedback: Bool? = nil
    @State private var showingExplanation: Bool = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack (spacing: 30) {
                    // Ícono de resultado
                    Image(systemName: GetIconForIssue(result.detectedIssue))
                        .font(.system(size: 80))
                        .foregroundColor(getColorForIssue(result.detectedIssue))
                        .accessibilityLabel("Ícono de diagnóstico")
                    
                    // Resultado principal
                    VStack (spacing: 10) {
                        Text(result.detectedIssue)
                            .font(.title)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                            .accessibilityAddTraits(.isHeader)
                        
                        // Nivel de confianza
                        HStack (spacing: 8) {
                            Image(systemName: "chart.bar.fill")
                                .foregroundColor(.blue)
                                .accessibilityHidden(true)
                            
                            Text("Confiabilidad: \(Int(result.confidence * 100))%")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Confiabilidad del diagnóstico: \(Int(result.confidence * 100)) por ciento")
                    }
                    
                    // Feedback del usuario
                    VStack (spacing: 15) {
                        Text("¿Es correcto este diagnóstico?")
                            .font(.headline)
                            .accessibilityAddTraits(.isHeader)
                        
                        HStack (spacing: 20) {
                            FeedbackButton(
                                icon: "checkmark.circle.fill",
                                text: "Sí, correcto",
                                color: .green,
                                isSelected: userFeedback == true
                            ) {
                                userFeedback = true
                                provideFeedback(isCorrect: true)
                            }
                            
                            FeedbackButton (
                                icon: "xmark.circle.fill",
                                text: "No, incorrecto",
                                color: .red,
                                isSelected: userFeedback == false
                            ) {
                                userFeedback = false
                                provideFeedback(isCorrect: false)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(15)
                    .shadow(radius: 3)
                    .padding(.horizontal)
                    
                    // desccripcion breve
                    VStack (alignment: .leading, spacing: 10) {
                        Text("Información")
                            .font(.headline)
                            .accessibilityAddTraits(.isHeader)
                        
                        Text(getDescriptionForIssue(result.detectedIssue))
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    
                    // Explicación detallada
                    Button(action: { showingExplanation = true }) {
                        Label("Var Ecplicación Detallada y Plan de Acción", systemImage: "lightbulb.fill")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    .accessibilityLabel("Ver explicación detallada")
                    
                    // Botón finalizar
                    Button(action: {dismiss()}) {
                        Text("Finalizar")
                            .font(.headline)
                            .foregroundStyle(.green)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .overlay (
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.green, lineWidth: 2)
                            )
                    }
                    .padding(.horizontal)
                    .accessibilityLabel("Finalizar un diagnóstico")
                }
                .padding(.vertical)
            }
            .navigationTitle("Resultado")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingExplanation) {
                ChatView(initialContext: result.detectedIssue)
            }
        }
    }
    
    private func provideFeedback(isCorrect: Bool) {
        // TODO: Guardar feedback en SwiftData
        print("Feedback guardado: \(isCorrect ? "Correcto" : "Incorrecto")")
    }
    
    private func GetIconForIssue(_ issue: String) -> String {
        switch issue {
        case "Planta Sana":
            return "checkmark.seal.fill"
        case "Roya del Café":
            return "exclamationmark.triangle.fill"
        case "Deficiencia de Nitrogeno":
            return "leaf.fill"
        default:
            return "questionmark.circle.fill"
        }
    }
    
    private func getColorForIssue(_ issue: String) -> Color {
        switch issue {
        case "Planta Sana":
            return .green
        case "Roya del Café":
            return .orange
        case "Deficiencia de Nitrogeno":
            return .yellow
        default:
            return .blue
        }
    }
    
    private func getDescriptionForIssue(_ issue: String) -> String {
        switch issue {
        case "Planta Sana":
            return "Tu planta de café muestra signos saludables. Continúa con los cuidados regulares."
        case "Roya del Café":
            return "La roya es una enfermedad fúngica que afecta las hojas. Requiere atención inmediata para prevenir pérdidas."
        case "Deficiencia de Nitrogeno":
            return "Las hojas muestran signos de falta de nitrógeno. Se recomienda fertilización orgánica."
        default:
            return "Consulta con el copiloto para más información."
        }
    }
}

// feedback button component
struct FeedbackButton: View {
    let icon: String
    let text: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack (spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 40))
                    foregroundStyle(isSelected ? color : .gray)
                
                Text(text)
                    .font(.caption)
                    .foregroundStyle(isSelected ? color : .gray)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? color.opacity(0.1) : Color(.systemGray6))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? color : Color.clear, lineWidth: 2)
            )
        }
        .accessibilityLabel(text)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

#Preview {
    DiagnosisResultView(result: DiagnosisResult(
                        detectedIssue: "Roya del Café",
                        confidence: 0.92,
                        imagePath: nil
    ))
}
