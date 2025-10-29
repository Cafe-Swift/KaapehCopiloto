//
//  HistoryView.swift
//  KaapehCopiloto
//
//  Created by Cafe Swift on 29/10/25.
//

import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var appState: AppStateViewModel
    @State private var diagnosisHistory: [DiagnosisRecord] = []
    
    var body: some View {
        VStack {
            if diagnosisHistory.isEmpty {
                // estado vacio
                VStack (spacing: 20) {
                    Image(systemName: "clock.badge.questionmark")
                        .font(.system(size: 80))
                        .foregroundStyle(.gray)
                        .accessibilityLabel("Sin historial")
                    
                    Text("Sin diagnósticos aún")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Tus diagnósticos aparecerán aquí")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .padding()
            } else {
                List {
                    ForEach(diagnosisHistory) { diagnosis in
                        HistoryItemView(diagnosis: diagnosis)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Historial")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: loadHistory)
    }
    
    private func loadHistory() {
        guard let user = appState.currentUser else { return }
        diagnosisHistory = SwiftDataService.shared.fetchDiagnosisHistory(for: user)
    }
}

// history item view
struct HistoryItemView: View {
    let diagnosis: DiagnosisRecord
    
    var body: some View {
        HStack (spacing: 15) {
            // icono segun el diagnostico
            Image(systemName: getIcon())
                .font(.title2)
                .foregroundStyle(getColor())
                .frame(width: 40)
                .accessibilityHidden(true)
            
            VStack (alignment: .leading, spacing: 5) {
                Text(diagnosis.detectedIssue)
                    .font(.headline)
                
                HStack (spacing: 15) {
                    Label("\(Int(diagnosis.confidence * 100))%", systemImage: "chart.bar.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Label(diagnosis.timestamp.formatted(date: .abbreviated, time: .shortened), systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                // mostrar feedback si existe
                if let feedback = diagnosis.userFeedbackCorrect {
                    HStack (spacing: 5) {
                        Image(systemName: feedback ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(feedback ? .green : .red)
                            .font(.caption)
                        
                        Text(feedback ? "Confirmado" : "Corregido")
                            .font(.caption)
                            .foregroundStyle(feedback ? .green : .red)
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundStyle(.gray)
                .font(.caption)
                .accessibilityHidden(true)
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Diagnóstico: \(diagnosis.detectedIssue), Confiabilidad: \(Int(diagnosis.confidence * 100))%, Fecha: \(diagnosis.timestamp.formatted(date: .abbreviated, time: .shortened))")
    }
    
    private func getIcon() -> String {
        switch diagnosis.detectedIssue {
        case "Planta Sana":
            return "checkmark.seal.fill"
        case "Roya del Café":
            return "exclamationmark.triangle.fill"
        case "Deficiencia de Nitrógeno":
            return "leaf.fill"
        default:
            return "questionmark.circle.fill"
        }
    }
    
    private func getColor() -> Color {
        switch diagnosis.detectedIssue {
        case "Planta Sana":
            return .green
        case "Roya del Café":
            return .orange
        case "Deficiencia de Nitrógeno":
            return .yellow
        default:
            return .blue
        }
    }
}

#Preview {
    NavigationStack {
        HistoryView()
            .environmentObject(AppStateViewModel())
    }
}
