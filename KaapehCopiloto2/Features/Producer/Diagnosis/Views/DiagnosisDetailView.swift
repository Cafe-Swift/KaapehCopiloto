//
//  DiagnosisDetailView.swift
//  KaapehCopiloto2
//
//  Created by Cafe Swift Team on 05/11/25.
//

import SwiftUI
import SwiftData

struct DiagnosisDetailView: View {
    let diagnosis: DiagnosisRecord
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var showingFeedback = false
    
    var body: some View {
        ZStack {
            liquidGlassBackground
            
            ScrollView {
                VStack(spacing: 24) {
                    // Diagnosis header
                    diagnosisHeader
                    
                    // Confidence meter
                    confidenceMeter
                    
                    // Feedback section
                    if diagnosis.userFeedbackCorrect == nil {
                        feedbackSection
                    } else {
                        feedbackDisplay
                    }
                    
                    // AI Explanation
                    if let explanation = diagnosis.aiExplanation {
                        explanationSection(explanation)
                    }
                    
                    // Action items
                    if let items = diagnosis.actionPlanItems, !items.isEmpty {
                        actionItemsSection
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Detalle")
        .navigationBarTitleDisplayMode(.inline)
    }
    
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
    
    private var diagnosisHeader: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(issueColor.opacity(0.3))
                    .frame(width: 100, height: 100)
                
                Image(systemName: issueIcon)
                    .font(.system(size: 50))
                    .foregroundStyle(issueColor)
            }
            
            Text(diagnosis.detectedIssue)
                .font(.title.bold())
                .foregroundStyle(.white)
            
            Text(diagnosis.timestamp.formatted(date: .long, time: .shortened))
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.15))
        )
    }
    
    private var confidenceMeter: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Nivel de Confianza")
                    .font(.headline)
                    .foregroundStyle(.white)
                
                Spacer()
                
                Text("\(Int(diagnosis.confidence * 100))%")
                    .font(.title2.bold())
                    .foregroundStyle(confidenceColor)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 20)
                    
                    RoundedRectangle(cornerRadius: 8)
                        .fill(confidenceColor)
                        .frame(width: geometry.size.width * diagnosis.confidence, height: 20)
                }
            }
            .frame(height: 20)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
        )
    }
    
    private var feedbackSection: some View {
        VStack(spacing: 16) {
            Text("¿El diagnóstico fue correcto?")
                .font(.headline)
                .foregroundStyle(.white)
            
            HStack(spacing: 16) {
                Button {
                    saveFeedback(isCorrect: true)
                } label: {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Sí, correcto")
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green.opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                Button {
                    showingFeedback = true
                } label: {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                        Text("No, incorrecto")
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red.opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
        )
        .alert("Diagnóstico Incorrecto", isPresented: $showingFeedback) {
            Button("Cancelar", role: .cancel) { }
            Button("Confirmar") {
                saveFeedback(isCorrect: false)
            }
        } message: {
            Text("Gracias por tu feedback. Esto nos ayuda a mejorar el modelo.")
        }
    }
    
    private var feedbackDisplay: some View {
        HStack {
            Image(systemName: diagnosis.userFeedbackCorrect == true ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.title)
                .foregroundStyle(diagnosis.userFeedbackCorrect == true ? .green : .red)
            
            Text(diagnosis.userFeedbackCorrect == true ? "Diagnóstico confirmado como correcto" : "Diagnóstico marcado como incorrecto")
                .font(.headline)
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
        )
    }
    
    private func explanationSection(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(.yellow)
                Text("Explicación")
                    .font(.headline)
            }
            .foregroundStyle(.white)
            
            Text(text)
                .font(.body)
                .foregroundStyle(.white.opacity(0.9))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
        )
    }
    
    private var actionItemsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "list.bullet.clipboard")
                    .foregroundStyle(.blue)
                Text("Plan de Acción")
                    .font(.headline)
            }
            .foregroundStyle(.white)
            
            ForEach(diagnosis.actionPlanItems ?? []) { item in
                HStack {
                    Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(item.isCompleted ? .green : .white.opacity(0.5))
                    
                    Text(item.descriptionText)
                        .font(.body)
                        .foregroundStyle(.white)
                        .strikethrough(item.isCompleted)
                    
                    Spacer()
                }
                .padding(.vertical, 8)
                .onTapGesture {
                    toggleActionItem(item)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
        )
    }
    
    // MARK: - Actions
    
    private func saveFeedback(isCorrect: Bool) {
        do {
            try SwiftDataService.shared.updateDiagnosisFeedback(
                record: diagnosis,
                isCorrect: isCorrect,
                correctedIssue: nil
            )
        } catch {
            print("Error saving feedback: \(error)")
        }
    }
    
    private func toggleActionItem(_ item: ActionItem) {
        do {
            try SwiftDataService.shared.toggleActionItemCompletion(item: item)
        } catch {
            print("Error toggling action item: \(error)")
        }
    }
    
    // MARK: - Helpers
    
    private var issueColor: Color {
        switch diagnosis.detectedIssue.lowercased() {
        case let issue where issue.contains("roya"):
            return .orange
        case let issue where issue.contains("sano"):
            return .green
        case let issue where issue.contains("nitrógeno"):
            return .yellow
        default:
            return .blue
        }
    }
    
    private var issueIcon: String {
        switch diagnosis.detectedIssue.lowercased() {
        case let issue where issue.contains("roya"):
            return "exclamationmark.triangle.fill"
        case let issue where issue.contains("sano"):
            return "checkmark.circle.fill"
        case let issue where issue.contains("nitrógeno"):
            return "leaf.fill"
        default:
            return "questionmark.circle.fill"
        }
    }
    
    private var confidenceColor: Color {
        diagnosis.confidence >= 0.8 ? .green : diagnosis.confidence >= 0.6 ? .yellow : .orange
    }
}
