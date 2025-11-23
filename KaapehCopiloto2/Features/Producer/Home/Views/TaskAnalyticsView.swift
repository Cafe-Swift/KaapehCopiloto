//
//  TaskAnalyticsView.swift
//  KaapehCopiloto2
//
//  Vista de Analytics y estadísticas de tareas
//

import SwiftUI
import Charts

// MARK: - Analytics Data Models

struct TaskCompletionData: Identifiable {
    let id = UUID()
    let date: Date
    let completed: Int
    let total: Int
    
    var completionRate: Double {
        guard total > 0 else { return 0 }
        return Double(completed) / Double(total)
    }
}

struct PriorityDistribution: Identifiable {
    let id = UUID()
    let priority: TaskPriority
    let count: Int
    
    var color: Color {
        switch priority {
        case .urgent: return .red
        case .high: return .orange
        case .medium: return .yellow
        case .low: return .green
        }
    }
}

struct CategoryDistribution: Identifiable {
    let id = UUID()
    let category: String
    let count: Int
}

// MARK: - Task Analytics View

struct TaskAnalyticsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AccessibilityManager.self) private var accessibilityManager
    var viewModel: TasksViewModel
    
    // Computed properties para analytics
    private var weeklyData: [TaskCompletionData] {
        generateWeeklyData()
    }
    
    private var priorityData: [PriorityDistribution] {
        generatePriorityData()
    }
    
    private var categoryData: [CategoryDistribution] {
        generateCategoryData()
    }
    
    private var averageCompletionTime: String {
        calculateAverageCompletionTime()
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // MARK: - Overview Stats
                    statsOverviewSection
                    
                    // MARK: - Completion Trend Chart
                    completionTrendSection
                    
                    // MARK: - Priority Distribution Chart
                    priorityDistributionSection
                    
                    // MARK: - Category Distribution Chart
                    categoryDistributionSection
                    
                    // MARK: - Performance Metrics
                    performanceMetricsSection
                }
                .padding()
            }
            .navigationTitle("📊 Analytics de Tareas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
        }
    }
    
    // MARK: - Stats Overview Section
    
    private var statsOverviewSection: some View {
        VStack(spacing: 12) {
            Text("Resumen General")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 12) {
                AnalyticsStatCard(
                    title: "Total",
                    value: "\(viewModel.totalCount)",
                    icon: "list.bullet",
                    color: .blue
                )
                
                AnalyticsStatCard(
                    title: "Completadas",
                    value: "\(viewModel.completedCount)",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
            }
            
            HStack(spacing: 12) {
                AnalyticsStatCard(
                    title: "Pendientes",
                    value: "\(viewModel.pendingCount)",
                    icon: "clock.fill",
                    color: .orange
                )
                
                AnalyticsStatCard(
                    title: "Vencidas",
                    value: "\(viewModel.overdueCount)",
                    icon: "exclamationmark.triangle.fill",
                    color: .red
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5)
    }
    
    // MARK: - Completion Trend Chart
    
    private var completionTrendSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tendencia de Completado (7 días)")
                .font(.headline)
            
            if weeklyData.isEmpty {
                Text("No hay datos suficientes")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
            } else {
                Chart(weeklyData) { data in
                    BarMark(
                        x: .value("Día", data.date, unit: .day),
                        y: .value("Completadas", data.completed)
                    )
                    .foregroundStyle(Color.green.gradient)
                    
                    BarMark(
                        x: .value("Día", data.date, unit: .day),
                        y: .value("Total", data.total - data.completed)
                    )
                    .foregroundStyle(Color.gray.gradient.opacity(0.3))
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { value in
                        if let date = value.as(Date.self) {
                            AxisValueLabel {
                                Text(date, format: .dateTime.weekday(.narrow))
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5)
    }
    
    // MARK: - Priority Distribution Chart
    
    private var priorityDistributionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Distribución por Prioridad")
                .font(.headline)
            
            if priorityData.isEmpty {
                Text("No hay tareas aún")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
            } else {
                Chart(priorityData) { item in
                    SectorMark(
                        angle: .value("Count", item.count),
                        innerRadius: .ratio(0.5),
                        angularInset: 2
                    )
                    .foregroundStyle(item.color)
                    .annotation(position: .overlay) {
                        if item.count > 0 {
                            VStack {
                                Text(item.priority.rawValue)
                                    .font(.caption2)
                                    .bold()
                                Text("\(item.count)")
                                    .font(.caption)
                            }
                            .foregroundColor(.white)
                        }
                    }
                }
                .frame(height: 200)
            }
            
            // Leyenda
            HStack(spacing: 16) {
                ForEach(priorityData) { item in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(item.color)
                            .frame(width: 10, height: 10)
                        Text("\(item.priority.rawValue): \(item.count)")
                            .font(.caption)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5)
    }
    
    // MARK: - Category Distribution Chart
    
    private var categoryDistributionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Distribución por Categoría")
                .font(.headline)
            
            if categoryData.isEmpty {
                Text("No hay categorías definidas")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 150)
            } else {
                Chart(categoryData) { item in
                    BarMark(
                        x: .value("Categoría", item.category),
                        y: .value("Cantidad", item.count)
                    )
                    .foregroundStyle(Color.blue.gradient)
                }
                .frame(height: 150)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5)
    }
    
    // MARK: - Performance Metrics Section
    
    private var performanceMetricsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Métricas de Rendimiento")
                .font(.headline)
            
            VStack(spacing: 8) {
                MetricRow(
                    title: "Tasa de Completado",
                    value: String(format: "%.1f%%", calculateCompletionRate() * 100),
                    icon: "chart.line.uptrend.xyaxis"
                )
                
                Divider()
                
                MetricRow(
                    title: "Tiempo Promedio de Completado",
                    value: averageCompletionTime,
                    icon: "clock"
                )
                
                Divider()
                
                MetricRow(
                    title: "Tareas por Día (Promedio)",
                    value: String(format: "%.1f", calculateTasksPerDay()),
                    icon: "calendar"
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5)
    }
    
    // MARK: - Helper Methods
    
    private func generateWeeklyData() -> [TaskCompletionData] {
        var data: [TaskCompletionData] = []
        let calendar = Calendar.current
        let today = Date()
        
        for dayOffset in (0..<7).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? date
            
            let tasksForDay = viewModel.filteredTasks.filter { task in
                task.createdAt >= startOfDay && task.createdAt < endOfDay
            }
            
            let completed = tasksForDay.filter { $0.isCompleted }.count
            
            data.append(TaskCompletionData(
                date: date,
                completed: completed,
                total: tasksForDay.count
            ))
        }
        
        return data
    }
    
    private func generatePriorityData() -> [PriorityDistribution] {
        var priorityCounts: [TaskPriority: Int] = [:]
        
        for task in viewModel.filteredTasks {
            priorityCounts[task.taskPriority, default: 0] += 1
        }
        
        return TaskPriority.allCases.compactMap { priority in
            guard let count = priorityCounts[priority], count > 0 else { return nil }
            return PriorityDistribution(priority: priority, count: count)
        }
    }
    
    private func generateCategoryData() -> [CategoryDistribution] {
        var categoryCounts: [String: Int] = [:]
        
        for task in viewModel.filteredTasks {
            if let category = task.category {
                categoryCounts[category, default: 0] += 1
            }
        }
        
        return categoryCounts.map { key, value in
            CategoryDistribution(category: key, count: value)
        }.sorted { $0.count > $1.count }
    }
    
    private func calculateCompletionRate() -> Double {
        guard viewModel.totalCount > 0 else { return 0 }
        return Double(viewModel.completedCount) / Double(viewModel.totalCount)
    }
    
    private func calculateTasksPerDay() -> Double {
        let allTasks = viewModel.filteredTasks
        guard !allTasks.isEmpty else { return 0 }
        
        let oldestTask = allTasks.min(by: { $0.createdAt < $1.createdAt })
        guard let oldestDate = oldestTask?.createdAt else { return 0 }
        
        let daysSinceOldest = Calendar.current.dateComponents([.day], from: oldestDate, to: Date()).day ?? 1
        let days = max(daysSinceOldest, 1)
        
        return Double(allTasks.count) / Double(days)
    }
    
    private func calculateAverageCompletionTime() -> String {
        let completedTasks = viewModel.filteredTasks.filter { $0.isCompleted && $0.completedAt != nil }
        
        guard !completedTasks.isEmpty else { return "N/A" }
        
        var totalMinutes: Double = 0
        for task in completedTasks {
            if let completedAt = task.completedAt {
                let interval = completedAt.timeIntervalSince(task.createdAt)
                totalMinutes += interval / 60
            }
        }
        
        let avgMinutes = totalMinutes / Double(completedTasks.count)
        
        if avgMinutes < 60 {
            return String(format: "%.0f min", avgMinutes)
        } else if avgMinutes < 1440 {
            return String(format: "%.1f horas", avgMinutes / 60)
        } else {
            return String(format: "%.1f días", avgMinutes / 1440)
        }
    }
}

// MARK: - Analytics Stat Card Component

struct AnalyticsStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.title2)
                .bold()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Metric Row Component

struct MetricRow: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            Text(title)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .bold()
        }
    }
}
