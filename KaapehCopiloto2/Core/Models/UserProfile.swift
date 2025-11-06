//
//  UserProfile.swift
//  KaapehCopiloto2
//
//  Created by Cafe Swift Team on 05/11/25.
//

import Foundation
import SwiftData

/// User profile model
@Model
final class UserProfile {
    @Attribute(.unique) var userId: UUID
    var userName: String
    var role: String // "Productor" o "Técnico"
    var preferredLanguage: String // "es", "tsz"
    var createdAt: Date
    var lastLoginAt: Date
    var backendUserId: Int? // ID from backend after sync
    
    @Relationship(deleteRule: .cascade)
    var accessibilitySettings: AccessibilityConfig?
    
    @Relationship(deleteRule: .cascade)
    var diagnosisHistory: [DiagnosisRecord]?
    
    init(
        userId: UUID = UUID(),
        userName: String,
        role: String = "Productor",
        preferredLanguage: String = "es",
        createdAt: Date = Date(),
        lastLoginAt: Date = Date(),
        backendUserId: Int? = nil
    ) {
        self.userId = userId
        self.userName = userName
        self.role = role
        self.preferredLanguage = preferredLanguage
        self.createdAt = createdAt
        self.lastLoginAt = lastLoginAt
        self.backendUserId = backendUserId
        self.diagnosisHistory = []
    }
    
    /// Update last login timestamp
    func updateLastLogin() {
        self.lastLoginAt = Date()
    }
    
    /// Check if user is a technician
    var isTechnician: Bool {
        role == "Técnico"
    }
    
    /// Check if user is a producer
    var isProducer: Bool {
        role == "Productor"
    }
}
