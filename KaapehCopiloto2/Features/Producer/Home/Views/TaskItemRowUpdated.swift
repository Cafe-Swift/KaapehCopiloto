//
//  TaskItemRow.swift
//  KaapehCopiloto2
//
//  Componente para mostrar una tarea individual con checkbox, prioridad y fecha
//

import SwiftUI

struct TaskItemRow: View {
    let task: ActionItem
    let onToggle: () -> Void
    let onPriorityChange: ((TaskPriority) -> Void)?
    let onDueDateChange: ((Date?) -> Void)?
    
    @Environment(AccessibilityManager.self) private var accessibilityManager
    @State private var showPriorityMenu: Bool = false
    @State private var showDatePicker: Bool = false
    
    init(
        task: ActionItem,
        onToggle: @escaping () -> Void,
        onPriorityChange: ((TaskPriority) -> Void)? = nil,
        onDueDateChange: ((Date?) -> Void)? = nil
    ) {
        self.task = task
        self.onToggle = onToggle
        self.onPriorityChange = onPriorityChange
        self.onDueDateChange = onDueDateChange
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Checkbox animado
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    onToggle()
                }
            }) {
                ZStack {
                    Circle()
                        .strokeBorder(task.isCompleted ? AppTheme.Colors.coffeeGreen : AppTheme.Colors.coffeeBrown.opacity(0.5), lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if task.isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 24, height: 24)
                            .background(AppTheme.Colors.coffeeGreen)
                            .clipShape(Circle())
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }
            .buttonStyle(.plain)
            .sensoryFeedback(trigger: task.isCompleted) { oldValue, newValue in
                return newValue ? .success : .impact(weight: .light)
            }
            .accessibilityLabel(task.isCompleted ? "Marcar como pendiente" : "Marcar como completada")
            
            // Contenido de la tarea
            VStack(alignment: .leading, spacing: 8) {
                Text(task.descriptionText)
                    .font(.system(size: accessibilityManager.bodyFontSize))
                    .foregroundStyle(task.isCompleted ? accessibilityManager.secondaryTextColor : accessibilityManager.primaryTextColor)
                    .strikethrough(task.isCompleted, color: accessibilityManager.secondaryTextColor)
                    .lineLimit(3)
                
                // Badges Row
                HStack(spacing: 8) {
                    // Priority Badge
                    TaskPriorityBadge(priority: task.taskPriority)
                        .onTapGesture {
                            showPriorityMenu = true
                        }
                        .sensoryFeedback(.selection, trigger: showPriorityMenu)
                    
                    // Due Date Badge
                    if let dueDate = task.dueDate {
                        TaskDueDateBadge(
                            dueDate: dueDate,
                            isOverdue: task.isOverdue,
                            isDueSoon: task.isDueSoon
                        )
                        .onTapGesture {
                            showDatePicker = true
                        }
                        .sensoryFeedback(.selection, trigger: showDatePicker)
                    } else {
                        Button(action: { showDatePicker = true }) {
                            Label("Agregar fecha", systemImage: "calendar.badge.plus")
                                .font(.caption2)
                                .foregroundStyle(AppTheme.Colors.coffeeBrown)
                        }
                        .sensoryFeedback(.impact(weight: .light), trigger: showDatePicker)
                    }
                    
                    // Category Badge
                    if let category = task.category {
                        Text(category.capitalized)
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(AppTheme.Colors.creamBrown.opacity(0.5))
                            .foregroundStyle(AppTheme.Colors.coffeeBrown)
                            .cornerRadius(8)
                    }
                }
                
                // Metadata
                HStack(spacing: 8) {
                    Label(
                        task.createdAt.formatted(date: .abbreviated, time: .omitted),
                        systemImage: "clock"
                    )
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    
                    if let completedDate = task.completedAt {
                        Text("•")
                            .foregroundStyle(.tertiary)
                        
                        Label(
                            "Completada: \(completedDate.formatted(date: .abbreviated, time: .shortened))",
                            systemImage: "checkmark.circle.fill"
                        )
                        .font(.caption2)
                        .foregroundStyle(AppTheme.Colors.coffeeGreen)
                    }
                }
            }
            
            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $showPriorityMenu) {
            TaskPriorityPickerSheet(
                currentPriority: task.taskPriority,
                onSelect: { newPriority in
                    onPriorityChange?(newPriority)
                    showPriorityMenu = false
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showDatePicker) {
            TaskDatePickerSheet(
                currentDate: task.dueDate,
                onSave: { newDate in
                    onDueDateChange?(newDate)
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Task Priority Badge

struct TaskPriorityBadge: View {
    let priority: TaskPriority
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(priorityColor)
                .frame(width: 8, height: 8)
            
            Text(priority.rawValue)
                .font(.caption2.weight(.medium))
                .foregroundStyle(priorityTextColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(priorityColor.opacity(0.15))
        .cornerRadius(8)
    }
    
    private var priorityColor: Color {
        switch priority {
        case .low: return Color(red: 0.2, green: 0.8, blue: 0.2) // Verde
        case .medium: return Color(red: 0.9, green: 0.7, blue: 0.0) // Amarillo
        case .high: return Color(red: 1.0, green: 0.6, blue: 0.0) // Naranja
        case .urgent: return Color(red: 1.0, green: 0.2, blue: 0.2) // Rojo
        }
    }
    
    private var priorityTextColor: Color {
        switch priority {
        case .low: return Color(red: 0.0, green: 0.5, blue: 0.0) // Verde oscuro
        case .medium: return Color(red: 0.7, green: 0.5, blue: 0.0) // Amarillo oscuro
        case .high: return Color(red: 0.8, green: 0.4, blue: 0.0) // Naranja oscuro
        case .urgent: return Color(red: 0.8, green: 0.0, blue: 0.0) // Rojo oscuro
        }
    }
}

// MARK: - Task Due Date Badge

struct TaskDueDateBadge: View {
    let dueDate: Date
    let isOverdue: Bool
    let isDueSoon: Bool
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: badgeIcon)
                .font(.caption2)
            
            Text(dueDate, style: .date)
                .font(.caption2.weight(.medium))
        }
        .foregroundStyle(badgeColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(badgeColor.opacity(0.15))
        .cornerRadius(8)
    }
    
    private var badgeIcon: String {
        if isOverdue {
            return "exclamationmark.triangle.fill"
        } else if isDueSoon {
            return "clock.badge.exclamationmark"
        } else {
            return "calendar"
        }
    }
    
    private var badgeColor: Color {
        if isOverdue {
            return .red
        } else if isDueSoon {
            return .orange
        } else {
            return .blue
        }
    }
}

// MARK: - Date Picker Sheet

struct TaskDatePickerSheet: View {
    let currentDate: Date?
    let onSave: (Date?) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @Environment(AccessibilityManager.self) private var accessibilityManager
    @State private var selectedDate: Date
    @State private var hasDate: Bool
    
    init(currentDate: Date?, onSave: @escaping (Date?) -> Void) {
        self.currentDate = currentDate
        self.onSave = onSave
        
        _selectedDate = State(initialValue: currentDate ?? Date().addingTimeInterval(86400))
        _hasDate = State(initialValue: currentDate != nil)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.creamBrown
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Fecha de vencimiento")
                                .font(.system(size: accessibilityManager.bodyFontSize, weight: .semibold))
                                .foregroundStyle(accessibilityManager.primaryTextColor)
                            
                            Toggle("Activar recordatorio", isOn: $hasDate)
                                .tint(AppTheme.Colors.coffeeGreen)
                                .sensoryFeedback(trigger: hasDate) { oldValue, newValue in
                                    return newValue ? .success : .impact(weight: .light)
                                }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.white)
                                .shadow(color: AppTheme.Colors.coffeeBrown.opacity(0.1), radius: 4)
                        )
                        .padding(.horizontal)
                        
                        if hasDate {
                            VStack(spacing: 16) {
                                HStack {
                                    Image(systemName: "calendar")
                                        .font(.title2)
                                        .foregroundStyle(AppTheme.Colors.coffeeBrown)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Fecha seleccionada")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        
                                        Text(selectedDate.formatted(date: .long, time: .shortened))
                                            .font(.system(size: accessibilityManager.bodyFontSize, weight: .medium))
                                            .foregroundStyle(accessibilityManager.primaryTextColor)
                                    }
                                    
                                    Spacer()
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(AppTheme.Colors.creamBrown.opacity(0.3))
                                )
                                
                                Divider()
                                
                                DatePicker(
                                    "Seleccionar fecha",
                                    selection: $selectedDate,
                                    in: Date()...,
                                    displayedComponents: [.date, .hourAndMinute]
                                )
                                .datePickerStyle(.graphical)
                                .tint(AppTheme.Colors.coffeeBrown)
                                .colorScheme(.light)
                                .environment(\.locale, Locale(identifier: "es_MX"))
                                .sensoryFeedback(.selection, trigger: selectedDate)
                            }
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(.white)
                                    .shadow(color: AppTheme.Colors.coffeeBrown.opacity(0.1), radius: 8)
                            )
                            .padding(.horizontal)
                        }
                        
                        if hasDate {
                            HStack(spacing: 8) {
                                Image(systemName: "info.circle.fill")
                                    .foregroundStyle(AppTheme.Colors.coffeeGreen)
                                
                                Text("Recibirás una notificación antes de la fecha límite")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(AppTheme.Colors.coffeeGreen.opacity(0.1))
                            )
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Fecha de Vencimiento")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.Colors.coffeeBrown, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                    .foregroundStyle(.white)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        onSave(hasDate ? selectedDate : nil)
                        dismiss()
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                }
            }
        }
    }
}

