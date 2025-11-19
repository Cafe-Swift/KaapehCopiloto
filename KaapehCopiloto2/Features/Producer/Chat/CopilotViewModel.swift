//
//  CopilotViewModel.swift
//  KaapehCopiloto2
//
//  RAG-Enhanced Copilot: Usa búsqueda semántica + generación aumentada
//

import Foundation
import SwiftUI
import SwiftData

@MainActor
@Observable
final class CopilotViewModel {
    var messages: [ChatMessage] = []
    var currentInput: String = ""
    var isProcessing: Bool = false
    var isInitialized: Bool = false
    
    private let ragService: RAGService
    
    init(modelContext: ModelContext) {
        self.ragService = RAGService()
        
        // Welcome message
        messages.append(ChatMessage(
            content: "¡Hola! Soy tu Copiloto Káapeh 🌱☕️\n\nEstoy aquí para ayudarte con el cuidado de tu cafetal usando conocimiento experto sobre:\n\n🍃 Roya del café\n🌱 Deficiencias nutricionales\n🌿 Cuidados y mantenimiento\n📊 Tratamientos agroecológicos\n\n¿En qué puedo ayudarte hoy?",
            isFromUser: false
        ))
        
        // Inicializar base de conocimiento en background
        Task {
            await waitForServicesReady()
        }
    }
    
    /// Espera a que los servicios estén listos
    private func waitForServicesReady() async {
        // Esperar a que la inicialización automática termine
        var retries = 0
        while !ragService.isReady && retries < 50 {
            try? await Task.sleep(for: .milliseconds(200))
            retries += 1
        }
        
        // Verificar que estén listos
        isInitialized = ragService.isReady
        
        if !isInitialized {
            print("⚠️ RAGService no está completamente inicializado")
        } else {
            print("✅ RAGService listo para usar")
        }
    }
    
    func sendMessage() async {
        guard !currentInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        // Add user message
        let userMessage = ChatMessage(content: currentInput, isFromUser: true)
        messages.append(userMessage)
        
        let query = currentInput
        currentInput = ""
        isProcessing = true
        
        // Generate RAG-enhanced response
        let response = await generateRAGResponse(for: query)
        messages.append(ChatMessage(content: response, isFromUser: false))
        
        isProcessing = false
    }
    
    /// Genera respuesta usando RAG: Retrieve → Augment → Generate
    private func generateRAGResponse(for query: String) async -> String {
        print("💬 CopilotViewModel recibió query: '\(query)'")
        print("   - isInitialized: \(isInitialized)")
        print("   - ragService.isReady: \(ragService.isReady)")
        
        guard isInitialized else {
            print("   ❌ RAGService NO está inicializado, devolviendo mensaje de espera")
            return "⏳ Estoy inicializando mi base de conocimiento. Por favor, intenta de nuevo en un momento..."
        }
        
        do {
            print("   ✅ Llamando a ragService.answer()...")
            // Llamar al pipeline RAG completo - devuelve ChatMessage ya formateado
            let chatMessage = try await ragService.answer(query: query)
            
            print("   ✅ Respuesta recibida del RAG")
            
            // El ChatMessage ya tiene el contenido formateado en su propiedad 'content'
            return chatMessage.content
            
        } catch {
            // Si hay error (o no hay documentos relevantes), devolver mensaje genérico
            print("⚠️ Error en RAG: \(error.localizedDescription)")
            return """
            🤔 No encontré información específica sobre tu consulta en mi base de conocimiento actual.
            
            Puedo ayudarte con:
            • Roya del café (síntomas, tratamiento, prevención)
            • Deficiencia de nitrógeno (identificación y corrección)
            • Cuidados generales de plantas de café
            • Principios agroecológicos
            
            ¿Podrías reformular tu pregunta?
            """
        }
    }
    
    func clearChat() {
        messages.removeAll()
        messages.append(ChatMessage(
            content: "¡Hola! Soy tu Copiloto Káapeh 🌱☕️\n\nEstoy aquí para ayudarte con el cuidado de tu cafetal. ¿En qué puedo ayudarte hoy?",
            isFromUser: false
        ))
    }
}
