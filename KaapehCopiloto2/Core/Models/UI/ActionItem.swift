//
//  ActionItem.swift
//  KaapehCopiloto2
//
//  Created by Cafe Swift Team on 05/11/25.
//

import Foundation
import SwiftData

// MARK: - Task Priority Enum

/// Priority levels for tasks
enum TaskPriority: String, Codable, CaseIterable {
    case low = "Baja"
    case medium = "Media"
    case high = "Alta"
    case urgent = "Urgente"
    
    var color: String {
        switch self {
        case .low: return "green"
        case .medium: return "yellow"
        case .high: return "orange"
        case .urgent: return "red"
        }
    }
    
    var sortOrder: Int {
        switch self {
        case .urgent: return 0
        case .high: return 1
        case .medium: return 2
        case .low: return 3
        }
    }
}

// MARK: - Action Item Model

/// Action item model for diagnosis follow-up tasks
@Model
final class ActionItem {
    var taskId: UUID
    var descriptionText: String
    var isCompleted: Bool
    var createdAt: Date
    var completedAt: Date?
    
    // Priority and Due Date
    var priority: String // Raw value del enum TaskPriority
    var dueDate: Date?
    var reminderDate: Date?
    var category: String? // "tratamiento", "prevención", "monitoreo"
    
    // Sort Order for Drag & Drop
    var sortOrder: Int
    
    // Propiedad computada para acceso tipado
    var taskPriority: TaskPriority {
        get { TaskPriority(rawValue: priority) ?? .medium }
        set { priority = newValue.rawValue }
    }
    
    // Computed property: ¿está vencida?
    var isOverdue: Bool {
        guard let dueDate = dueDate, !isCompleted else { return false }
        return dueDate < Date()
    }
    
    // Computed property: ¿vence pronto? (menos de 24 horas)
    var isDueSoon: Bool {
        guard let dueDate = dueDate, !isCompleted else { return false }
        let dayFromNow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        return dueDate < dayFromNow && dueDate > Date()
    }
    
    init(
        taskId: UUID = UUID(),
        descriptionText: String,
        isCompleted: Bool = false,
        createdAt: Date = Date(),
        completedAt: Date? = nil,
        priority: TaskPriority = .medium,
        dueDate: Date? = nil,
        reminderDate: Date? = nil,
        category: String? = nil,
        sortOrder: Int = 0
    ) {
        self.taskId = taskId
        self.descriptionText = descriptionText
        self.isCompleted = isCompleted
        self.createdAt = createdAt
        self.completedAt = completedAt
        self.priority = priority.rawValue
        self.dueDate = dueDate
        self.reminderDate = reminderDate
        self.category = category
        self.sortOrder = sortOrder
    }
    
    /// Toggle completion status
    func toggleCompletion() {
        isCompleted.toggle()
        completedAt = isCompleted ? Date() : nil
    }
    
    /// Mark as completed
    func complete() {
        isCompleted = true
        completedAt = Date()
    }
    
    /// Mark as incomplete
    func uncomplete() {
        isCompleted = false
        completedAt = nil
    }
    
    /// Update priority
    func updatePriority(_ newPriority: TaskPriority) {
        self.taskPriority = newPriority
    }
    
    /// Update due date
    func updateDueDate(_ newDate: Date?) {
        self.dueDate = newDate
    }
}
