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
                        categoryDistributionSection
                        
                        // SECCIONES DE ANALYTICS AVANZADAS
                        if viewModel.isLoadingAnalytics {
                            ProgressView("Cargando estadísticas avanzadas...")
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else {
                            frequentIssuesSection
                            trendsChartSection
                            heatmapSection
                            feedbackAnalysisSection
                            activeUsersSection
                        }
                        
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
                    .foregroundStyle(colorForIssue(item.issue))
                    .cornerRadius(5)
                }
                .frame(height: 250)
                .chartLegend(.hidden)
                
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
    
    // MARK: - Category Distribution Section
    private var categoryDistributionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Distribución por Categoría")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Color(red: 0.2, green: 0.13, blue: 0.07))
            
            if viewModel.isLoadingCategories {
                ProgressView("Cargando categorías...")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else if !viewModel.categoryDistribution.isEmpty {
                categoryChart
            } else {
                Text("No hay datos de categorías disponibles")
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
    
    private var categoryChart: some View {
        VStack(spacing: 16) {
            Chart {
                ForEach(Array(viewModel.categoryDistribution.keys.sorted()), id: \.self) { category in
                    let count = viewModel.categoryDistribution[category] ?? 0
                    
                    SectorMark(
                        angle: .value("Conteo", count),
                        innerRadius: .ratio(0.5),
                        angularInset: 2
                    )
                    .foregroundStyle(by: .value("Categoría", category))
                    .annotation(position: .overlay) {
                        if count > 0 {
                            VStack(spacing: 4) {
                                Text("\(count)")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Text(categoryPercentage(count))
                                    .font(.system(size: 10))
                                    .foregroundColor(.white.opacity(0.9))
                            }
                        }
                    }
                }
            }
            .frame(height: 300)
            .chartLegend(position: .bottom, alignment: .leading, spacing: 12)
            .chartForegroundStyleScale([
                "Deficiencias Nutricionales": Color.orange,
                "Enfermedades": Color.red,
                "Plagas": Color.purple,
                "Planta Saludable": Color.green,
                "Otros": Color.gray
            ])
        }
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
    
    
    // MARK: - Analytics Avanzadas Sections
    
    /// Sección 1: Top Problemas Más Frecuentes
    private var frequentIssuesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.doc.horizontal.fill")
                    .font(.title2)
                    .foregroundStyle(Color(red: 0.8, green: 0.4, blue: 0.2))
                
                Text("Diagnósticos Más Frecuentes")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color(red: 0.2, green: 0.13, blue: 0.07))
            }
            
            if !viewModel.frequentIssues.isEmpty {
                VStack(spacing: 12) {
                    ForEach(Array(viewModel.frequentIssues.prefix(10))) { issue in
                        HStack(spacing: 12) {
                            // Ranking badge
                            Text("#\(viewModel.frequentIssues.firstIndex(where: { $0.id == issue.id })! + 1)")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 32, height: 32)
                                .background(rankColor(for: viewModel.frequentIssues.firstIndex(where: { $0.id == issue.id })! + 1))
                                .clipShape(Circle())
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(issue.issue)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(Color(red: 0.2, green: 0.13, blue: 0.07))
                                
                                HStack(spacing: 8) {
                                    Label("\(issue.count) casos", systemImage: "number.circle.fill")
                                        .font(.caption)
                                        .foregroundStyle(Color(red: 0.4, green: 0.26, blue: 0.13))
                                    
                                    Label(String(format: "%.1f%% del total", issue.percentage), systemImage: "chart.pie.fill")
                                        .font(.caption)
                                        .foregroundStyle(Color(red: 0.6, green: 0.4, blue: 0.2))
                                }
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text(String(format: "%.0f%%", issue.avgConfidence * 100))
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundStyle(confidenceColor(issue.avgConfidence))
                                
                                Text("confianza")
                                    .font(.caption2)
                                    .foregroundStyle(Color(red: 0.4, green: 0.26, blue: 0.13))
                            }
                        }
                        .padding(12)
                        .background(Color(red: 0.99, green: 0.98, blue: 0.96))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            } else {
                emptyStateView(message: "No hay datos de problemas frecuentes")
            }
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
    }
    
    /// Sección 2: Gráfica de Tendencias
    private var trendsChartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.xyaxis.line")
                    .font(.title2)
                    .foregroundStyle(Color(red: 0.2, green: 0.5, blue: 0.7))
                
                Text("Tendencias (30 días)")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color(red: 0.2, green: 0.13, blue: 0.07))
            }
            
            if let trends = viewModel.trends, !trends.dataPoints.isEmpty {
                Chart {
                    ForEach(trends.dataPoints) { point in
                        LineMark(
                            x: .value("Fecha", parseTrendDate(point.date)),
                            y: .value("Total", point.totalDiagnoses)
                        )
                        .foregroundStyle(Color(red: 0.2, green: 0.5, blue: 0.7))
                        .lineStyle(StrokeStyle(lineWidth: 3))
                        .symbol {
                            Circle()
                                .fill(Color(red: 0.2, green: 0.5, blue: 0.7))
                                .frame(width: 8, height: 8)
                        }
                        
                        AreaMark(
                            x: .value("Fecha", parseTrendDate(point.date)),
                            y: .value("Total", point.totalDiagnoses)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.2, green: 0.5, blue: 0.7).opacity(0.3),
                                    Color(red: 0.2, green: 0.5, blue: 0.7).opacity(0.05)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    }
                }
                .frame(height: 220)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 5)) { value in
                        if let date = value.as(Date.self) {
                            AxisValueLabel {
                                Text(date, format: .dateTime.day().month(.abbreviated))
                                    .font(.caption2)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel()
                        AxisGridLine()
                    }
                }
                
                // Estadísticas resumidas
                HStack(spacing: 20) {
                    trendStat(
                        title: "Total",
                        value: "\(trends.dataPoints.map { $0.totalDiagnoses }.reduce(0, +))",
                        icon: "sum",
                        color: .blue
                    )
                    
                    trendStat(
                        title: "Promedio",
                        value: "\(trends.dataPoints.map { $0.totalDiagnoses }.reduce(0, +) / trends.dataPoints.count)",
                        icon: "chart.bar.fill",
                        color: .green
                    )
                    
                    if let max = trends.dataPoints.map({ $0.totalDiagnoses }).max() {
                        trendStat(
                            title: "Pico",
                            value: "\(max)",
                            icon: "arrow.up.circle.fill",
                            color: .orange
                        )
                    }
                }
                .padding(.top, 8)
            } else {
                emptyStateView(message: "No hay datos de tendencias")
            }
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
    }
    
    /// Sección 3: Mapa de Calor por Ubicación
    private var heatmapSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "map.fill")
                    .font(.title2)
                    .foregroundStyle(Color(red: 0.8, green: 0.3, blue: 0.3))
                
                Text("Distribución Geográfica")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color(red: 0.2, green: 0.13, blue: 0.07))
            }
            
            if !viewModel.heatmapLocations.isEmpty {
                VStack(spacing: 12) {
                    ForEach(viewModel.heatmapLocations) { location in
                        HStack(spacing: 12) {
                            Image(systemName: "location.fill")
                                .font(.title3)
                                .foregroundStyle(.white)
                                .frame(width: 44, height: 44)
                                .background(
                                    LinearGradient(
                                        colors: [Color(red: 0.8, green: 0.3, blue: 0.3), Color(red: 0.6, green: 0.2, blue: 0.2)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .clipShape(Circle())
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(location.location)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(Color(red: 0.2, green: 0.13, blue: 0.07))
                                
                                HStack(spacing: 6) {
                                    Text("\(location.diagnosesCount) diagnósticos")
                                        .font(.caption)
                                        .foregroundStyle(Color(red: 0.4, green: 0.26, blue: 0.13))
                                    
                                    Text("•")
                                        .foregroundStyle(Color(red: 0.6, green: 0.4, blue: 0.2))
                                    
                                    Text(location.mostCommonIssue)
                                        .font(.caption)
                                        .foregroundStyle(Color(red: 0.6, green: 0.4, blue: 0.2))
                                        .lineLimit(1)
                                }
                            }
                            
                            Spacer()
                            
                            // Indicador de intensidad
                            Circle()
                                .fill(heatIntensityColor(location.diagnosesCount, max: viewModel.heatmapLocations.map { $0.diagnosesCount }.max() ?? 1))
                                .frame(width: 40, height: 40)
                                .overlay {
                                    Text(String(format: "%.0f%%", location.avgConfidence * 100))
                                        .font(.caption2.bold())
                                        .foregroundStyle(.white)
                                }
                        }
                        .padding(12)
                        .background(Color(red: 0.99, green: 0.98, blue: 0.96))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            } else {
                emptyStateView(message: "No hay datos de ubicaciones")
            }
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
    }
    
    /// Sección 4: Análisis de Feedback
    private var feedbackAnalysisSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.pie.fill")
                    .font(.title2)
                    .foregroundStyle(Color(red: 0.3, green: 0.6, blue: 0.3))
                
                Text("Análisis de Precisión")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color(red: 0.2, green: 0.13, blue: 0.07))
            }
            
            if let feedback = viewModel.feedbackAnalysis {
                // KPI Cards de precisión
                HStack(spacing: 12) {
                    VStack(spacing: 8) {
                        Text(String(format: "%.1f%%", feedback.accuracyRate))
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(Color(red: 0.3, green: 0.6, blue: 0.3))
                        
                        Text("Precisión General")
                            .font(.caption)
                            .foregroundStyle(Color(red: 0.4, green: 0.26, blue: 0.13))
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(red: 0.3, green: 0.6, blue: 0.3).opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    VStack(spacing: 8) {
                        Text("\(feedback.correctDiagnoses)")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(.green)
                        
                        Text("Correctos")
                            .font(.caption)
                            .foregroundStyle(Color(red: 0.4, green: 0.26, blue: 0.13))
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    VStack(spacing: 8) {
                        Text("\(feedback.incorrectDiagnoses)")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(.red)
                        
                        Text("Incorrectos")
                            .font(.caption)
                            .foregroundStyle(Color(red: 0.4, green: 0.26, blue: 0.13))
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                // Problemas con más errores
                if !feedback.issuesWithMostErrors.isEmpty {
                    Text("Problemas con más errores:")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color(red: 0.4, green: 0.26, blue: 0.13))
                        .padding(.top, 8)
                    
                    VStack(spacing: 8) {
                        ForEach(feedback.issuesWithMostErrors.prefix(5)) { issue in
                            HStack {
                                Text(issue.issue)
                                    .font(.subheadline)
                                    .foregroundStyle(Color(red: 0.2, green: 0.13, blue: 0.07))
                                
                                Spacer()
                                
                                Text("\(issue.incorrect)/\(issue.total)")
                                    .font(.caption.bold())
                                    .foregroundStyle(.red)
                                
                                Text("(\(String(format: "%.0f%%", issue.accuracy)) precisión)")
                                    .font(.caption2)
                                    .foregroundStyle(Color(red: 0.6, green: 0.4, blue: 0.2))
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(Color(red: 0.99, green: 0.98, blue: 0.96))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
            } else {
                emptyStateView(message: "No hay datos de feedback")
            }
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
    }
    
    /// Sección 5: Usuarios Más Activos
    private var activeUsersSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "person.3.fill")
                    .font(.title2)
                    .foregroundStyle(Color(red: 0.5, green: 0.3, blue: 0.7))
                
                Text("Usuarios Más Activos")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color(red: 0.2, green: 0.13, blue: 0.07))
            }
            
            if !viewModel.activeUsers.isEmpty {
                VStack(spacing: 10) {
                    ForEach(Array(viewModel.activeUsers.prefix(10))) { user in
                        HStack(spacing: 12) {
                            // Ranking
                            ZStack {
                                Circle()
                                    .fill(userRankColor(viewModel.activeUsers.firstIndex(where: { $0.id == user.id })! + 1))
                                    .frame(width: 36, height: 36)
                                
                                Text("#\(viewModel.activeUsers.firstIndex(where: { $0.id == user.id })! + 1)")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(user.displayName)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(Color(red: 0.2, green: 0.13, blue: 0.07))
                                
                                HStack(spacing: 6) {
                                    Label("\(user.totalDiagnoses)", systemImage: "doc.fill")
                                        .font(.caption)
                                        .foregroundStyle(Color(red: 0.4, green: 0.26, blue: 0.13))
                                    
                                    if let lastActivity = user.lastActivity {
                                        Text("•")
                                            .font(.caption2)
                                            .foregroundStyle(Color(red: 0.6, green: 0.4, blue: 0.2))
                                        
                                        Text(formatActivityDate(lastActivity))
                                            .font(.caption2)
                                            .foregroundStyle(Color(red: 0.6, green: 0.4, blue: 0.2))
                                    }
                                }
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(user.mostCommonIssue)
                                    .font(.caption.bold())
                                    .foregroundStyle(Color(red: 0.8, green: 0.4, blue: 0.2))
                                    .lineLimit(1)
                                
                                Text("Más frecuente")
                                    .font(.caption2)
                                    .foregroundStyle(Color(red: 0.6, green: 0.4, blue: 0.2))
                            }
                        }
                        .padding(10)
                        .background(Color(red: 0.99, green: 0.98, blue: 0.96))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            } else {
                emptyStateView(message: "No hay datos de usuarios")
            }
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
    }
    
    // MARK: - Helper Views
    
    private func trendStat(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Color(red: 0.2, green: 0.13, blue: 0.07))
            
            Text(title)
                .font(.caption2)
                .foregroundStyle(Color(red: 0.6, green: 0.4, blue: 0.2))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(red: 0.99, green: 0.98, blue: 0.96))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
    private func emptyStateView(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 48))
                .foregroundStyle(Color(red: 0.6, green: 0.4, blue: 0.2).opacity(0.3))
            
            Text(message)
                .font(.subheadline)
                .foregroundStyle(Color(red: 0.4, green: 0.26, blue: 0.13))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
        // MARK: - Helper Functions
    
    private func categoryPercentage(_ count: Int) -> String {
        let total = viewModel.categoryDistribution.values.reduce(0, +)
        guard total > 0 else { return "0%" }
        let percentage = (Double(count) / Double(total)) * 100
        return String(format: "%.1f%%", percentage)
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



    // MARK: - Analytics Helper Functions
    
    private func rankColor(for rank: Int) -> Color {
        switch rank {
        case 1: return Color(red: 1.0, green: 0.84, blue: 0.0) // Gold
        case 2: return Color(red: 0.75, green: 0.75, blue: 0.75) // Silver
        case 3: return Color(red: 0.8, green: 0.5, blue: 0.2) // Bronze
        default: return Color(red: 0.4, green: 0.26, blue: 0.13)
        }
    }
    
    private func confidenceColor(_ confidence: Double) -> Color {
        if confidence >= 0.9 {
            return Color(red: 0.2, green: 0.5, blue: 0.3)
        } else if confidence >= 0.7 {
            return Color(red: 0.8, green: 0.6, blue: 0.2)
        } else {
            return Color(red: 0.8, green: 0.3, blue: 0.3)
        }
    }
    
    private func heatIntensityColor(_ count: Int, max: Int) -> Color {
        let intensity = Double(count) / Double(max)
        
        if intensity >= 0.8 {
            return Color(red: 0.8, green: 0.2, blue: 0.2)
        } else if intensity >= 0.5 {
            return Color(red: 0.9, green: 0.5, blue: 0.2)
        } else if intensity >= 0.3 {
            return Color(red: 0.9, green: 0.7, blue: 0.3)
        } else {
            return Color(red: 0.3, green: 0.6, blue: 0.9)
        }
    }
    
    private func userRankColor(_ rank: Int) -> Color {
        switch rank {
        case 1: return Color(red: 1.0, green: 0.84, blue: 0.0) // Gold
        case 2: return Color(red: 0.75, green: 0.75, blue: 0.75) // Silver
        case 3: return Color(red: 0.8, green: 0.5, blue: 0.2) // Bronze
        case 4...10: return Color(red: 0.5, green: 0.3, blue: 0.7)
        default: return Color(red: 0.6, green: 0.4, blue: 0.2)
        }
    }
    
    private func parseTrendDate(_ dateString: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dateString) ?? Date()
    }
    
    private func formatActivityDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: dateString) else { return "Hace tiempo" }
        
        let now = Date()
        let components = Calendar.current.dateComponents([.day, .hour, .minute], from: date, to: now)
        
        if let days = components.day, days > 0 {
            return "Hace \(days)d"
        } else if let hours = components.hour, hours > 0 {
            return "Hace \(hours)h"
        } else if let minutes = components.minute, minutes > 0 {
            return "Hace \(minutes)m"
        } else {
            return "Justo ahora"
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
