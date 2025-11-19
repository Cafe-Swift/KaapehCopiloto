//
//  ResponseTypes.swift
//  KaapehCopiloto2
//
//  Estructuras @Generable para respuestas del sistema RAG
//  NOTA: SimpleChatResponse y EducationalResponse están en sus propios archivos
//

import Foundation
import FoundationModels

// MARK: - Respuesta Principal de Diagnóstico
@Generable
struct CoffeeDiagnosisResponse: Equatable {
    @Guide(description: """
    La respuesta completa y conversacional basada en el contexto proporcionado. 
    - Para saludos o preguntas casuales: responde de forma concisa y profesional, ofreciendo ayuda
    - Para preguntas sobre Káapeh: explica qué es en 2-3 líneas máximo, de forma profesional
    - Para preguntas técnicas: primero define el problema o concepto de forma clara, luego explica la causa o el proceso
    Debe ser clara, profesional y en español. Usa analogías relevantes del campo y la agricultura cuando sea necesario.
    """)
    var answer: String
    
    @Guide(description: """
    Lista de pasos de tratamiento recomendados. 
    SOLO incluir para preguntas técnicas sobre enfermedades, plagas o nutrición.
    Máximo 3-5 pasos MÁS IMPORTANTES y prácticos.
    NO incluir para saludos ni preguntas sobre Káapeh.
    Si no aplica, dejar el array vacío [].
    """)
    var treatment: [String]
    
    @Guide(description: """
    Lista de medidas preventivas para evitar el problema en el futuro.
    SOLO incluir para preguntas técnicas sobre enfermedades, plagas o nutrición.
    Máximo 3-4 medidas CLAVE.
    NO incluir para saludos ni preguntas sobre Káapeh.
    Si no aplica, dejar el array vacío [].
    """)
    var prevention: [String]
    
    @Guide(description: """
    Una recomendación final o llamado a la acción profesional.
    - Para saludos: puede estar vacío "" o una oferta de ayuda simple
    - Para Káapeh: puede estar vacío ""
    - Para preguntas técnicas: un consejo práctico y motivador
    """)
    var callToAction: String
}

// MARK: - Conversion Helper
extension CoffeeDiagnosisResponse {
    func toChatMessage(metadata: RAGMetadata? = nil) -> ChatMessage {
        var fullContent = answer
        
        if !treatment.isEmpty {
            fullContent += "\n\n**🌱 Tratamiento:**\n"
            fullContent += treatment.enumerated().map { index, step in "\(index + 1). \(step)" }.joined(separator: "\n")
        }
        
        if !prevention.isEmpty {
            fullContent += "\n\n**🛡️ Prevención:**\n"
            fullContent += prevention.map { "• \($0)" }.joined(separator: "\n")
        }
        
        if !callToAction.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            fullContent += "\n\n💡 " + callToAction
        }
        
        // Ya NO incluimos las fuentes en el contenido final
        
        return ChatMessage(
            content: fullContent,
            isFromUser: false,
            sources: [],  // Array vacío, no mostramos fuentes
            ragMetadata: metadata
        )
    }
}
