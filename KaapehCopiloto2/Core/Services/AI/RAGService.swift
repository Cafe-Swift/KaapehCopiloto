//
//  RAGService.swift
//  KaapehCopiloto2
//
//  Servicio principal de RAG (Retrieval-Augmented Generation)
//  Orquesta: EmbeddingService → VectorDatabaseService → FoundationModelsService
//

import Foundation
import SwiftUI
import Combine

// MARK: - RAG Service
@MainActor
final class RAGService: ObservableObject {
    // MARK: - Dependencies
    private let foundationModelsService: FoundationModelsService
    private let embeddingService: EmbeddingService?
    private let vectorDatabase: VectorDatabaseService
    
    // MARK: - Published Properties
    @Published private(set) var isProcessing: Bool = false
    
    // MARK: - Configuration
    private let topK = 3  // ✅ Optimizado: solo 3 docs más relevantes
    private let minSimilarity: Double = 0.6  // ✅ Optimizado: threshold más alto
    private let maxChunkCharacters = 900  // ✅ Optimizado: reduce tokens
    
    // MARK: - Initialization
    init(
        foundationModelsService: FoundationModelsService,
        embeddingService: EmbeddingService?,
        vectorDatabase: VectorDatabaseService
    ) {
        self.foundationModelsService = foundationModelsService
        self.embeddingService = embeddingService
        self.vectorDatabase = vectorDatabase
        
        print("🚀 Iniciando inicialización de RAGService...")
        
        if foundationModelsService.isAvailable {
            print("✅ FoundationModelsService disponible")
        } else {
            print("⚠️ FoundationModelsService NO disponible")
        }
        
        if embeddingService != nil {
            print("✅ EmbeddingService listo")
        } else {
            print("⚠️ EmbeddingService NO disponible")
        }
        
        print("✅ VectorDatabaseService conectado")
        print("✅ RAGService listo para usar")
        print("   - Foundation Models: \(foundationModelsService.isAvailable ? "✅" : "❌")")
        print("   - EmbeddingService: \(embeddingService != nil ? "✅" : "❌")")
        print("   - VectorDatabase: ✅")
    }
    
    // MARK: - Convenience Initializer
    convenience init() {
        self.init(
            foundationModelsService: FoundationModelsService(),
            embeddingService: EmbeddingService(),
            vectorDatabase: VectorDatabaseService.shared
        )
    }
    
    // MARK: - Availability
    var isReady: Bool {
        foundationModelsService.isAvailable && embeddingService != nil
    }
    
    // MARK: - Main RAG Pipeline
    /// Pipeline completo de RAG: Retrieve → Augment → Generate
    func answer(query: String, categoryFilter: String? = nil) async throws -> ChatMessage {
        print("💬 Pregunta recibida: '\(query)'")
        
        // ✅ Validar que la query sea válida
        guard isValidQuery(query) else {
            print("   ❌ Query inválida rechazada")
            return ChatMessage(
                content: "Por favor, formula una pregunta clara sobre café o sobre Káapeh.",
                isFromUser: false,
                sources: [],
                ragMetadata: nil
            )
        }
        
        // Detectar tipo de pregunta
        if isCasualGreeting(query) {
            print("💬 Pregunta casual detectada - usando Foundation Models directo")
            return try await handleCasualQuery(query)
        }
        
        if isAboutKaapeh(query) {
            print("🔍 Pregunta técnica detectada (palabra clave: 'kaapeh') - usando RAG completo")
        } else if isTechnicalQuery(query) {
            print("🔍 Pregunta técnica detectada - usando RAG completo")
        }
        
        // Pipeline RAG completo
        return try await handleTechnicalQuery(query, categoryFilter: categoryFilter)
    }
    
    // MARK: - Query Validation
    
    /// Valida si una query es válida y tiene sentido procesarla
    private func isValidQuery(_ query: String) -> Bool {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // ❌ Muy corto
        guard trimmed.count >= 3 else {
            print("   ⚠️ Query rechazada: muy corta")
            return false
        }
        
        // ❌ Solo caracteres repetidos o patterns sin sentido
        let lowercased = trimmed.lowercased()
        let uniqueChars = Set(lowercased.filter { $0.isLetter })
        
        // Si tiene muy pocas letras únicas
        if uniqueChars.count <= 2 {
            print("   ⚠️ Query rechazada: muy pocas letras únicas")
            return false
        }
        
        // ❌ Detectar repeticiones excesivas (ej: "Miauuu", "jajaja")
        var consecutiveDuplicates = 0
        let chars = Array(lowercased)
        for i in 1..<chars.count {
            if chars[i] == chars[i-1] && chars[i].isLetter {
                consecutiveDuplicates += 1
            }
        }
        let duplicateRatio = Double(consecutiveDuplicates) / Double(trimmed.count)
        if duplicateRatio > 0.4 {  // Más del 40% son duplicados consecutivos
            print("   ⚠️ Query rechazada: demasiadas letras repetidas")
            return false
        }
        
        // ❌ No contiene letras
        if !trimmed.contains(where: { $0.isLetter }) {
            print("   ⚠️ Query rechazada: sin letras")
            return false
        }
        
        return true
    }
    
    // MARK: - Query Classification
    
    private func isCasualGreeting(_ query: String) -> Bool {
        let lowercased = query.lowercased()
        let greetings = ["hola", "hi", "hello", "buenos días", "buenas tardes", "buenas noches",
                        "qué tal", "cómo estás", "hey", "saludos"]
        return greetings.contains(where: { lowercased.contains($0) })
    }
    
