//
//  UserProfile.swift
//  KaapehCopiloto
//
//  Created by Marco Antonio Torres Ramirez on 27/10/25.
//

import Foundation
import SwiftData

@Model
final class UserProfile {
    @Attribute(.unique) var userID: UUID
    var userName: String
    var role: String // "Productor" o "Tecnico"
    var preferredLanguage: String // "es", "tsz" (Tsotsil)
    var createdAt: Date
    
    @Relationship(deleteRule: .cascade, inverse: \AccessibilityConfig.userProfile)
    var accessibilitySettings: AccessibilityConfig?
    
    @Relationship(deleteRule: .cascade, inverse: \DiagnosisRecord.userProfile)
    var diagnosisHistory: [DiagnosisRecord]?
    
    init(userName: String, role: String = "Productor", preferredLanguage: String = "es") {
        self.userID = UUID()
        self.userName = userName
        self.role = role
        self.preferredLanguage = preferredLanguage
        self.createdAt = Date()
        self.diagnosisHistory = []
    }
}
