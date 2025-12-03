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
        Group {
            if viewModel.visibleFilteredTasks.isEmpty {
            // Caso vacío: usar ScrollView simple
            ScrollView {
                VStack(spacing: 16) {
                    // Stats Cards que hacen scroll
                    statsCards
                        .padding(.horizontal)
                        .padding(.top, 8)
                    
                    // Active Filter Indicator
                    if viewModel.selectedFilter != .all {
                        activeFilterBadge
                            .padding(.horizontal)
                    }
                    
                    noResultsView
                        .padding()
                        .padding(.top, 20)
                }
            }
        } else {
            // Caso con tareas: usar List con header
            List {
                // SECCIÓN 1: Stats Cards como header de la lista
                Section {
                    EmptyView()
                } header: {
                    VStack(spacing: 12) {
                        statsCards
                            .padding(.top, 8)
                        
                        // Active Filter Indicator
                        if viewModel.selectedFilter != .all {
                            activeFilterBadge
                        }
                    }
                    .padding(.bottom, 8)
                    .frame(maxWidth: .infinity)
                    .listRowInsets(EdgeInsets())
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                
                // SECCIÓN 2: Tareas
                Section {
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
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.white)
                                .shadow(
                                    color: AppTheme.Colors.coffeeBrown.opacity(0.1),
                                    radius: 4,
                                    x: 0,
                                    y: 2
                                )
                        )
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
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
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(AppTheme.Colors.creamBrown.opacity(0.3))
            .scrollDismissesKeyboard(.interactively)
            }
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
            .padding(.horizontal, 16)
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
    
    // MARK: - Filter Sheet (Coffee Theme Design)
    
    private var filterSheet: some View {
        NavigationStack {
            ZStack {
                // Fondo crema consistente con la app
                (accessibilityManager.isHighContrastEnabled ?
                 Color.black :
                 AppTheme.Colors.creamBrown.opacity(0.3))
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // SECCIÓN: Filtros Rápidos
                        VStack(alignment: .leading, spacing: 14) {
                            // Header con estilo café
                            HStack(spacing: 10) {
                                Image(systemName: "line.3.horizontal.decrease.circle.fill")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundStyle(AppTheme.Colors.coffeeBrown)
                                
                                Text("Filtros Rápidos")
                                    .font(.system(size: accessibilityManager.titleFontSize, weight: .bold))
                                    .foregroundStyle(accessibilityManager.primaryTextColor)
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                            
                            // Grid de filtros
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
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                            viewModel.selectedFilter = filter
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.white)
                                .shadow(
                                    color: AppTheme.Colors.coffeeBrown.opacity(0.15),
                                    radius: 8,
                                    x: 0,
                                    y: 4
                                )
                        )
                        .padding(.horizontal, 16)
                        
                        // SECCIÓN: Ordenar por
                        VStack(alignment: .leading, spacing: 14) {
                            // Header con icono
                            HStack(spacing: 10) {
                                Image(systemName: "arrow.up.arrow.down.circle.fill")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundStyle(AppTheme.Colors.coffeeGreen)
                                
                                Text("Ordenar por")
                                    .font(.system(size: accessibilityManager.titleFontSize, weight: .bold))
                                    .foregroundStyle(accessibilityManager.primaryTextColor)
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                            
                            // Opciones de ordenamiento
                            VStack(spacing: 10) {
                                ForEach(TaskSort.allCases, id: \.self) { sort in
                                    Button {
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                            viewModel.selectedSort = sort
                                        }
                                    } label: {
                                        HStack(spacing: 12) {
                                            // Icono con círculo - estilo consistente con StatsCard
                                            Image(systemName: sortIcon(for: sort))
                                                .font(.system(size: 18, weight: .semibold))
                                                .foregroundStyle(
                                                    viewModel.selectedSort == sort ?
                                                    .white :
                                                    AppTheme.Colors.coffeeGreen
                                                )
                                                .frame(width: 40, height: 40)
                                                .background(
                                                    Circle()
                                                        .fill(
                                                            viewModel.selectedSort == sort ?
                                                            AppTheme.Colors.coffeeGreen :
                                                            AppTheme.Colors.coffeeGreen.opacity(0.15)
                                                        )
                                                )
                                            
                                            Text(sort.rawValue)
                                                .font(.system(size: accessibilityManager.bodyFontSize, weight: .medium))
                                                .foregroundStyle(accessibilityManager.primaryTextColor)
                                            
                                            Spacer()
                                            
                                            if viewModel.selectedSort == sort {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .font(.system(size: 24))
                                                    .foregroundStyle(AppTheme.Colors.coffeeGreen)
                                                    .transition(.scale.combined(with: .opacity))
                                            }
                                        }
                                        .padding(.horizontal, 18)
                                        .padding(.vertical, 14)
                                        .background(
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(
                                                    viewModel.selectedSort == sort ?
                                                    AppTheme.Colors.coffeeGreen.opacity(0.12) :
                                                    Color.white.opacity(accessibilityManager.isHighContrastEnabled ? 1.0 : 0.85)
                                                )
                                                .shadow(
                                                    color: viewModel.selectedSort == sort ?
                                                    AppTheme.Colors.coffeeGreen.opacity(0.2) :
                                                    AppTheme.Colors.coffeeBrown.opacity(0.08),
                                                    radius: viewModel.selectedSort == sort ? 8 : 4,
                                                    x: 0,
                                                    y: viewModel.selectedSort == sort ? 3 : 2
                                                )
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(
                                                    viewModel.selectedSort == sort ?
                                                    LinearGradient(
                                                        colors: [
                                                            AppTheme.Colors.coffeeGreen,
                                                            AppTheme.Colors.coffeeGreen.opacity(0.6)
                                                        ],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    ) :
                                                    LinearGradient(
                                                        colors: [Color.clear, Color.clear],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    ),
                                                    lineWidth: viewModel.selectedSort == sort ? 1.5 : 0
                                                )
                                        )
                                        .scaleEffect(viewModel.selectedSort == sort ? 1.02 : 1.0)
                                    }
                                    .sensoryFeedback(.selection, trigger: viewModel.selectedSort)
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.white)
                                .shadow(
                                    color: AppTheme.Colors.coffeeBrown.opacity(0.15),
                                    radius: 8,
                                    x: 0,
                                    y: 4
                                )
                        )
                        .padding(.horizontal, 16)
                        
                        // SECCIÓN: Acciones
                        VStack(alignment: .leading, spacing: 14) {
                            // Header con icono
                            HStack(spacing: 10) {
                                Image(systemName: "bolt.circle.fill")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundStyle(AppTheme.Colors.espresso)
                                
                                Text("Acciones")
                                    .font(.system(size: accessibilityManager.titleFontSize, weight: .bold))
                                    .foregroundStyle(accessibilityManager.primaryTextColor)
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                            
                            VStack(spacing: 10) {
                                // Mostrar tareas ocultas
                                if !viewModel.hiddenCompletedTaskIds.isEmpty {
                                    Button {
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                            viewModel.showAllHiddenTasks()
                                        }
                                    } label: {
                                        HStack(spacing: 12) {
                                            // Círculo sólido - estilo consistente
                                            Image(systemName: "eye.fill")
                                                .font(.system(size: 18, weight: .semibold))
                                                .foregroundStyle(AppTheme.Colors.coffeeGreen)
                                                .frame(width: 40, height: 40)
                                                .background(
                                                    Circle()
                                                        .fill(AppTheme.Colors.coffeeGreen.opacity(0.15))
                                                )
                                            
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text("Mostrar tareas ocultas")
                                                    .font(.system(size: accessibilityManager.bodyFontSize, weight: .medium))
                                                    .foregroundStyle(accessibilityManager.primaryTextColor)
                                                
                                                Text("\(viewModel.hiddenCompletedTaskIds.count) ocultas")
                                                    .font(.system(size: accessibilityManager.captionFontSize))
                                                    .foregroundStyle(accessibilityManager.secondaryTextColor)
                                            }
                                            
                                            Spacer()
                                            
                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 13, weight: .semibold))
                                                .foregroundStyle(AppTheme.Colors.coffeeBrown.opacity(0.4))
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 14)
                                                .fill(.white)
                                                .shadow(
                                                    color: AppTheme.Colors.coffeeBrown.opacity(0.1),
                                                    radius: 4,
                                                    x: 0,
                                                    y: 2
                                                )
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14)
                                                .stroke(AppTheme.Colors.coffeeGreen.opacity(0.2), lineWidth: 1)
                                        )
                                    }
                                    .sensoryFeedback(.success, trigger: viewModel.hiddenCompletedTaskIds.count)
                                }
                                
                                // Eliminar completadas
                                Button(role: .destructive) {
                                    viewModel.deleteCompletedTasks()
                                    showFilters = false
                                } label: {
                                    HStack(spacing: 12) {
                                        // Círculo sólido rojo
                                        Image(systemName: "trash.fill")
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundStyle(.red)
                                            .frame(width: 40, height: 40)
                                            .background(
                                                Circle()
                                                    .fill(Color.red.opacity(0.15))
                                            )
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Eliminar completadas")
                                                .font(.system(size: accessibilityManager.bodyFontSize, weight: .medium))
                                                .foregroundStyle(.red)
                                            
                                            Text("Esta acción no se puede deshacer")
                                                .font(.system(size: accessibilityManager.captionFontSize))
                                                .foregroundStyle(accessibilityManager.secondaryTextColor)
                                        }
                                        
                                        Spacer()
                                        
                                        if viewModel.completedCount > 0 {
                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 13, weight: .semibold))
                                                .foregroundStyle(Color.red.opacity(0.4))
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(.white)
                                            .shadow(
                                                color: Color.red.opacity(viewModel.completedCount > 0 ? 0.1 : 0.05),
                                                radius: 4,
                                                x: 0,
                                                y: 2
                                            )
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(Color.red.opacity(viewModel.completedCount > 0 ? 0.25 : 0.15), lineWidth: 1)
                                    )
                                }
                                .sensoryFeedback(.warning, trigger: viewModel.completedCount)
                                .disabled(viewModel.completedCount == 0)
                                .opacity(viewModel.completedCount == 0 ? 0.5 : 1.0)
                            }
                            .padding(.horizontal, 16)
                        }
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.white)
                                .shadow(
                                    color: AppTheme.Colors.coffeeBrown.opacity(0.15),
                                    radius: 8,
                                    x: 0,
                                    y: 4
                                )
                        )
                        .padding(.horizontal, 16)
                    }
                    .padding(.vertical, 24)
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
                    .font(.system(size: accessibilityManager.bodyFontSize, weight: .semibold))
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
        .sensoryFeedback(.selection, trigger: isSelected)
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
                // Icono más grande y con mejor contraste
                Image(systemName: icon)
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(
                        isSelected ?
                        .white :
                        (accessibilityManager.isHighContrastEnabled ?
                         AppTheme.Colors.coffeeBrown :
                         AppTheme.Colors.coffeeBrown.opacity(0.8))
                    )
                
                Text(title)
                    .font(.system(size: accessibilityManager.bodyFontSize, weight: .semibold))
                    .foregroundStyle(
                        isSelected ?
                        .white :
                        accessibilityManager.primaryTextColor
                    )
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, minHeight: 100)
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        isSelected ?
                        AppTheme.Colors.coffeeBrown :
                        (accessibilityManager.isHighContrastEnabled ? .white : .white.opacity(0.95))
                    )
                    .shadow(
                        color: isSelected ?
                        AppTheme.Colors.coffeeBrown.opacity(0.3) :
                        AppTheme.Colors.coffeeBrown.opacity(0.1),
                        radius: isSelected ? 8 : 4,
                        x: 0,
                        y: 2
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ?
                        AppTheme.Colors.coffeeBrown :
                        (accessibilityManager.isHighContrastEnabled ?
                         AppTheme.Colors.coffeeBrown.opacity(0.4) :
                         AppTheme.Colors.coffeeBrown.opacity(0.2)),
                        lineWidth: accessibilityManager.isHighContrastEnabled ? 2.5 : (isSelected ? 2 : 1.5)
                    )
            )
            .scaleEffect(isSelected ? 1.03 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .sensoryFeedback(.selection, trigger: isSelected)
        .buttonStyle(.plain)
    }
}
