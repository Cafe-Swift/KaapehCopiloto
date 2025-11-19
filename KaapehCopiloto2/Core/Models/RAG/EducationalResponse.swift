//
//  EducationalResponse.swift
//  KaapehCopiloto2
//
//  Respuesta educativa para explicaciones técnicas simples
//

import Foundation
import FoundationModels

@Generable
struct EducationalResponse: Equatable {
    @Guide(description: """
    Explicación simple y amigable del concepto, usando analogías de la vida diaria.
    Debe desglosar el concepto técnico en términos que un caficultor pueda entender fácilmente.
    Máximo 3-4 párrafos breves.
    """)
    var explanation: String
    
    @Guide(description: """
    Lista de 2-3 consejos prácticos relacionados con la explicación.
    Si no aplica, dejar el array vacío [].
    """)
    var practicalTips: [String]
    
    @Guide(description: """
    Lista de fuentes consultadas (títulos de documentos).
    Si no se usaron documentos, dejar el array vacío [].
    """)
    var sources: [String]
}

// MARK: - Conversion Helper
extension EducationalResponse {
    func toChatMessage(metadata: RAGMetadata? = nil) -> ChatMessage {
        var fullContent = explanation
        
        if !practicalTips.isEmpty {
            fullContent += "\n\n**💡 Consejos prácticos:**\n"
            fullContent += practicalTips.map { "• \($0)" }.joined(separator: "\n")
        }
        
        if !sources.isEmpty {
            fullContent += "\n\n**📚 Fuentes consultadas:**"
            fullContent += "\n" + sources.map { "• \($0)" }.joined(separator: "\n")
        }
        
        return ChatMessage(
            content: fullContent,
            isFromUser: false,
            sources: sources,
            ragMetadata: metadata
        )
    }
}
