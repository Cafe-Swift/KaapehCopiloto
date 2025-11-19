//
//  ProducerHomeView.swift
//  KaapehCopiloto2
//
//  Created by Cafe Swift on 05/11/2025.
//

import SwiftUI
import SwiftData

struct ProducerHomeView: View {
    let user: UserProfile
    @Binding var selectedTab: Int
    @State private var viewModel: ProducerHomeViewModel
    @Environment(\.modelContext) private var modelContext
    @Environment(AccessibilityManager.self) private var accessibilityManager
    
    init(user: UserProfile, selectedTab: Binding<Int>, swiftDataService: SwiftDataService) {
        self.user = user
        self._selectedTab = selectedTab
        _viewModel = State(initialValue: ProducerHomeViewModel(user: user, swiftDataService: swiftDataService))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Fondo dinámico basado en configuración de accesibilidad
                accessibilityManager.backgroundColor
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Greeting Section
                        greetingSection
                        
                        // Quick Stats
                        statsSection
                        
                        // Main Actions
                        actionsSection
                        
                        // Recent Diagnoses
                        if !viewModel.recentDiagnoses.isEmpty {
                            recentDiagnosesSection
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Káapeh Copiloto")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color(red: 0.4, green: 0.26, blue: 0.13), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear {
                viewModel.loadData()
                viewModel.syncDataIfPossible()
            }
            .refreshable {
                viewModel.loadData()
                viewModel.syncDataIfPossible()
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
        }
    }
    
    // MARK: - View Components
    
    private var greetingSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.getGreeting())
                .font(.system(size: accessibilityManager.titleFontSize, weight: .bold))
                .foregroundStyle(accessibilityManager.primaryTextColor)
            
            Text("Tu cafetal en tu bolsillo")
                .font(.system(size: accessibilityManager.bodyFontSize))
                .foregroundStyle(accessibilityManager.secondaryTextColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(accessibilityManager.cardBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
    }
    
    private var statsSection: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            StatCard(
                title: "Diagnósticos",
                value: "\(viewModel.getTotalDiagnoses())",
                icon: "camera.fill",
                color: AppTheme.Colors.coffeeGreen
            )
            
            StatCard(
                title: "Tareas",
                value: "\(viewModel.getPendingTasks())",
                icon: "checklist",
                color: AppTheme.Colors.lightBrown
            )
        }
    }
    
    private var actionsSection: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            // AI Copilot Button - Cambia al tab 2 (Copiloto)
            Button {
                selectedTab = 2
            } label: {
                ActionCard(
                    icon: "brain.head.profile",
                    title: "Copiloto IA",
                    subtitle: "Pregunta lo que necesites",
                    gradient: AppTheme.Gradients.greenCoffeeGradient,
                    accentColor: AppTheme.Colors.coffeeGreen
                )
            }
            
            // Diagnosis Button - Cambia al tab 1 (Diagnóstico)
            Button {
                selectedTab = 1
            } label: {
                ActionCard(
                    icon: "camera.fill",
                    title: "Nuevo Diagnóstico",
                    subtitle: "Toma una foto de tu planta",
                    gradient: AppTheme.Gradients.coffeeGradient,
                    accentColor: AppTheme.Colors.coffeeBrown
                )
            }
            
            // History Button - Cambia al tab 3 (Historial)
            Button {
                selectedTab = 3
            } label: {
                ActionCard(
                    icon: "clock.fill",
                    title: "Ver Historial",
                    subtitle: "Revisa tus diagnósticos anteriores",
                    gradient: AppTheme.Gradients.lightCoffeeGradient,
                    accentColor: AppTheme.Colors.lightBrown
                )
            }
        }
    }
    
    private var recentDiagnosesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recientes")
                .font(.system(size: accessibilityManager.headlineFontSize, weight: .bold))
                .foregroundStyle(accessibilityManager.primaryTextColor)
            
            ForEach(viewModel.recentDiagnoses.prefix(3), id: \.recordId) { diagnosis in
                DiagnosisPreviewCard(diagnosis: diagnosis)
            }
        }
    }
}

