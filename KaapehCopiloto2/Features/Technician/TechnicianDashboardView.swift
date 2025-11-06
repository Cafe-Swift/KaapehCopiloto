//
//  TechnicianDashboardView.swift
//  KaapehCopiloto2
//
//  Created by Cafe Swift Team on 05/11/25.
//

import SwiftUI
import SwiftData
import Charts

struct TechnicianDashboardView: View {
    @State private var viewModel: TechnicianDashboardViewModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var allDiagnoses: [DiagnosisRecord]
    
    init(swiftDataService: SwiftDataService, authToken: String? = nil, authViewModel: AuthenticationViewModel? = nil) {
        self._viewModel = State(initialValue: TechnicianDashboardViewModel(
            swiftDataService: swiftDataService,
            authToken: authToken,
            authViewModel: authViewModel
        ))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.98, green: 0.96, blue: 0.93)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        headerSection
                        kpiCardsSection
                        issueDistributionChart
                        recentActivitySection
                    }
                    .padding()
                }
                .refreshable {
                    await viewModel.refreshData()
                }
            }
            .navigationTitle("Dashboard Técnico")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color(red: 0.4, green: 0.26, blue: 0.13), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            Task { await viewModel.syncWithBackend() }
                        } label: {
                            Label("Sincronizar", systemImage: "arrow.triangle.2.circlepath")
                        }
                        
                        Button(role: .destructive) {
                            viewModel.logout()
                        } label: {
                            Label("Cerrar sesión", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle.fill")
                            .foregroundStyle(.white)
                    }
                }
            }
            .task {
                await viewModel.loadMetrics(diagnoses: allDiagnoses)
            }
            .alert("Cerrar Sesión", isPresented: $viewModel.showLogoutConfirmation) {
                Button("Cancelar", role: .cancel) { }
                Button("Cerrar Sesión", role: .destructive) {
                    viewModel.confirmLogout()
                }
            } message: {
                Text("¿Estás seguro de que quieres cerrar sesión?")
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK", role: .cancel) {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            }
            .onChange(of: viewModel.shouldLogout) { _, shouldLogout in
                if shouldLogout {
                    dismiss()
                }
            }
        }
    }
    
    private var liquidGlassBackground: some View {
        LinearGradient(
            colors: [
                Color(red: 0.2, green: 0.3, blue: 0.4),
                Color(red: 0.3, green: 0.4, blue: 0.3)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Dashboard de Métricas")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(Color(red: 0.2, green: 0.13, blue: 0.07))
            
            Text("Última actualización: \(Date().formatted(date: .abbreviated, time: .shortened))")
                .font(.subheadline)
                .foregroundStyle(Color(red: 0.4, green: 0.26, blue: 0.13))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
    }
    
    private var kpiCardsSection: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            KPICard(
                title: "Precisión Percibida",
                value: String(format: "%.1f%%", viewModel.tpp),
                subtitle: "TPP",
                icon: "checkmark.seal.fill",
                color: viewModel.tpp >= 90 ? .green : viewModel.tpp >= 70 ? .yellow : .red
            )
            
            KPICard(
                title: "Confiabilidad Modelo",
                value: String(format: "%.1f%%", viewModel.cpm),
                subtitle: "CPM",
                icon: "gauge.with.dots.needle.67percent",
                color: viewModel.cpm >= 85 ? .green : viewModel.cpm >= 70 ? .yellow : .red
            )
            
            KPICard(
                title: "Total Diagnósticos",
                value: "\(viewModel.totalDiagnoses)",
                subtitle: "Registros",
                icon: "chart.bar.fill",
                color: .blue
            )
            
            KPICard(
                title: "Con Feedback",
                value: "\(viewModel.diagnosesWithFeedback)",
                subtitle: "Validados",
                icon: "hand.thumbsup.fill",
                color: .purple
            )
        }
    }
    
    private var issueDistributionChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Distribución de Diagnósticos")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Color(red: 0.2, green: 0.13, blue: 0.07))
            
            if !viewModel.issueDistribution.isEmpty {
                Chart(viewModel.issueDistribution, id: \.issue) { item in
                    SectorMark(
                        angle: .value("Count", item.count),
                        innerRadius: .ratio(0.5),
                        angularInset: 2
                    )
                    .foregroundStyle(by: .value("Issue", item.issue))
                    .cornerRadius(5)
                }
                .frame(height: 250)
                .chartLegend(position: .bottom)
                
                // Lista de detalles con TEXTO NEGRO
                VStack(spacing: 12) {
                    ForEach(viewModel.issueDistribution, id: \.issue) { item in
                        HStack {
                            Circle()
                                .fill(colorForIssue(item.issue))
                                .frame(width: 12, height: 12)
                            
                            Text(item.issue)
                                .font(.subheadline)
                                .foregroundStyle(Color(red: 0.2, green: 0.13, blue: 0.07))
                            
                            Spacer()
                            
                            Text("\(item.count)")
                                .font(.headline)
                                .foregroundStyle(Color(red: 0.2, green: 0.13, blue: 0.07))
                            
                            Text("(\(Int(Double(item.count) / Double(viewModel.totalDiagnoses) * 100))%)")
                                .font(.caption)
                                .foregroundStyle(Color(red: 0.4, green: 0.26, blue: 0.13))
                        }
                        .padding(.horizontal)
                    }
                }
            } else {
                Text("No hay datos disponibles")
                    .font(.subheadline)
                    .foregroundStyle(Color(red: 0.4, green: 0.26, blue: 0.13))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
            }
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
    }
    
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Actividad Reciente")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Color(red: 0.2, green: 0.13, blue: 0.07))
            
            ForEach(Array(allDiagnoses.prefix(5))) { diagnosis in
                TechnicianDiagnosisCard(diagnosis: diagnosis)
            }
        }
    }
    
    private func colorForIssue(_ issue: String) -> Color {
        switch issue.lowercased() {
        case let i where i.contains("roya"): return .orange
        case let i where i.contains("sano"): return .green
        case let i where i.contains("nitrógeno"): return .yellow
        default: return .blue
        }
    }
}

