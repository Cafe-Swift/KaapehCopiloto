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
    @State private var isPressed: Bool = false
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
                        .strokeBorder(task.isCompleted ? AppTheme.Colors.coffeeGreen : Color.gray.opacity(0.5), lineWidth: 2)
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
            .scaleEffect(isPressed ? 0.9 : 1.0)
            .accessibilityLabel(task.isCompleted ? "Marcar como pendiente" : "Marcar como completada")
            
            // Contenido de la tarea
            VStack(alignment: .leading, spacing: 8) {
                Text(task.descriptionText)
                    .font(.system(size: accessibilityManager.bodyFontSize))
                    .foregroundStyle(task.isCompleted ? accessibilityManager.secondaryTextColor : accessibilityManager.primaryTextColor)
                    .strikethrough(task.isCompleted, color: accessibilityManager.secondaryTextColor)
                    .lineLimit(3)
                
                // ⭐ NEW: Badges Row
                HStack(spacing: 8) {
                    // Priority Badge
                    TaskPriorityBadge(priority: task.taskPriority)
                        .onTapGesture {
                            showPriorityMenu = true
                        }
                    
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
                    } else {
                        Button(action: { showDatePicker = true }) {
                            Label("Agregar fecha", systemImage: "calendar.badge.plus")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    // Category Badge
                    if let category = task.category {
                        Text(category.capitalized)
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.gray.opacity(0.2))
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
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(response: 0.3)) {
                onToggle()
            }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .confirmationDialog("Seleccionar Prioridad", isPresented: $showPriorityMenu) {
            ForEach(TaskPriority.allCases, id: \.self) { priority in
                Button(priority.rawValue) {
                    onPriorityChange?(priority)
                }
            }
        }
        .sheet(isPresented: $showDatePicker) {
            TaskDatePickerSheet(
                currentDate: task.dueDate,
                onSave: { newDate in
                    onDueDateChange?(newDate)
                }
            )
            .presentationDetents([.medium])
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
                .foregroundStyle(priorityColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(priorityColor.opacity(0.15))
        .cornerRadius(8)
    }
    
    private var priorityColor: Color {
        switch priority {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .orange
        case .urgent: return .red
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
    @State private var selectedDate: Date
    @State private var hasDate: Bool
    
    init(currentDate: Date?, onSave: @escaping (Date?) -> Void) {
        self.currentDate = currentDate
        self.onSave = onSave
        
        _selectedDate = State(initialValue: currentDate ?? Date().addingTimeInterval(86400)) // +1 día
        _hasDate = State(initialValue: currentDate != nil)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Toggle("Establecer fecha de vencimiento", isOn: $hasDate)
                    .padding()
                
                if hasDate {
                    DatePicker(
                        "Fecha de vencimiento",
                        selection: $selectedDate,
                        in: Date()...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.graphical)
                    .padding()
                }
                
                Spacer()
            }
            .navigationTitle("Fecha de Vencimiento")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        onSave(hasDate ? selectedDate : nil)
                        dismiss()
                    }
                }
            }
        }
    }
}
