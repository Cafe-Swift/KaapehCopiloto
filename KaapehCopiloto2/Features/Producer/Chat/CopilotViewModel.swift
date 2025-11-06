//
//  CopilotViewModel.swift
//  KaapehCopiloto2
//
//  Created by Cafe Swift Team on 06/11/25.
//

import Foundation
import SwiftUI

@MainActor
@Observable
final class CopilotViewModel {
    var messages: [ChatMessage] = []
    var currentInput: String = ""
    var isProcessing: Bool = false
    
    // Mock responses for Sprint 1 (MLX integration in Sprint 2)
    private let mockResponses: [String: String] = [
        "roya": "☕️ **Roya del Café (La Roya)**\n\nLa roya es causada por el hongo *Hemileia vastatrix*. Se identifica por manchas amarillas/naranjas en las hojas.\n\n**Acciones recomendadas:**\n1. Podar ramas afectadas\n2. Aplicar fungicida orgánico (caldo bordelés)\n3. Mejorar ventilación entre plantas\n4. Fertilizar para fortalecer la planta",
        
        "nitrógeno": "🌱 **Deficiencia de Nitrógeno**\n\nSe observa en hojas amarillas, especialmente las más viejas.\n\n**Solución:**\n1. Aplicar abono orgánico rico en nitrógeno\n2. Usar compost o estiércol bien descompuesto\n3. Considerar cultivos de cobertura (leguminosas)\n4. Mantener pH del suelo entre 6-7",
        
        "sano": "✅ **Planta Sana**\n\n¡Excelente! Tu planta muestra signos de salud:\n- Hojas verdes y vigorosas\n- Buen desarrollo\n\n**Mantén:**\n1. Riego regular\n2. Fertilización balanceada\n3. Control preventivo de plagas\n4. Poda de mantenimiento",
        
        "default": "☕️ **Káapeh Copiloto**\n\nEstoy aquí para ayudarte. Puedo orientarte sobre:\n\n🍃 Roya del café\n🌱 Deficiencias nutricionales\n🌿 Cuidado general de la planta\n📊 Interpretación de diagnósticos\n\n¿Qué te gustaría saber?"
    ]
    
    init() {
        // Welcome message
        messages.append(ChatMessage(
            content: "¡Hola! Soy tu Copiloto Káapeh 🌱☕️\n\nEstoy aquí para ayudarte con el cuidado de tu cafetal. ¿En qué puedo ayudarte hoy?",
            isFromUser: false
        ))
    }
    
    func sendMessage() {
        guard !currentInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        // Add user message
        let userMessage = ChatMessage(content: currentInput, isFromUser: true)
        messages.append(userMessage)
        
        let query = currentInput.lowercased()
        currentInput = ""
        isProcessing = true
        
        // Simulate AI processing with delay
        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
            
            // Generate response based on query
            let response = generateResponse(for: query)
            messages.append(ChatMessage(content: response, isFromUser: false))
            
            isProcessing = false
        }
    }
    
    private func generateResponse(for query: String) -> String {
        // Check for keywords
        if query.contains("roya") {
            return mockResponses["roya"]!
        } else if query.contains("nitrógeno") || query.contains("nitrogen") || query.contains("amarilla") {
            return mockResponses["nitrógeno"]!
        } else if query.contains("sano") || query.contains("sana") || query.contains("bien") {
            return mockResponses["sano"]!
        } else if query.contains("hola") || query.contains("ayuda") || query.contains("help") {
            return mockResponses["default"]!
        } else {
            return "Entiendo tu consulta sobre '\(query)'. En esta versión del Copiloto, puedo ayudarte especialmente con:\n\n• Roya del café\n• Deficiencia de nitrógeno\n• Estado de salud general\n\n¿Sobre cuál te gustaría saber más?"
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
