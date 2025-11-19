//
//  RAGGeneratedResponse.swift
//  KaapehCopiloto2
//
//  Structured output para Foundation Models
//

import Foundation
import FoundationModels

// MARK: - RAG Generated Response
/// Respuesta estructurada básica del LLM con respuesta + fuentes citadas
@Generable
struct RAGGeneratedResponse: Equatable {
    @Guide(description: "La respuesta sintetizada al usuario, basada ÚNICAMENTE en el contexto proporcionado.")
    var answer: String
    
    @Guide(description: "Lista de títulos de documentos citados en la respuesta. Debe ser un array de strings.")
    var citedSources: [String]
    
    @Guide(description: "Nivel de confianza en la respuesta de 0.0 a 1.0")
    var confidence: Double
    
    @Guide(description: "true si el contexto fue suficiente para responder, false si faltó información")
    var contextWasSufficient: Bool
}
