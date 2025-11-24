//
//  TasksListView.swift
//  KaapehCopiloto2
//
//  Vista principal de tareas con búsqueda, filtros y ordenamiento
//

import SwiftUI
import SwiftData

struct TasksListView: View {
    @Bindable var viewModel: TasksViewModel
    @Environment(AccessibilityManager.self) private var accessibilityManager
    @Environment(\.modelContext) private var modelContext
    
    @State private var showFilters: Bool = false
    @State private var showSortOptions: Bool = false
    @State private var showNotificationPermission: Bool = false
    @State private var showAnalytics: Bool = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.creamBrown.opacity(0.3)
                    .ignoresSafeArea()
                
                if viewModel.isLoading {
                    loadingView
                } else if viewModel.groupedTasks.isEmpty {
                    emptyStateView
                } else {
                    mainContent
                }
            }
            .navigationTitle("Mis Tareas")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(AppTheme.Colors.coffeeBrown, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    filterButton
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    sortButton
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    analyticsButton
                }
            }
            .searchable(
                text: $viewModel.searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Buscar tareas..."
            )
            .onAppear {
                viewModel.loadTasks()
                checkNotificationPermissions()
            }
            .sheet(isPresented: $showFilters) {
                filterSheet
            }
            .alert("Permisos de Notificaciones", isPresented: $showNotificationPermission) {
                Button("Configurar") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Más Tarde", role: .cancel) {}
            } message: {
                Text("Activa las notificaciones para recibir recordatorios de tus tareas.")
            }
            .sheet(isPresented: $showAnalytics) {
                TaskAnalyticsView(viewModel: viewModel)
            }
            .confetti(isActive: $viewModel.showConfetti)
        }
    }
    
    // MARK: - Main Content
    
    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Stats Cards
                statsCards
                
                // Active Filter Indicator
                if viewModel.selectedFilter != .all {
                    activeFilterBadge
                }
                
                // Tasks List
                if viewModel.filteredTasks.isEmpty {
                    noResultsView
                } else {
                    tasksListContent
                }
            }
            .padding()
        }
    }
    
    // MARK: - Stats Cards
    
    private var statsCards: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // Pendientes
                StatsCard(
                    title: "Pendientes",
                    count: viewModel.pendingCount,
                    icon: "circle",
                    color: .blue,
                    isSelected: viewModel.selectedFilter == .pending
                ) {
                    viewModel.selectedFilter = .pending
                }
                
                // Completadas
                StatsCard(
                    title: "Completadas",
                    count: viewModel.completedCount,
                    icon: "checkmark.circle.fill",
                    color: .green,
                    isSelected: viewModel.selectedFilter == .completed
                ) {
                    viewModel.selectedFilter = .completed
                }
                
                // Vencidas
                if viewModel.overdueCount > 0 {
                    StatsCard(
                        title: "Vencidas",
                        count: viewModel.overdueCount,
                        icon: "exclamationmark.triangle.fill",
                        color: .red,
                        isSelected: viewModel.selectedFilter == .overdue
                    ) {
                        viewModel.selectedFilter = .overdue
                    }
                }
                
                // Próximas
                if viewModel.dueSoonCount > 0 {
                    StatsCard(
                        title: "Próximas",
                        count: viewModel.dueSoonCount,
                        icon: "clock.badge.exclamationmark",
                        color: .orange,
                        isSelected: viewModel.selectedFilter == .dueSoon
                    ) {
                        viewModel.selectedFilter = .dueSoon
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }
    
    // MARK: - Tasks List Content
    
    private var tasksListContent: some View {
        LazyVStack(spacing: 16) {
            ForEach(viewModel.filteredTasks.sorted(by: { $0.sortOrder < $1.sortOrder }), id: \.taskId) { task in
                TaskItemRow(
                    task: task,
                    onToggle: {
                        withAnimation(.spring()) {
                            viewModel.toggleTask(task)
                        }
                    },
                    onPriorityChange: { newPriority in
                        viewModel.updatePriority(task: task, priority: newPriority)
                    },
                    onDueDateChange: { newDate in
                        viewModel.updateDueDate(task: task, date: newDate)
                    }
                )
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.white)
                        .shadow(color: AppTheme.Colors.coffeeBrown.opacity(0.15), radius: 8, x: 0, y: 4)
                )
                .padding(.horizontal, 4)
                // ⭐ Swipe to Delete (completadas)
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    if task.isCompleted {
                        Button(role: .destructive) {
                            deleteTask(task)
                        } label: {
                            Label("Eliminar", systemImage: "trash")
                        }
                    }
                }
                // ⭐ Swipe to Schedule Reminder
                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                    if !task.isCompleted {
                        Button {
                            scheduleQuickReminder(for: task)
                        } label: {
                            Label("Recordar", systemImage: "bell.badge")
                        }
                        .tint(.blue)
                    }
                }
            }
            .onMove { indices, newOffset in
                moveTask(from: indices, to: newOffset)
            }
        }
    }
    
    // MARK: - Filter Button
    
    private var filterButton: some View {
        Button {
            showFilters = true
        } label: {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .font(.title3)
                
                if viewModel.selectedFilter != .all {
                    Circle()
                        .fill(.red)
                        .frame(width: 8, height: 8)
                        .offset(x: 4, y: -4)
                }
            }
        }
    }
    
    // MARK: - Sort Button
    
    private var sortButton: some View {
        Menu {
            ForEach(TaskSort.allCases, id: \.self) { sort in
                Button {
                    viewModel.selectedSort = sort
                } label: {
                    HStack {
                        Text(sort.rawValue)
                        Spacer()
                        if viewModel.selectedSort == sort {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.blue)
                        }
                    }
                }
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down.circle")
                .font(.title3)
        }
    }
    
    // MARK: - Analytics Button
    
    private var analyticsButton: some View {
        Button {
            showAnalytics = true
        } label: {
            Image(systemName: "chart.bar.fill")
        }
        .sheet(isPresented: $showAnalytics) {
            TaskAnalyticsView(viewModel: viewModel)
        }
    }
    
    // MARK: - Filter Sheet
    
    private var filterSheet: some View {
        NavigationStack {
            List {
                Section("Filtros") {
                    ForEach(TaskFilter.allCases, id: \.self) { filter in
                        Button {
                            viewModel.selectedFilter = filter
                            showFilters = false
                        } label: {
                            HStack {
                                Text(filter.rawValue)
                                    .foregroundStyle(AppTheme.Colors.coffeeBrown)
                                
                                Spacer()
                                
                                if viewModel.selectedFilter == filter {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(AppTheme.Colors.coffeeGreen)
                                }
                            }
                        }
                    }
                }
                
                Section {
                    Button(role: .destructive) {
                        viewModel.deleteCompletedTasks()
                        showFilters = false
                    } label: {
                        Label("Eliminar Completadas", systemImage: "trash")
                    }
                    .disabled(viewModel.completedCount == 0)
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.Colors.creamBrown.opacity(0.3))
            .navigationTitle("Filtros y Acciones")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.Colors.coffeeBrown, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Listo") {
                        showFilters = false
                    }
                    .foregroundStyle(.white)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
    
    // MARK: - Helper Views
    
    private var activeFilterBadge: some View {
        HStack {
            Text("Filtro: \(viewModel.selectedFilter.rawValue)")
                .font(.caption)
                .foregroundStyle(AppTheme.Colors.coffeeBrown)
            
            Button {
                viewModel.selectedFilter = .all
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(AppTheme.Colors.coffeeBrown)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(AppTheme.Colors.creamBrown.opacity(0.7))
        .cornerRadius(16)
    }
    
    private var noResultsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundStyle(AppTheme.Colors.coffeeBrown.opacity(0.6))
            
            Text("No se encontraron tareas")
                .font(.title3.weight(.medium))
                .foregroundStyle(AppTheme.Colors.coffeeBrown)
            
            Text("Intenta cambiar los filtros o el término de búsqueda")
                .font(.subheadline)
                .foregroundStyle(AppTheme.Colors.coffeeBrown.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }
    
    private var loadingView: some View {
        VStack {
            ProgressView()
                .scaleEffect(1.5)
                .tint(AppTheme.Colors.coffeeBrown)
            
            Text("Cargando tareas...")
                .font(.subheadline)
                .foregroundStyle(AppTheme.Colors.coffeeBrown.opacity(0.7))
                .padding(.top)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 80))
                .foregroundStyle(AppTheme.Colors.coffeeGreen)
            
            Text("¡Todo en orden!")
                .font(.title.weight(.bold))
                .foregroundStyle(AppTheme.Colors.coffeeBrown)
            
            Text("No tienes tareas pendientes.\nCrea un diagnóstico para generar nuevas tareas.")
                .font(.body)
                .foregroundStyle(AppTheme.Colors.coffeeBrown.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }
    
    // MARK: - Actions
    
    private func deleteTask(_ task: ActionItem) {
        guard let context = SwiftDataService.shared.modelContext else { return }
        
        withAnimation {
            context.delete(task)
            try? context.save()
            viewModel.loadTasks()
        }
    }
    
    private func scheduleQuickReminder(for task: ActionItem) {
        // Programa recordatorio para 1 hora antes de la fecha de vencimiento
        guard let dueDate = task.dueDate else { return }
        
        let reminderDate = Calendar.current.date(
            byAdding: .hour,
            value: -1,
            to: dueDate
        ) ?? dueDate
        
        viewModel.scheduleReminder(task: task, reminderDate: reminderDate)
    }
    
    private func checkNotificationPermissions() {
        Task {
            await NotificationService.shared.checkAuthorizationStatus()
            
            if !NotificationService.shared.isAuthorized {
                showNotificationPermission = true
            }
        }
    }
    
    // MARK: - Drag & Drop Actions
    
    private func moveTask(from indices: IndexSet, to newOffset: Int) {
        var sortedTasks = viewModel.filteredTasks.sorted(by: { $0.sortOrder < $1.sortOrder })
        
        // Mover el item en el array
        sortedTasks.move(fromOffsets: indices, toOffset: newOffset)
        
        // Actualizar sortOrder para todos
        for (index, task) in sortedTasks.enumerated() {
            task.sortOrder = index
        }
        
        // Guardar cambios
        guard let context = SwiftDataService.shared.modelContext else { return }
        try? context.save()
        
        // Recargar
        viewModel.loadTasks()
    }
}

// MARK: - Stats Card Component

struct StatsCard: View {
    let title: String
    let count: Int
    let icon: String
    let color: Color
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: icon)
                        .foregroundStyle(color)
                    
                    Spacer()
                    
                    Text("\(count)")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(color)
                }
                
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .frame(width: 140)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? color.opacity(0.2) : Color(uiColor: .systemBackground))
                    .shadow(color: AppTheme.Colors.coffeeBrown.opacity(0.1), radius: 8, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? color : AppTheme.Colors.coffeeBrown.opacity(0.2), lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}
