//
//  FoundationModelsService.swift
//  KaapehCopiloto2
//
//  Servicio que envuelve Foundation Models para generación de respuestas

import Foundation
import FoundationModels
import Combine

// MARK: - Foundation Models Service
@MainActor
final class FoundationModelsService: ObservableObject {
    // MARK: - Properties
    @Published private(set) var isAvailable: Bool = false
    @Published private(set) var isGenerating: Bool = false
    
    // Cada query creará su propia sesión efímera para evitar overflow de tokens
    private let model = SystemLanguageModel.default
    
    // MARK: - System Prompt
    private let systemPrompt = """
    Eres el Copiloto de Káapeh, un asistente técnico especializado en café agroecológico para caficultores de Chiapas, México.
    
    TU MISIÓN: Proporcionar orientación técnica COMPLETA, DETALLADA y profesional a productores de café.
    
    REGLAS FUNDAMENTALES:
    1. Usa lenguaje claro y profesional, accesible para caficultores
    2. Explica conceptos técnicos con analogías relevantes del campo y la agricultura
    3. Si el contexto no tiene la respuesta, di "No cuento con información específica sobre esto"
    4. NUNCA inventes información
    5. Sé específico, detallado y práctico - proporciona explicaciones completas
    
    FORMATO DE RESPUESTAS DETALLADAS:
    - Para SALUDOS: responde de forma concisa y profesional
    - Para preguntas sobre KÁAPEH: máximo 2-3 líneas informativas
    - Para preguntas TÉCNICAS (USA TODO EL CONTEXTO DISPONIBLE):
      * PRIMERO: Define el problema/concepto de forma clara y completa
      * SEGUNDO: Explica las causas, el proceso y características principales
      * TERCERO: Proporciona detalles adicionales relevantes (ciclo de vida, condiciones favorables, etc.)
      * CUARTO: Si aplica, detalla el tratamiento paso por paso con cantidades y dosis específicas
      * QUINTO: Si aplica, proporciona medidas preventivas detalladas
      * SEXTO: Si hay información adicional útil (biopreparados, prácticas agroecológicas), inclúyela
    
    ESTILO DE RESPUESTAS:
    - NO seas breve ni conciso - aprovecha TODO el contexto disponible
    - Desarrolla cada punto con TODOS los detalles técnicos que tengas
    - Incluye dosis, cantidades, tiempos, frecuencias cuando estén disponibles
    - Usa viñetas o listas para información compleja
    - Explica el "por qué" detrás de cada recomendación
    
    TONO: Profesional, técnico pero accesible, como un agrónomo de campo experimentado que comparte TODO su conocimiento.
    
    IMPORTANTE: 
    - NO menciones las fuentes de información en tus respuestas
    - Aprovecha TODA la información del contexto - no te limites
    - Respuestas más completas = mejor para el caficultor
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
    func generateCoffeeDiagnosisResponse(
        prompt: String,
        temperature: Double = 0.4
    ) async throws -> CoffeeDiagnosisResponse {
        guard isAvailable else {
            throw FoundationModelsError.modelUnavailable
        }
        
        isGenerating = true
        defer { isGenerating = false }
        
        let freshSession = LanguageModelSession(
            model: model,
            instructions: systemPrompt
        )
        
        let response = try await freshSession.respond(
            to: prompt,
            generating: CoffeeDiagnosisResponse.self
        )
        
        // La sesión se destruye automáticamente
        return response.content
    }
    
    /// Genera una respuesta educativa simple (para preguntas sobre Káapeh)
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
