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
                // Pendientes - Marrón café
                    StatsCard(
                    title: "Pendientes",
                    count: viewModel.pendingCount,
                    icon: "circle",
                    color: AppTheme.Colors.coffeeBrown,
                    isSelected: viewModel.selectedFilter == .pending
                ) {
                    viewModel.selectedFilter = .pending
                }
                
                // Completadas - Verde café
                StatsCard(
                    title: "Completadas",
                    count: viewModel.completedCount,
                    icon: "checkmark.circle.fill",
                    color: AppTheme.Colors.coffeeGreen,
                    isSelected: viewModel.selectedFilter == .completed
                ) {
                    viewModel.selectedFilter = .completed
                }
                
                // Vencidas - Marrón oscuro (espresso)
                if viewModel.overdueCount > 0 {
                    StatsCard(
                        title: "Vencidas",
                        count: viewModel.overdueCount,
                        icon: "exclamationmark.triangle.fill",
                        color: AppTheme.Colors.espresso,
                        isSelected: viewModel.selectedFilter == .overdue
                    ) {
                        viewModel.selectedFilter = .overdue
                    }
                }
                
                // Próximas - Marrón claro
                if viewModel.dueSoonCount > 0 {
                    StatsCard(
                        title: "Próximas",
                        count: viewModel.dueSoonCount,
                        icon: "clock.badge.exclamationmark",
                        color: AppTheme.Colors.lightBrown,
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
            ForEach(viewModel.visibleFilteredTasks.sorted(by: { $0.sortOrder < $1.sortOrder }), id: \.taskId) { task in
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
                // Swipe to Hide
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    if task.isCompleted {
                        Button {
                            withAnimation(.spring()) {
                                viewModel.hideCompletedTask(task)
                            }
                        } label: {
                            Label("Ocultar", systemImage: "eye.slash.fill")
                        }
                        .tint(AppTheme.Colors.coffeeBrown)
                    }
                }
                // Swipe to Schedule Reminder
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
            ZStack {
                AppTheme.Colors.creamBrown.opacity(0.3)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Sección de Filtros Rápidos
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Filtros Rápidos")
                                .font(.headline)
                                .foregroundStyle(accessibilityManager.primaryTextColor)
                                .padding(.horizontal)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 12) {
                                ForEach(TaskFilter.allCases, id: \.self) { filter in
                                    FilterChip(
                                        title: filter.rawValue,
                                        isSelected: viewModel.selectedFilter == filter,
                                        icon: filterIcon(for: filter)
                                    ) {
                                        withAnimation(.spring()) {
                                            viewModel.selectedFilter = filter
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        Divider()
                            .padding(.vertical, 8)
                        
                        // Sección de Ordenamiento
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Ordenar por")
                                .font(.headline)
                                .foregroundStyle(accessibilityManager.primaryTextColor)
                                .padding(.horizontal)
                            
                            VStack(spacing: 8) {
                                ForEach(TaskSort.allCases, id: \.self) { sort in
                                    Button {
                                        withAnimation(.spring()) {
                                            viewModel.selectedSort = sort
                                        }
                                    } label: {
                                        HStack {
                                            Image(systemName: sortIcon(for: sort))
                                                .frame(width: 24)
                                                .foregroundStyle(
                                                    viewModel.selectedSort == sort ?
                                                    AppTheme.Colors.coffeeGreen :
                                                    AppTheme.Colors.coffeeBrown.opacity(0.6)
                                                )
                                            
                                            Text(sort.rawValue)
                                                .font(.system(size: accessibilityManager.bodyFontSize))
                                                .foregroundStyle(
                                                    viewModel.selectedSort == sort ?
                                                    accessibilityManager.primaryTextColor :
                                                    accessibilityManager.secondaryTextColor
                                                )
                                            
                                            Spacer()
                                            
                                            if viewModel.selectedSort == sort {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundStyle(AppTheme.Colors.coffeeGreen)
                                            }
                                        }
                                        .padding()
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(
                                                    viewModel.selectedSort == sort ?
                                                    AppTheme.Colors.coffeeGreen.opacity(0.1) :
                                                    .white
                                                )
                                        )
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        Divider()
                            .padding(.vertical, 8)
                        
                        // Sección de Acciones
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Acciones")
                                .font(.headline)
                                .foregroundStyle(accessibilityManager.primaryTextColor)
                                .padding(.horizontal)
                            
                            VStack(spacing: 8) {
                                // Mostrar tareas ocultas
                                if !viewModel.hiddenCompletedTaskIds.isEmpty {
                                    Button {
                                        withAnimation(.spring()) {
                                            viewModel.showAllHiddenTasks()
                                        }
                                    } label: {
                                        HStack {
                                            Image(systemName: "eye.fill")
                                                .frame(width: 24)
                                                .foregroundStyle(AppTheme.Colors.coffeeGreen)
                                            
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text("Mostrar tareas ocultas")
                                                    .font(.system(size: accessibilityManager.bodyFontSize))
                                                    .foregroundStyle(accessibilityManager.primaryTextColor)
                                                
                                                Text("\(viewModel.hiddenCompletedTaskIds.count) ocultas")
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                            
                                            Spacer()
                                        }
                                        .padding()
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(.white)
                                        )
                                    }
                                }
                                
                                // Eliminar completadas (permanente)
                                Button(role: .destructive) {
                                    viewModel.deleteCompletedTasks()
                                    showFilters = false
                                } label: {
                                    HStack {
                                        Image(systemName: "trash.fill")
                                            .frame(width: 24)
                                            .foregroundStyle(.red)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Eliminar completadas permanentemente")
                                                .font(.system(size: accessibilityManager.bodyFontSize))
                                                .foregroundStyle(.red)
                                            
                                            Text("Esta acción no se puede deshacer")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        
                                        Spacer()
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(.white)
                                    )
                                }
                                .disabled(viewModel.completedCount == 0)
                                .opacity(viewModel.completedCount == 0 ? 0.5 : 1.0)
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Filtros y Opciones")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.Colors.coffeeBrown, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Listo") {
                        showFilters = false
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    
    // Helper para iconos de filtros
    private func filterIcon(for filter: TaskFilter) -> String {
        switch filter {
        case .all: return "list.bullet"
        case .pending: return "circle"
        case .completed: return "checkmark.circle.fill"
        case .overdue: return "exclamationmark.triangle.fill"
        case .dueSoon: return "clock.badge.exclamationmark"
        case .highPriority: return "flag.fill"
        }
    }
    
    // Helper para iconos de ordenamiento
    private func sortIcon(for sort: TaskSort) -> String {
        switch sort {
        case .dueDate: return "calendar"
        case .priority: return "flag.fill"
        case .createdDate: return "clock"
        case .alphabetical: return "textformat.abc"
        }
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
    @Environment(AccessibilityManager.self) private var accessibilityManager
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    // Icono con círculo de fondo
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(isSelected ? .white : color)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(isSelected ? color : color.opacity(0.15))
                        )
                    
                    Spacer()
                    
                    // Contador
                    Text("\(count)")
                        .font(.system(size: accessibilityManager.titleFontSize, weight: .bold))
                        .foregroundStyle(isSelected ? AppTheme.Colors.coffeeBrown : color)
                }
                
                // Título
                Text(title)
                    .font(.system(size: accessibilityManager.bodyFontSize, weight: .medium))
                    .foregroundStyle(isSelected ? AppTheme.Colors.coffeeBrown : AppTheme.Colors.coffeeBrown.opacity(0.7))
            }
            .padding(16)
            .frame(width: 140, height: 100)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? AppTheme.Colors.creamBrown.opacity(0.8) : .white)
                    .shadow(
                        color: isSelected ? color.opacity(0.3) : AppTheme.Colors.coffeeBrown.opacity(0.1),
                        radius: isSelected ? 12 : 8,
                        x: 0,
                        y: isSelected ? 6 : 4
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? color : AppTheme.Colors.coffeeBrown.opacity(0.15), lineWidth: isSelected ? 2.5 : 1.5)
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Filter Chip Component

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let icon: String
    let onTap: () -> Void
    
    @Environment(AccessibilityManager.self) private var accessibilityManager
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundStyle(isSelected ? .white : AppTheme.Colors.coffeeBrown)
                
                Text(title)
                    .font(.system(size: accessibilityManager.captionFontSize, weight: .medium))
                    .foregroundStyle(isSelected ? .white : AppTheme.Colors.coffeeBrown)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? AppTheme.Colors.coffeeBrown : .white)
                    .shadow(
                        color: isSelected ? AppTheme.Colors.coffeeBrown.opacity(0.3) : AppTheme.Colors.coffeeBrown.opacity(0.1),
                        radius: isSelected ? 8 : 4,
                        x: 0,
                        y: 2
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? AppTheme.Colors.coffeeBrown : AppTheme.Colors.coffeeBrown.opacity(0.2),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .scaleEffect(isSelected ? 1.03 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}
