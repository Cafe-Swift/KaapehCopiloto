//
//  HistoryListView.swift
//  KaapehCopiloto2
//
//  Created by Cafe Swift Team on 05/11/25.
//  UPDATED with AccessibilityManager support
//

import SwiftUI
import SwiftData

struct HistoryListView: View {
    let user: UserProfile
    @Environment(\.dismiss) var dismiss
    @Environment(AccessibilityManager.self) private var accessibilityManager
    @State private var viewModel: HistoryViewModel
    
    init(user: UserProfile) {
        self.user = user
        self._viewModel = State(initialValue: HistoryViewModel(user: user))
    }
    
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
            
            if viewModel.isLoading {
                ProgressView()
                    .tint(AppTheme.Colors.coffeeBrown)
                    .scaleEffect(1.5)
            } else if viewModel.diagnoses.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        // Header flotante moderno
                        modernHeader
                            .padding(.horizontal)
                            .padding(.top, 10)
                        
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.diagnoses, id: \.recordId) { diagnosis in
                                NavigationLink {
                                    DiagnosisResultViewWrapper(diagnosis: diagnosis)
                                } label: {
                                    DiagnosisHistoryCard(diagnosis: diagnosis)
                                }
                                .buttonStyle(DiagnosisCardButtonStyle())
                                .sensoryFeedback(.selection, trigger: diagnosis.recordId)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 20)
                }
                .refreshable {
                    viewModel.loadDiagnoses()
                }
            }
        }
    }
    
    // MARK: - Modern Header
    
    private var modernHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Historial")
                    .font(.system(size: accessibilityManager.titleFontSize, weight: .bold))
                    .foregroundStyle(accessibilityManager.primaryTextColor)
                
                Text("\(viewModel.diagnoses.count) diagnósticos")
                    .font(.system(size: accessibilityManager.captionFontSize))
                    .foregroundStyle(accessibilityManager.secondaryTextColor)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.15), radius: 12, y: 6)
        )
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                AppTheme.Colors.coffeeBrown.opacity(0.2),
                                AppTheme.Colors.coffeeBrown.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Image(systemName: "tray.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(AppTheme.Colors.coffeeBrown.opacity(0.6))
            }
            
            Text("No hay diagnósticos")
                .font(.system(size: accessibilityManager.headlineFontSize, weight: .bold))
                .foregroundStyle(accessibilityManager.primaryTextColor)
            
            Text("Toma tu primera foto para comenzar")
                .font(.system(size: accessibilityManager.bodyFontSize))
                .foregroundStyle(accessibilityManager.secondaryTextColor)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.15), radius: 12, y: 6)
        )
        .padding(.horizontal, 40)
    }
}

// MARK: - Diagnosis Result Wrapper
/// Wrapper para DiagnosisResultView cuando se accede desde el historial
/// Permite que el botón X funcione correctamente para regresar al historial
struct DiagnosisResultViewWrapper: View {
    let diagnosis: DiagnosisRecord
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        DiagnosisResultView(
            diagnosis: diagnosis,
            onFeedback: { _ in
                // El feedback no se puede cambiar desde el historial
            },
            onDismiss: {
                // El botón X regresa al historial
                dismiss()
            }
        )
        .navigationBarHidden(true)
    }
}

// MARK: - Diagnosis History Card
struct DiagnosisHistoryCard: View {
    let diagnosis: DiagnosisRecord
    @Environment(AccessibilityManager.self) private var accessibilityManager
    
    var body: some View {
        HStack(spacing: 16) {
            // Ícono circular con color del diagnóstico
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                colorForIssue,
                                colorForIssue.opacity(0.7)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                    .shadow(color: colorForIssue.opacity(0.4), radius: 8, y: 4)
                
                Image(systemName: iconForIssue)
                    .font(.system(size: 24))
                    .foregroundStyle(.white)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(diagnosis.detectedIssue)
                    .font(.system(size: accessibilityManager.headlineFontSize, weight: .semibold))
                    .foregroundStyle(accessibilityManager.primaryTextColor)
                    .lineLimit(2)
                
                HStack(spacing: 8) {
                    Label(diagnosis.formattedDate, systemImage: "calendar")
                        .font(.system(size: accessibilityManager.captionFontSize))
                        .foregroundStyle(accessibilityManager.secondaryTextColor)
                    
                    // Badge de confianza
                    HStack(spacing: 4) {
                        Image(systemName: "gauge.with.dots.needle.67percent")
                            .font(.system(size: 11))
                        Text(diagnosis.confidencePercentage)
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(confidenceColor)
                    )
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 8) {
                // Feedback visual
                if let feedback = diagnosis.userFeedbackCorrect {
                    ZStack {
                        Circle()
                            .fill(feedback ? Color(red: 0.2, green: 0.5, blue: 0.3).opacity(0.15) : Color.red.opacity(0.15))
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: feedback ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(feedback ? Color(red: 0.2, green: 0.5, blue: 0.3) : .red)
                    }
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color(red: 0.6, green: 0.4, blue: 0.2))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.15), radius: 12, y: 6)
        )
    }
    
    private var iconForIssue: String {
        switch diagnosis.detectedIssue.lowercased() {
        case let x where x.contains("roya"):
            return "exclamationmark.triangle.fill"
        case let x where x.contains("sano") || x.contains("sana"):
            return "checkmark.seal.fill"
        case let x where x.contains("nitrógeno") || x.contains("nitrogen"):
            return "leaf.fill"
        case let x where x.contains("plaga"):
            return "ant.fill"
        default:
            return "questionmark.circle.fill"
        }
    }
    
    private var colorForIssue: Color {
        switch diagnosis.detectedIssue.lowercased() {
        case let x where x.contains("roya"):
            return .orange
        case let x where x.contains("sano") || x.contains("sana"):
            return AppTheme.Colors.coffeeGreen
        case let x where x.contains("nitrógeno") || x.contains("nitrogen"):
            return .yellow
        case let x where x.contains("plaga"):
            return .purple
        default:
            return AppTheme.Colors.coffeeBrown
        }
    }
    
    private var confidenceColor: Color {
        if diagnosis.confidence >= 0.8 {
            return AppTheme.Colors.coffeeGreen
        } else if diagnosis.confidence >= 0.6 {
            return .orange
        } else {
            return .red
        }
    }
}

// MARK: - HistoryViewModel
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

// MARK: - Custom Button Style
struct DiagnosisCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: UserProfile.self, DiagnosisRecord.self,
        configurations: config
    )
    
    let user = UserProfile(userName: "testuser", role: "Productor", preferredLanguage: "es")
    
    HistoryListView(user: user)
        .modelContainer(container)
        .environment(AccessibilityManager.shared)
}
