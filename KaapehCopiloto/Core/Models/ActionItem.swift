//
//  ActionItem.swift
//  KaapehCopiloto
//
//  Created by Marco Antonio Torres Ramirez on 27/10/25.
//

import Foundation
import SwiftData

@Model
final class ActionItem {
    var taskId: UUID
    var descriptionText: String
    var isCompleted: Bool
    var createdAt: Date
    
    var diagnosisRecord: DiagnosisRecord?
    
    init (descriptionText: String) {
        self.taskId = UUID()
        self.descriptionText = descriptionText
        self.isCompleted = false
        self.createdAt = Date()
    }
}
