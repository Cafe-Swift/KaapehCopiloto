//
//  HistoryListView.swift
//  KaapehCopiloto2
//
//  Created by Cafe Swift Team on 05/11/25.
//

import SwiftUI
import SwiftData

struct HistoryListView: View {
    let user: UserProfile
    @Environment(\.dismiss) var dismiss
    @State private var viewModel: HistoryViewModel
    
    init(user: UserProfile) {
        self.user = user
        self._viewModel = State(initialValue: HistoryViewModel(user: user))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Fondo crema limpio
                Color(red: 0.98, green: 0.96, blue: 0.93)
                    .ignoresSafeArea()
                
                if viewModel.isLoading {
                    ProgressView()
                        .tint(Color(red: 0.4, green: 0.26, blue: 0.13))
                        .scaleEffect(1.5)
                } else if viewModel.diagnoses.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.diagnoses, id: \.recordId) { diagnosis in
                                NavigationLink {
                                    DiagnosisResultView(
                                        diagnosis: diagnosis,
                                        onFeedback: { _ in },
                                        onDismiss: { } 
                                    )
                                } label: {
                                    DiagnosisHistoryCard(diagnosis: diagnosis)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 20)
                    }
                }
            }
            .navigationTitle("Historial")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color(red: 0.4, green: 0.26, blue: 0.13), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.white)
                            .font(.title2)
                    }
                    .accessibilityLabel("Cerrar")
                }
            }
            .refreshable {
                viewModel.loadDiagnoses()
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "tray.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .foregroundStyle(Color(red: 0.4, green: 0.26, blue: 0.13).opacity(0.6))
            
            Text("No hay diagnósticos")
                .font(.title2.bold())
                .foregroundStyle(Color(red: 0.2, green: 0.13, blue: 0.07))
            
            Text("Toma tu primera foto para comenzar")
                .font(.body)
                .foregroundStyle(Color(red: 0.4, green: 0.26, blue: 0.13))
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
        .padding(.horizontal, 40)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No hay diagnósticos. Toma tu primera foto para comenzar")
    }
}

struct DiagnosisHistoryCard: View {
    let diagnosis: DiagnosisRecord
    
    var body: some View {
        HStack(spacing: 16) {
            // Ícono circular con color del diagnóstico
            Image(systemName: iconForIssue(diagnosis.detectedIssue))
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(colorForIssue(diagnosis.detectedIssue))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 6) {
                Text(diagnosis.detectedIssue)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color(red: 0.2, green: 0.13, blue: 0.07))
                
                Text(diagnosis.formattedDate)
                    .font(.subheadline)
                    .foregroundStyle(Color(red: 0.4, green: 0.26, blue: 0.13))
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 6) {
                Text(diagnosis.confidencePercentage)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(colorForIssue(diagnosis.detectedIssue))
                
                if let feedback = diagnosis.userFeedbackCorrect {
                    Image(systemName: feedback ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(feedback ? Color(red: 0.2, green: 0.5, blue: 0.3) : .red)
                        .font(.title3)
                }
            }
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(diagnosis.detectedIssue), \(diagnosis.confidencePercentage) de confianza, \(diagnosis.formattedDate)")
    }
    
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

@MainActor
@Observable
final class HistoryViewModel {
    var user: UserProfile
    var diagnoses: [DiagnosisRecord] = []
    var isLoading: Bool = false
    var errorMessage: String?
    
    private let dataService = SwiftDataService.shared
    
    init(user: UserProfile) {
        self.user = user
        loadDiagnoses()
    }
    
    func loadDiagnoses() {
        isLoading = true
        errorMessage = nil
        
        do {
            diagnoses = try dataService.fetchDiagnosisHistory(for: user, limit: 50)
            isLoading = false
        } catch {
            errorMessage = "Error al cargar diagnósticos: \(error.localizedDescription)"
            isLoading = false
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: UserProfile.self, DiagnosisRecord.self, AccessibilityConfig.self, ActionItem.self,
        configurations: config
    )
    
    let user = UserProfile(userName: "testuser", role: "Productor", preferredLanguage: "es")
    
    HistoryListView(user: user)
        .modelContainer(container)
}