struct TechnicianDiagnosisCard: View {
    let diagnosis: DiagnosisRecord
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconForIssue)
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(colorForIssue)
                .clipShape(Circle())
                .shadow(color: colorForIssue.opacity(0.3), radius: 4, y: 2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(diagnosis.detectedIssue)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color(red: 0.2, green: 0.13, blue: 0.07))
                
                Text(diagnosis.timestamp.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(Color(red: 0.4, green: 0.26, blue: 0.13))
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(diagnosis.confidence * 100))%")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(colorForIssue)
                
                if let feedback = diagnosis.userFeedbackCorrect {
                    Image(systemName: feedback ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(feedback ? Color(red: 0.2, green: 0.5, blue: 0.3) : .red)
                        .font(.title3)
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 6, y: 3)
    }
    
    private var colorForIssue: Color {
        switch diagnosis.detectedIssue.lowercased() {
        case let i where i.contains("roya"): return .orange
        case let i where i.contains("sano"): return .green
        case let i where i.contains("nitrógeno"): return .yellow
        default: return .blue
        }
    }
    
    private var iconForIssue: String {
        switch diagnosis.detectedIssue.lowercased() {
        case let i where i.contains("roya"): return "exclamationmark.triangle.fill"
        case let i where i.contains("sano"): return "checkmark.circle.fill"
        case let i where i.contains("nitrógeno"): return "leaf.fill"
        default: return "questionmark.circle.fill"
        }
    }
}


#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: UserProfile.self, DiagnosisRecord.self, AccessibilityConfig.self, ActionItem.self,
        configurations: config
    )
    
    TechnicianDashboardView(swiftDataService: SwiftDataService(modelContext: container.mainContext))
        .modelContainer(container)
}
