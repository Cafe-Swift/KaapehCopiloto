//
//  RAGService.swift
//  KaapehCopiloto2
//
//  Servicio principal de RAG (Retrieval-Augmented Generation)
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
    private let topK = 3
    private let minSimilarity: Double = 0.6  //
    private let maxChunkCharacters = 1000  //
    
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
        
        // Muy corto
        guard trimmed.count >= 3 else {
            print("   ⚠️ Query rechazada: muy corta")
            return false
        }
        
        // Solo caracteres repetidos o patterns sin sentido
        let lowercased = trimmed.lowercased()
        let uniqueChars = Set(lowercased.filter { $0.isLetter })
        
        // Si tiene muy pocas letras únicas
        if uniqueChars.count <= 2 {
            print("   ⚠️ Query rechazada: muy pocas letras únicas")
            return false
        }
        
        // Detectar repeticiones excesivas ( "jajaja")
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
        
        // No contiene letras
        if !trimmed.contains(where: { $0.isLetter }) {
            print("   ⚠️ Query rechazada: sin letras")
            return false
        }
        
        return true
    }
    
    // MARK: - Query Classification
    
    private func isCasualGreeting(_ query: String) -> Bool {

        // Normalizar acentos y minúsculas
        let normalized = query
            .folding(options: .diacriticInsensitive, locale: .current)
            .lowercased()

        // Limpiar puntuación que pueda interferir
        let cleaned = normalized.replacingOccurrences(
            of: "[!¡?¿.,;:()\\-]",
            with: "",
            options: .regularExpression
        )

        // Lista ampliada de saludos (solo texto, sin regex)
        let greetings = [
            // Español
            "hola", "holi", "holis", "holaaa", "holu",
            "que onda", "que rollo", "que pedo", "que pasa",
            "que tal", "como estas", "como va", "como andas",
            "buenas", "buenos dias", "buenas tardes", "buenas noches",
            "saludos", "que hay", "quibo", "quiubo", "que cuentas",
            "que haces", "como amaneciste", "como va todo",
            "buenas buenas", "wenas", "hola amigo", "hola amiga",
            "que show", "que mas",

            // Inglés
            "hi", "hey", "hello", "heyy", "heya",
            "hi there", "hello there", "hey there",
            "good morning", "good afternoon", "good evening",
            "whats up", "what's up", "sup", "wassup", "wazzup",
            "hows it going", "how are you", "how ya doing", "how you doin",
            "yo", "hiya", "greetings",
            "whats good", "whats new", "howve you been",
            "long time no see"
        ]

        // Comportamiento exacto igual al original
        return greetings.contains(where: { cleaned.contains($0) })
    }
    
    private func isAboutKaapeh(_ query: String) -> Bool {
        let lowercased = query.lowercased()
        return lowercased.contains("káapeh") || lowercased.contains("kaapeh")
    }
    
    private func isTechnicalQuery(_ query: String) -> Bool {

        // Normalizar acentos y minúsculas
        let normalized = query
            .folding(options: .diacriticInsensitive, locale: .current)
            .lowercased()

        // Limpiar puntuación para evitar falsos negativos
        let cleaned = normalized.replacingOccurrences(
            of: "[!¡?¿.,;:()\\-]",
            with: "",
            options: .regularExpression
        )

        let technicalKeywords = [
            // Enfermedades y plagas
            "roya", "plaga", "plagas", "hongo", "hongos",
            "mancha", "manchas", "enfermedad", "enfermedades",
            "peste", "bacteria", "virus", "infeccion", "patogeno",
            "gusano", "insecto", "insectos", "cochinilla", "broca",
            "nematodo", "acaro",

            // Manejo y tratamiento
            "nutricion", "fertilizar", "fertilizante", "abonado",
            "abono", "tratar", "tratamiento", "prevenir", "prevencion",
            "control biologico", "control quimico", "fumigar",
            "fumigacion", "poda", "podar", "riego",

            // Partes de la planta y síntomas
            "hoja", "hojas", "tallo", "raiz", "raices",
            "fruto", "corteza", "secas", "amarillas", "cafeadas",
            "marchita", "marchitez", "decoloracion", "deformacion",

            // Café / agricultura
            "cafe", "cafetal", "cultivo", "planta", "plantacion",
            "agricola", "agricultura", "suelo", "sustrato",
            "ph", "nutrientes", "micronutrientes", "macronutrientes",

            // Problemas comunes
            "deficiencia", "toxicidad", "estres hidrico",
            "sobre riego", "sub riego", "falta de luz",
            "exceso de luz", "temperatura", "humedad"
        ]

        return technicalKeywords.contains(where: { cleaned.contains($0) })
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
        CONTEXTO COMPLETO (Base de Conocimiento de Káapeh - USA TODA LA INFORMACIÓN):
        \(context)
        
        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        
        PREGUNTA DEL USUARIO:
        \(query)
        
        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        
        INSTRUCCIONES PARA TU RESPUESTA COMPLETA Y DETALLADA:
        
        1. APROVECHA TODO EL CONTEXTO - NO TE LIMITES:
           - Lee TODOS los documentos proporcionados arriba
           - Extrae TODA la información relevante disponible
           - Incluye TODOS los detalles técnicos (dosis, cantidades, tiempos, frecuencias)
           - Respuestas más completas y detalladas = mejor para el caficultor
        
        2. USA SOLO EL CONTEXTO (PERO ÚSALO TODO):
           - Si la información está → inclúyela COMPLETA con todos sus detalles
           - Si NO está → di "No cuento con información específica sobre esto"
           - NUNCA inventes información
        
        3. Para preguntas TÉCNICAS (enfermedades, plagas, nutrición, biopreparados):
           - PRIMERO: Define el problema/concepto de forma clara y completa (3-4 líneas)
           - SEGUNDO: Explica causas, ciclo de vida, características - con TODOS los detalles disponibles
           - TERCERO: Incluye información adicional relevante (condiciones favorables, síntomas detallados, etc.)
           - Usa analogías del campo cuando ayuden a entender conceptos complejos
           - Profesional y técnico, pero siempre accesible para caficultores
           - Explica términos científicos cuando sea necesario
           - IMPORTANTE: NO menciones las fuentes en tu respuesta
        
        4. ESTRUCTURA DETALLADA según corresponda:
           - answer: Respuesta COMPLETA con TODOS los detalles disponibles (4-7 líneas o más)
                    Incluye definición + causas + características + información adicional relevante
           
           - treatment: [si aplica] TODOS los pasos con:
                       * Dosis específicas (kg, litros, %, gramos)
                       * Cantidades exactas por volumen
                       * Frecuencia de aplicación (cada X días/semanas)
                       * Forma de aplicación (foliar, al suelo, etc.)
                       * Momento del día recomendado
                       * 6-10 pasos detallados si hay información
           
           - prevention: [si aplica] TODAS las medidas preventivas con:
                        * Prácticas culturales específicas
                        * Frecuencias de monitoreo
                        * Condiciones a evitar
                        * Acciones de manejo del cultivo
                        * 5-8 medidas detalladas si hay información
           
           - sources: [] (array vacío - NUNCA mostrar fuentes)
           
           - callToAction: [opcional] Recomendación práctica adicional si es relevante
        
        FORMATO DE RESPUESTAS:
        - NO uses límites artificiales de "máximo X pasos" - incluye TODOS los pasos disponibles
        - Incluye cantidades específicas (10 kg, 5 litros, 2%) cuando estén en el contexto
        - Menciona tiempos (7 días, 2 semanas, cada mes) cuando aplique
        - Explica el "por qué" detrás de cada recomendación cuando sea posible
        - Usa viñetas implícitas para organizar información compleja
        
        TONO: Como un agrónomo de campo experimentado que comparte TODO su conocimiento técnico de forma accesible.
        
        RECUERDA SIEMPRE: El caficultor necesita TODA la información disponible - respuestas completas y detalladas son mejores que respuestas breves.
        
        Responde ahora en formato CoffeeDiagnosisResponse con la información MÁS COMPLETA posible.
        """
    }
}
