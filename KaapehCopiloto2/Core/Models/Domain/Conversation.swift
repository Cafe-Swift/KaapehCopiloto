//
//  Conversation.swift
//  KaapehCopiloto2
//
//  Modelo para conversaciones persistentes
//

import Foundation
import SwiftData

@Model
final class Conversation {
    @Attribute(.unique) var id: UUID
    var title: String
    var createdAt: Date
    var lastMessageAt: Date
    var lastUpdated: Date
    var isVoiceChat: Bool
    
    // Relación con UserProfile (opcional)
    var userId: UUID?
    
    // Datos serializados de los mensajes
    var messagesData: Data
    
    init(
        id: UUID = UUID(),
        title: String = "Nueva conversación",
        createdAt: Date = Date(),
        lastMessageAt: Date = Date(),
        lastUpdated: Date = Date(),
        isVoiceChat: Bool = false,
        userId: UUID? = nil,
        messagesData: Data = Data()
    ) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.lastMessageAt = lastMessageAt
        self.lastUpdated = lastUpdated
        self.isVoiceChat = isVoiceChat
        self.userId = userId
        self.messagesData = messagesData
    }
    
    // Helper para formatear la fecha
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: lastMessageAt)
    }
}

// MARK: - Convenience Initializer
extension Conversation {
    convenience init(isVoiceConversation: Bool) {
        self.init(
            title: isVoiceConversation ? "Chat de Voz" : "Chat de Texto",
            isVoiceChat: isVoiceConversation
        )
    }
}
