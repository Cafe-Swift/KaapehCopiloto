//
//  ActionItem.swift
//  KaapehCopiloto2
//
//  Created by Cafe Swift Team on 05/11/25.
//

import Foundation
import SwiftData

/// Action item model for diagnosis follow-up tasks
@Model
final class ActionItem {
    var taskId: UUID
    var descriptionText: String
    var isCompleted: Bool
    var createdAt: Date
    var completedAt: Date?
    
    init(
        taskId: UUID = UUID(),
        descriptionText: String,
        isCompleted: Bool = false,
        createdAt: Date = Date(),
        completedAt: Date? = nil
    ) {
        self.taskId = taskId
        self.descriptionText = descriptionText
        self.isCompleted = isCompleted
        self.createdAt = createdAt
        self.completedAt = completedAt
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
}
