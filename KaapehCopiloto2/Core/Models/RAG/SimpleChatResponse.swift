//
//  SimpleChatResponse.swift
//  KaapehCopiloto2
//
//  Respuesta simple para saludos y conversación básica
//

import Foundation
import FoundationModels

@Generable
struct SimpleChatResponse: Equatable {
    @Guide(description: "Una respuesta amigable y breve en español. Para saludos, responde cálidamente y ofrece ayuda.")
    var response: String
}

// MARK: - Conversion Helper
extension SimpleChatResponse {
    func toChatMessage(metadata: RAGMetadata? = nil) -> ChatMessage {
        return ChatMessage(
            content: response,
            isFromUser: false,
            sources: [],
            ragMetadata: metadata
        )
    }
}