    private func isAboutKaapeh(_ query: String) -> Bool {
        let lowercased = query.lowercased()
        return lowercased.contains("káapeh") || lowercased.contains("kaapeh")
    }
    
    private func isTechnicalQuery(_ query: String) -> Bool {
        let lowercased = query.lowercased()
        let technicalKeywords = ["roya", "plaga", "enfermedad", "nutrición", "fertilizar",
                                "tratar", "prevenir", "hojas", "manchas", "hongos",
                                "café", "cafetal", "cultivo", "planta"]
        return technicalKeywords.contains(where: { lowercased.contains($0) })
    }
    
    // MARK: - Casual Query Handler
    private func handleCasualQuery(_ query: String) async throws -> ChatMessage {
        print("💬 Generando respuesta de saludo (sin RAG)...")
        
        let response = try await foundationModelsService.generateGreeting(
            prompt: query
        )
        
        return ChatMessage(content: response, isFromUser: false, sources: [], ragMetadata: nil)
    }
    
    // MARK: - Technical Query Handler
    private func handleTechnicalQuery(
        _ query: String,
        categoryFilter: String?
    ) async throws -> ChatMessage {
        isProcessing = true
        defer { isProcessing = false }
        
        let startTime = Date()
        
        // PASO 1: RETRIEVE - Buscar documentos relevantes
        print("🔍 Iniciando pipeline RAG completo para query: '\(query)'")
        
        let searchResults = try await vectorDatabase.search(
            query: query,
            topK: topK,
            categoryFilter: categoryFilter,
            minSimilarity: minSimilarity
        )
        
        let retrievalTime = Date().timeIntervalSince(startTime)
        
        guard !searchResults.isEmpty else {
            print("   ⚠️ No se encontraron documentos relevantes")
            return ChatMessage(
                content: "No encontré información específica sobre eso en mi base de conocimiento. ¿Podrías reformular tu pregunta?",
                isFromUser: false,
                sources: [],
                ragMetadata: nil
            )
        }
        
        print("   ✅ Encontrados \(searchResults.count) documentos relevantes")
        
        // PASO 2: AUGMENT - Construir contexto
        let context = buildContext(from: searchResults)
        let augmentedPrompt = buildRAGPrompt(query: query, context: context)
        
        // PASO 3: GENERATE - Generar respuesta
        let generationStart = Date()
        
        let response = try await foundationModelsService.generateCoffeeDiagnosisResponse(
            prompt: augmentedPrompt
        )
        
        let generationTime = Date().timeIntervalSince(generationStart)
        let totalTime = Date().timeIntervalSince(startTime)
        
        // Calcular score promedio
        let averageScore = searchResults.isEmpty ? 0.0 :
            searchResults.reduce(0.0) { $0 + Double($1.similarityScore) } / Double(searchResults.count)
        
        // Crear metadata
        let metadata = RAGMetadata(
            retrievedDocuments: searchResults.count,
            averageScore: averageScore,
            retrievalTimeMs: retrievalTime * 1000,
            generationTimeMs: generationTime * 1000
        )
        
        print("   ✅ Respuesta RAG generada en \(Int(totalTime * 1000))ms")
        print("      - Recuperación: \(Int(retrievalTime * 1000))ms")
        print("      - Generación: \(Int(generationTime * 1000))ms")
        
        // Convertir a ChatMessage
        return response.toChatMessage(metadata: metadata)
    }
    
    // MARK: - Context Building
    
    private func buildContext(from results: [RAGSearchResult]) -> String {
        var contextParts: [String] = []
        
        for (index, result) in results.enumerated() {
            let truncatedContent = String(result.document.content.prefix(maxChunkCharacters))
            contextParts.append("""
            [DOCUMENTO \(index + 1): \(result.document.title)]
            \(truncatedContent)
            """)
        }
        
        return contextParts.joined(separator: "\n\n---\n\n")
    }
    
    private func buildRAGPrompt(query: String, context: String) -> String {
        return """
        CONTEXTO (Base de Conocimiento de Káapeh):
        \(context)
        
        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        
        PREGUNTA DEL USUARIO:
        \(query)
        
        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        
        INSTRUCCIONES PARA TU RESPUESTA:
        
        1. RESPONDE en 2-3 líneas máximo, de forma profesional e informativa.
        
        2. USA SOLO EL CONTEXTO:
           - Si la información está en el contexto → úsala
           - Si NO está en el contexto → di "No cuento con información específica sobre esto"
           - NUNCA inventes
        
        3. Para preguntas TÉCNICAS (enfermedades, plagas, nutrición):
           - Primero define el problema o concepto de forma clara
           - Usa analogías relevantes del campo y la agricultura cuando sea necesario
           - Profesional y técnico, pero accesible
           - Usa términos como "la planta", "el cultivo", "las hojas"
           - Explica términos técnicos cuando sea necesario
           - IMPORTANTE: NO menciones las fuentes de información en tu respuesta
        
        4. ESTRUCTURA según corresponda:
           - answer: respuesta clara y directa
           - treatment: [solo si aplica] máximo 3-5 pasos clave
           - prevention: [solo si aplica] máximo 3-4 medidas importantes
           - sources: [] (array vacío - no mostrar fuentes)
           - callToAction: consejo breve y práctico
        
        Responde ahora en formato CoffeeDiagnosisResponse.
        """
    }
}
