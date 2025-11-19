//
//  FoundationModelsService.swift
//  KaapehCopiloto2
//
//  Servicio que envuelve Foundation Models para generación de respuestas
//  ✅ OPTIMIZADO: Usa sesiones efímeras para evitar overflow de tokens
//

import Foundation
import FoundationModels
import Combine

// MARK: - Foundation Models Service
@MainActor
final class FoundationModelsService: ObservableObject {
    // MARK: - Properties
    @Published private(set) var isAvailable: Bool = false
    @Published private(set) var isGenerating: Bool = false
    
    // ✅ CAMBIO CRÍTICO: Ya NO usamos una sesión persistente
    // Cada query creará su propia sesión efímera para evitar overflow de tokens
    private let model = SystemLanguageModel.default
    
    // MARK: - System Prompt
    private let systemPrompt = """
    Eres el Copiloto de Káapeh, un asistente técnico especializado en café agroecológico para caficultores de Chiapas, México.
    
    TU MISIÓN: Proporcionar orientación técnica clara, práctica y profesional a productores de café.
    
    REGLAS FUNDAMENTALES:
    1. Usa lenguaje claro y profesional, accesible para caficultores
    2. Explica conceptos técnicos con analogías relevantes del campo y la agricultura
    3. Si el contexto no tiene la respuesta, di "No cuento con información específica sobre esto"
    4. NUNCA inventes información
    5. Sé específico y práctico - enfócate en soluciones aplicables
    
    FORMATO DE RESPUESTAS:
    - Para SALUDOS: responde de forma concisa y profesional
    - Para preguntas sobre KÁAPEH: máximo 2-3 líneas informativas
    - Para preguntas TÉCNICAS:
      * Primero: define el problema o concepto de forma clara
      * Segundo: explica la causa o el proceso
      * SOLO si aplica: proporciona tratamiento y medidas preventivas
    
    TONO: Profesional, técnico pero accesible, como un agrónomo de campo que entiende la realidad del caficultor.
    
    IMPORTANTE: NO menciones las fuentes de información en tus respuestas.
    """
    
    // MARK: - Initialization
    init() {
        checkAvailability()
        print("✅ FoundationModelsService inicializado (modo: sesiones efímeras)")
    }
    
    // MARK: - Availability Check
    private func checkAvailability() {
        switch model.availability {
        case .available:
            isAvailable = true
            print("✅ Foundation Models disponible")
        case .unavailable(let reason):
            isAvailable = false
            print("⚠️ Foundation Models no disponible: \(reason)")
        @unknown default:
            isAvailable = false
        }
    }
    
    // MARK: - Generation Methods
    
    /// Genera una respuesta estructurada para diagnóstico de café
    /// ✅ Usa una sesión NUEVA para cada llamada - evita overflow de tokens
    func generateCoffeeDiagnosisResponse(
        prompt: String,
        temperature: Double = 0.4
    ) async throws -> CoffeeDiagnosisResponse {
        guard isAvailable else {
            throw FoundationModelsError.modelUnavailable
        }
        
        isGenerating = true
        defer { isGenerating = false }
        
        // ✅ CREAR SESIÓN EFÍMERA - Se destruye después de la respuesta
        let freshSession = LanguageModelSession(
            model: model,
            instructions: systemPrompt
        )
        
        let response = try await freshSession.respond(
            to: prompt,
            generating: CoffeeDiagnosisResponse.self
        )
        
        // La sesión se destruye automáticamente aquí (sale del scope)
        return response.content
    }
    
    /// Genera una respuesta educativa simple (para preguntas sobre Káapeh)
    /// ✅ Usa una sesión NUEVA para cada llamada
    func generateEducationalResponse(
        prompt: String,
        temperature: Double = 0.3
    ) async throws -> CoffeeDiagnosisResponse {
        return try await generateCoffeeDiagnosisResponse(
            prompt: prompt,
            temperature: temperature
        )
    }
    
    /// Genera un saludo simple
    /// ✅ Usa una sesión NUEVA para cada llamada
    func generateGreeting(prompt: String) async throws -> String {
        guard isAvailable else {
            throw FoundationModelsError.modelUnavailable
        }
        
        isGenerating = true
        defer { isGenerating = false }
        
        let greetingPrompt = """
        \(prompt)
        
        Responde de forma breve y profesional. Ofrece tu ayuda como Copiloto de Káapeh.
        """
        
        // ✅ CREAR SESIÓN EFÍMERA
        let freshSession = LanguageModelSession(
            model: model,
            instructions: systemPrompt
        )
        
        let response = try await freshSession.respond(to: greetingPrompt)
        return response.content
    }
}

// MARK: - Errors
enum FoundationModelsError: LocalizedError {
    case sessionNotInitialized
    case modelUnavailable
    case generationFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .sessionNotInitialized:
            return "La sesión del modelo no está inicializada"
        case .modelUnavailable:
            return "El modelo no está disponible"
        case .generationFailed(let message):
            return "Error al generar respuesta: \(message)"
        }
    }
}