// MARK: - Stat Card Component
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    @Environment(AccessibilityManager.self) private var accessibilityManager
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(color)
                .clipShape(Circle())
                .shadow(color: color.opacity(0.3), radius: 4, y: 2)
            
            Text(value)
                .font(.system(size: accessibilityManager.titleFontSize, weight: .bold))
                .foregroundStyle(accessibilityManager.primaryTextColor)
            
            Text(title)
                .font(.system(size: accessibilityManager.bodyFontSize))
                .foregroundStyle(accessibilityManager.secondaryTextColor)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(accessibilityManager.cardBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
    }
}

// MARK: - Action Card Component
struct ActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let gradient: LinearGradient
    let accentColor: Color
    @Environment(AccessibilityManager.self) private var accessibilityManager
    
    var body: some View {
        HStack(spacing: 16) {
            // Ícono circular con gradiente
            Image(systemName: icon)
                .font(.title)
                .foregroundStyle(.white)
                .frame(width: 64, height: 64)
                .background(gradient)
                .clipShape(Circle())
                .shadow(color: accentColor.opacity(0.3), radius: 6, y: 3)
            
            VStack(alignment: .leading, spacing: 6) {
                // Título dinámico
                Text(title)
                    .font(.system(size: accessibilityManager.headlineFontSize, weight: .bold))
                    .foregroundStyle(accessibilityManager.primaryTextColor)
                
                // Subtítulo dinámico
                Text(subtitle)
                    .font(.system(size: accessibilityManager.bodyFontSize))
                    .foregroundStyle(accessibilityManager.secondaryTextColor)
            }
            
            Spacer()
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.title3)
                .foregroundStyle(accessibilityManager.secondaryTextColor)
        }
        .padding(20)
        .background(accessibilityManager.cardBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
    }
}

// MARK: - Diagnosis Preview Card
struct DiagnosisPreviewCard: View {
    let diagnosis: DiagnosisRecord
    
    var body: some View {
        HStack(spacing: 16) {
            // Ícono de diagnóstico
            Image(systemName: iconForIssue(diagnosis.detectedIssue))
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(colorForIssue(diagnosis.detectedIssue))
                .clipShape(Circle())
                .shadow(color: colorForIssue(diagnosis.detectedIssue).opacity(0.3), radius: 4, y: 2)
            
            VStack(alignment: .leading, spacing: 6) {
                // Nombre del diagnóstico
                Text(diagnosis.detectedIssue)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color(red: 0.2, green: 0.13, blue: 0.07))
                
                Text(diagnosis.formattedDate)
                    .font(.system(size: 14))
                    .foregroundStyle(Color(red: 0.4, green: 0.26, blue: 0.13))
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 6) {
                // Porcentaje de confianza
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
        .padding(20)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
    }
    
    private func iconForIssue(_ issue: String) -> String {
        switch issue.lowercased() {
        case let x where x.contains("roya"):
            return "leaf.fill"
        case let x where x.contains("sano") || x.contains("sana"):
            return "checkmark.seal.fill"
        case let x where x.contains("nitrógeno") || x.contains("nitrogen"):
            return "exclamationmark.triangle.fill"
        default:
            return "info.circle.fill"
        }
    }
    
    private func colorForIssue(_ issue: String) -> Color {
        switch issue.lowercased() {
        case let x where x.contains("roya"):
            return .orange
        case let x where x.contains("sano") || x.contains("sana"):
            return AppTheme.Colors.coffeeGreen
        case let x where x.contains("nitrógeno") || x.contains("nitrogen"):
            return .yellow
        default:
            return AppTheme.Colors.coffeeBrown
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: UserProfile.self, AccessibilityConfig.self, DiagnosisRecord.self, ActionItem.self,
        configurations: config
    )
    
    let context = ModelContext(container)
    let service = SwiftDataService(modelContext: context)
    let user = UserProfile(userName: "testuser", role: "Productor", preferredLanguage: "es")
    
    ProducerHomeView(user: user, selectedTab: .constant(0), swiftDataService: service)
        .modelContainer(container)
        .environment(AccessibilityManager.shared)
}
