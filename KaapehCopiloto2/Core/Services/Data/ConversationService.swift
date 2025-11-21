//
//  ConversationService.swift
//  KaapehCopiloto2
//
//  Servicio para gestión de conversaciones persistentes
//

import Foundation
import SwiftData

@MainActor
final class ConversationService {
    static let shared = ConversationService()
    
    private var modelContext: ModelContext?
    
    private init() {
        print("💬 ConversationService inicializado")
    }
    
    /// Configurar el servicio con el contexto de SwiftData
    func configure(with context: ModelContext) {
        self.modelContext = context
        print("💬 ConversationService configurado con ModelContext")
    }
    
    // MARK: - CRUD Operations
    
    /// Crear nueva conversación
    func createConversation(isVoice: Bool) -> Conversation {
        let conversation = Conversation(isVoiceConversation: isVoice)
        
        // Guardar en SwiftData
        if let context = modelContext {
            context.insert(conversation)
            try? context.save()
        }
        
        return conversation
    }
    
    /// Obtener todas las conversaciones
    func fetchAllConversations() -> [Conversation] {
        guard let context = modelContext else {
            print("⚠️ ModelContext no disponible")
            return []
        }
        
        let descriptor = FetchDescriptor<Conversation>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        do {
            return try context.fetch(descriptor)
        } catch {
            print("❌ Error al cargar conversaciones: \(error)")
            return []
        }
    }
    
    /// Eliminar conversación
    func delete(_ conversation: Conversation) {
        guard let context = modelContext else { return }
        
        context.delete(conversation)
        try? context.save()
    }
    
    // MARK: - Message Serialization
    
    /// Guardar mensajes en una conversación
    func saveMessages(_ messages: [ChatMessage], to conversation: Conversation) {
        // Serializar mensajes a JSON
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            let data = try encoder.encode(messages)
            conversation.messagesData = data
            
            // Actualizar timestamps
            conversation.lastUpdated = Date()
            conversation.lastMessageAt = Date()
            
            // Guardar en SwiftData
            try? modelContext?.save()
            
            print("💾 \(messages.count) mensajes guardados en conversación")
        } catch {
            print("❌ Error al guardar mensajes: \(error)")
        }
    }
    
    /// Cargar mensajes desde una conversación
    func loadMessages(from conversation: Conversation) -> [ChatMessage] {
        // Verificar si hay datos
        guard conversation.messagesData.count > 0 else {
            print("ℹ️ No hay mensajes en la conversación")
            return []
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            let messages = try decoder.decode([ChatMessage].self, from: conversation.messagesData)
            print("📖 \(messages.count) mensajes cargados desde conversación")
            return messages
        } catch {
            print("❌ Error al cargar mensajes: \(error)")
            return []
        }
    }
}


