//
//  ChatMessage.swift
//  KaapehCopiloto2
//
//  Modelo de mensaje para el chat RAG
//

import Foundation
import SwiftData

/// Mensaje individual en el chat
struct ChatMessage: Identifiable, Equatable, Codable {
    let id: UUID
    let content: String
    let isFromUser: Bool
    let timestamp: Date
    
    /// Metadata opcional para RAG
    var sources: [String]?
    var ragMetadata: RAGMetadata?
    
    init(
        id: UUID = UUID(),
        content: String,
        isFromUser: Bool,
        timestamp: Date = Date(),
        sources: [String]? = nil,
        ragMetadata: RAGMetadata? = nil
    ) {
        self.id = id
        self.content = content
        self.isFromUser = isFromUser
        self.timestamp = timestamp
        self.sources = sources
        self.ragMetadata = ragMetadata
    }
}

/// Metadata RAG para mensajes del asistente
struct RAGMetadata: Equatable, Codable {
    let retrievedDocuments: Int
    let averageScore: Double
    let retrievalTimeMs: Double
    let generationTimeMs: Double
    
    var performanceSummary: String {
        """
        📊 Stats: \(retrievedDocuments) docs, \(String(format: "%.0f", retrievalTimeMs + generationTimeMs))ms
        """
    }
}

// MARK: - Helper Extensions
extension ChatMessage {
    /// Verifica si el mensaje tiene fuentes citadas
    var hasSources: Bool {
        sources?.isEmpty == false
    }
    
    /// Formatea el timestamp para display
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
    
    /// Role para Foundation Models (user/assistant)
    var role: String {
        isFromUser ? "user" : "assistant"
    }
}

// MARK: - Sample Data
extension ChatMessage {
    static let sampleUser = ChatMessage(
        content: "¿Qué le pasa a mi planta?",
        isFromUser: true
    )
    
    static let sampleAssistant = ChatMessage(
        content: "Basándome en tu descripción, parece ser Roya del café. Te recomiendo...",
        isFromUser: false,
        sources: ["Manual_Roya.pdf", "Guia_Kaapeh.pdf"],
        ragMetadata: RAGMetadata(
            retrievedDocuments: 3,
            averageScore: 0.87,
            retrievalTimeMs: 8.5,
            generationTimeMs: 120.0
        )
    )
    
    static let preview = [sampleUser, sampleAssistant]
}
