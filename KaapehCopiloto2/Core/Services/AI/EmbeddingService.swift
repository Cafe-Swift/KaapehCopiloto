//
//  EmbeddingService.swift
//  KaapehCopiloto2
//
//  RAG Service: Genera embeddings usando NLContextualEmbedding
//

import NaturalLanguage
import Foundation
import Combine

// MARK: - Errors

enum EmbeddingError: Error {
    case modelUnavailable
    case assetNotAvailable
    case embeddingFailed
    case notReady
    case invalidInput
    case unsupportedLanguage
    
    var localizedDescription: String {
        switch self {
        case .modelUnavailable:
            return "El modelo de embeddings no está disponible en este dispositivo"
        case .assetNotAvailable:
            return "Los recursos del modelo no están descargados"
        case .embeddingFailed:
            return "Error al generar el embedding"
        case .notReady:
            return "El servicio de embeddings no está listo. Por favor espera."
        case .invalidInput:
            return "El texto proporcionado está vacío o es inválido"
        case .unsupportedLanguage:
            return "El idioma no está soportado para embeddings"
        }
    }
}

// MARK: - Service

@MainActor
final class EmbeddingService: ObservableObject {
    
    // MARK: - Properties
    
    private var embeddings: [NLLanguage: NLContextualEmbedding] = [:]
    private var readyLanguages: Set<NLLanguage> = []
    private var embeddingCache: [String: [Double]] = [:]
    private let maxCacheSize = 100
    private let primaryLanguage: NLLanguage = .spanish
    
    static let supportedLanguages: [NLLanguage] = [.spanish, .english]
    
    // MARK: - Initialization
    
    init?() {
        // Inicializar embeddings para todos los idiomas soportados
        for language in Self.supportedLanguages {
            guard let embedding = NLContextualEmbedding(language: language) else {
                print("⚠️ No se pudo inicializar NLContextualEmbedding para \(language.rawValue)")
                continue
            }
            embeddings[language] = embedding
        }
        
        guard embeddings[primaryLanguage] != nil else {
            print("❌ Error crítico: No se pudo inicializar el idioma primario")
            return nil
        }
        
        Task {
            await checkAndRequestAssets()
        }
    }
    
    // MARK: - Asset Management
    
    private func checkAndRequestAssets() async {
        for (language, embedding) in embeddings {
            if embedding.hasAvailableAssets {
                readyLanguages.insert(language)
                print("✅ Embedding assets disponibles para \(language.rawValue)")
            } else {
                print("📥 Solicitando assets para \(language.rawValue)...")
                do {
                    try await embedding.requestAssets()
                    if embedding.hasAvailableAssets {
                        readyLanguages.insert(language)
                        print("✅ Assets descargados para \(language.rawValue)")
                    }
                } catch {
                    print("❌ Error descargando assets para \(language.rawValue): \(error)")
                }
            }
        }
    }
    
    var isReady: Bool {
        !readyLanguages.isEmpty
    }
    
    func isReady(for language: NLLanguage) -> Bool {
        readyLanguages.contains(language)
    }
    
    // MARK: - Embedding Generation
    
    /// Genera un embedding para texto en español (idioma por defecto)
    func generateEmbedding(for text: String) async throws -> [Double] {
        return try await generateEmbedding(for: text, language: primaryLanguage)
    }
    
    /// Genera un embedding para texto en un idioma específico
    func generateEmbedding(for text: String, language: NLLanguage) async throws -> [Double] {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            throw EmbeddingError.invalidInput
        }
        
        // Check cache
        let cacheKey = "\(language.rawValue):\(trimmedText)"
        if let cachedVector = embeddingCache[cacheKey] {
            return cachedVector
        }
        
        guard let embedding = embeddings[language] else {
            throw EmbeddingError.unsupportedLanguage
        }
        
        guard readyLanguages.contains(language) else {
            throw EmbeddingError.notReady
        }
        
        guard let result = try? embedding.embeddingResult(for: trimmedText, language: language) else {
            print("❌ Error: No se pudo generar embedding para '\(trimmedText.prefix(50))'")
            throw EmbeddingError.embeddingFailed
        }
        
        // Crear el rango completo del texto
        let fullRange = trimmedText.startIndex..<trimmedText.endIndex
        
        // Obtener el vector enumerando los caracteres del rango
        var vectorArray: [Double] = []
        