// MARK: - Priority Picker Sheet (MEJORADO)

struct TaskPriorityPickerSheet: View {
    let currentPriority: TaskPriority
    let onSelect: (TaskPriority) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @Environment(AccessibilityManager.self) private var accessibilityManager
    @State private var selectedPriority: TaskPriority
    
    init(currentPriority: TaskPriority, onSelect: @escaping (TaskPriority) -> Void) {
        self.currentPriority = currentPriority
        self.onSelect = onSelect
        
        _selectedPriority = State(initialValue: currentPriority)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.creamBrown
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Título con mejor diseño
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Seleccionar Prioridad")
                            .font(.system(size: accessibilityManager.bodyFontSize + 2, weight: .bold))
                            .foregroundStyle(accessibilityManager.primaryTextColor)
                        
                        Text("Toca una opción para cambiar la prioridad")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.white)
                            .shadow(color: AppTheme.Colors.coffeeBrown.opacity(0.1), radius: 4)
                    )
                    .padding(.horizontal)
                    .padding(.top, 20)
                    
                    // Lista de prioridades con mejor espaciado
                    VStack(spacing: 16) {
                        ForEach(TaskPriority.allCases, id: \.self) { priority in
                            Button(action: {
                                selectedPriority = priority
                                onSelect(priority)
                            }) {
                                HStack(spacing: 16) {
                                    // Círculo de color
                                    Circle()
                                        .fill(priorityColor(priority))
                                        .frame(width: 12, height: 12)
                                    
                                    Text(priority.rawValue)
                                        .font(.system(size: accessibilityManager.bodyFontSize, weight: .semibold))
                                        .foregroundStyle(priorityTextColor(priority))
                                    
                                    Spacer()
                                    
                                    if selectedPriority == priority {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.title3)
                                            .foregroundStyle(priorityColor(priority))
                                    }
                                }
                                .padding(20)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(priorityColor(priority).opacity(0.25))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(
                                            selectedPriority == priority ? priorityColor(priority) : Color.clear,
                                            lineWidth: 2
                                        )
                                )
                            }
                            .sensoryFeedback(.selection, trigger: selectedPriority)
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 24)
                    
                    Spacer()
                }
            }
            .navigationTitle("Prioridad")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.Colors.coffeeBrown, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                    .foregroundStyle(.white)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Listo") {
                        dismiss()
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                }
            }
        }
    }
    
    private func priorityColor(_ priority: TaskPriority) -> Color {
        switch priority {
        case .low: return Color(red: 0.2, green: 0.8, blue: 0.2) // Verde
        case .medium: return Color(red: 0.9, green: 0.7, blue: 0.0) // Amarillo más oscuro
        case .high: return Color(red: 1.0, green: 0.6, blue: 0.0) // Naranja
        case .urgent: return Color(red: 1.0, green: 0.2, blue: 0.2) // Rojo
        }
    }
    
    private func priorityTextColor(_ priority: TaskPriority) -> Color {
        switch priority {
        case .low: return Color(red: 0.0, green: 0.5, blue: 0.0) // Verde oscuro
        case .medium: return Color(red: 0.7, green: 0.5, blue: 0.0) // Amarillo/dorado oscuro
        case .high: return Color(red: 0.8, green: 0.4, blue: 0.0) // Naranja oscuro
        case .urgent: return Color(red: 0.8, green: 0.0, blue: 0.0) // Rojo oscuro
        }
    }
}