        // NLContextualEmbedding genera embeddings de 512 dimensiones
        
        // obtener el vector para todo el texto
        result.enumerateTokenVectors(in: fullRange) { (vector, range) -> Bool in
            // Convertir el vector a array
            vectorArray = vector.map { Double($0) }
            // Retornar false para detenernos después del primer token
            return false
        }
        
        guard !vectorArray.isEmpty else {
            print("❌ Error: No se pudo extraer el vector del resultado")
            throw EmbeddingError.embeddingFailed
        }
        
        let dimension = 512
        guard vectorArray.count == dimension else {
            print("⚠️ Vector size: \(vectorArray.count), expected \(dimension)")
            throw EmbeddingError.embeddingFailed
        }
        
        print("✅ Embedding generado: vector \(dimension)D")
        
        let finalVector = vectorArray
        cacheEmbedding(finalVector, for: cacheKey)
        
        return finalVector
    }
    
    /// Genera embeddings para múltiples textos
    func generateEmbeddings(for texts: [String], language: NLLanguage = .spanish) async throws -> [[Double]] {
        var results: [[Double]] = []
        for text in texts {
            do {
                let vector = try await generateEmbedding(for: text, language: language)
                results.append(vector)
            } catch {
                print("⚠️ Error generando embedding para '\(text.prefix(50))': \(error)")
                throw error
            }
        }
        return results
    }
    
    // MARK: - Similarity Calculations
    
    /// Calcula similitud coseno entre dos vectores (0.0 a 1.0)
    static func cosineSimilarity(_ vector1: [Double], _ vector2: [Double]) -> Double {
        guard vector1.count == vector2.count, !vector1.isEmpty else {
            return 0.0
        }
        
        let dotProduct = zip(vector1, vector2).map(*).reduce(0, +)
        let magnitude1 = sqrt(vector1.map { $0 * $0 }.reduce(0, +))
        let magnitude2 = sqrt(vector2.map { $0 * $0 }.reduce(0, +))
        
        guard magnitude1 > 0, magnitude2 > 0 else {
            return 0.0
        }
        
        let similarity = dotProduct / (magnitude1 * magnitude2)
        return max(0, min(1, (similarity + 1) / 2))
    }
    
    /// Encuentra los top-K candidatos más similares
    static func topKSimilar<T>(
        to queryVector: [Double],
        from candidates: [(id: T, vector: [Double])],
        k: Int
    ) -> [(id: T, score: Double)] {
        let scores = candidates.map { candidate in
            (id: candidate.id, score: cosineSimilarity(queryVector, candidate.vector))
        }
        
        let sorted = scores.sorted { $0.score > $1.score }
        return Array(sorted.prefix(k))
    }
    
    // MARK: - Cache Management
    
    private func cacheEmbedding(_ vector: [Double], for key: String) {
        if embeddingCache.count >= maxCacheSize {
            if let firstKey = embeddingCache.keys.first {
                embeddingCache.removeValue(forKey: firstKey)
            }
        }
        embeddingCache[key] = vector
    }
    
    func clearCache() {
        embeddingCache.removeAll()
        print("🗑️ Cache de embeddings limpiado")
    }
    
    // MARK: - Statistics
    
    var statistics: EmbeddingStatistics {
        EmbeddingStatistics(
            readyLanguages: Array(readyLanguages),
            cachedEmbeddings: embeddingCache.count,
            maxCacheSize: maxCacheSize
        )
    }
}

// MARK: - Statistics Model

struct EmbeddingStatistics {
    let readyLanguages: [NLLanguage]
    let cachedEmbeddings: Int
    let maxCacheSize: Int
    
    var cacheUsagePercentage: Double {
        Double(cachedEmbeddings) / Double(maxCacheSize) * 100
    }
    
    var description: String {
        """
        📊 Embedding Service Stats:
        - Idiomas listos: \(readyLanguages.map { $0.rawValue }.joined(separator: ", "))
        - Cache: \(cachedEmbeddings)/\(maxCacheSize) (\(String(format: "%.1f", cacheUsagePercentage))%)
        """
    }
}

// MARK: - Extensions

extension NLLanguage {
    var displayName: String {
        switch self {
        case .spanish:
            return "Español"
        case .english:
            return "English"
        default:
            return rawValue
        }
    }
}
