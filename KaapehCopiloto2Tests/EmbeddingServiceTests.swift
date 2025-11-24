//
//  EmbeddingServiceTests.swift
//  KaapehCopiloto2Tests
//
//  Created by Test Suite on 23/11/25.
//

import Testing
import Foundation
@testable import KaapehCopiloto2

@MainActor
struct EmbeddingServiceTests {
    
    var service: EmbeddingService
    
    init() throws {
        guard let service = EmbeddingService() else {
            throw TestError.serviceInitFailed
        }
        self.service = service
    }
    
    enum TestError: Error {
        case serviceInitFailed
        case embeddingFailed
    }
    
    // MARK: - Initialization Tests
    
    @Test("EmbeddingService initializes successfully")
    func testServiceInitialization() throws {
        #expect(service.isReady)
    }
    
    @Test("Embedding service supports Spanish")
    func testSpanishSupport() async throws {
        let text = "La roya del café es una enfermedad"
        let vector = try await service.generateEmbedding(for: text)
        
        #expect(vector.count == 512)
        #expect(vector.allSatisfy { $0.isFinite })
    }
    
    @Test("Embedding service supports English")
    func testEnglishSupport() async throws {
        let text = "Coffee rust is a disease"
        let vector = try await service.generateEmbedding(for: text)
        
        #expect(vector.count == 512)
        #expect(vector.allSatisfy { $0.isFinite })
    }
    
    // MARK: - Vector Generation Tests
    
    @Test("Generate embedding for normal text")
    func testGenerateEmbeddingNormalText() async throws {
        let text = "Deficiencia de nitrógeno en plantas de café"
        let vector = try await service.generateEmbedding(for: text)
        
        #expect(vector.count == 512)
        #expect(vector.allSatisfy { $0.isFinite })
    }
    
    @Test("Generate embedding for short text")
    func testGenerateEmbeddingShortText() async throws {
        let text = "Roya"
        let vector = try await service.generateEmbedding(for: text)
        
        #expect(vector.count == 512)
        #expect(vector.allSatisfy { $0.isFinite })
    }
    
    @Test("Generate embedding for long text")
    func testGenerateEmbeddingLongText() async throws {
        let longText = String(repeating: "La roya del café es una enfermedad causada por el hongo Hemileia vastatrix. ", count: 10)
        let vector = try await service.generateEmbedding(for: longText)
        
        #expect(vector.count == 512)
        #expect(vector.allSatisfy { $0.isFinite })
    }
    
    @Test("Handle empty text gracefully")
    func testGenerateEmbeddingEmptyText() async throws {
        let text = ""
        
        await #expect(throws: Error.self) {
            _ = try await service.generateEmbedding(for: text)
        }
    }
    
    @Test("Handle whitespace-only text")
    func testGenerateEmbeddingWhitespaceText() async throws {
        let text = "   \n\t   "
        
        await #expect(throws: Error.self) {
            _ = try await service.generateEmbedding(for: text)
        }
    }
    
    // MARK: - Vector Similarity Tests
    
    @Test("Similar texts produce similar vectors")
    func testSimilarTextsProduceSimilarVectors() async throws {
        let text1 = "Roya del café"
        let text2 = "Enfermedad de la roya del café"
        
        let vector1 = try await service.generateEmbedding(for: text1)
        let vector2 = try await service.generateEmbedding(for: text2)
        
        let similarity = cosineSimilarity(vector1, vector2)
        
        // Los textos similares deberían tener alta similitud (> 0.7)
        #expect(similarity > 0.7)
    }
    
    @Test("Different texts produce different vectors")
    func testDifferentTextsProduceDifferentVectors() async throws {
        let text1 = "Roya del café"
        let text2 = "Precio del mercado financiero"
        
        let vector1 = try await service.generateEmbedding(for: text1)
        let vector2 = try await service.generateEmbedding(for: text2)
        
        let similarity = cosineSimilarity(vector1, vector2)
        
        // Los textos diferentes deberían tener baja similitud (< 0.5)
        #expect(similarity < 0.5)
    }
    
    @Test("Same text produces identical vectors")
    func testSameTextProducesIdenticalVectors() async throws {
        let text = "Deficiencia de nitrógeno"
        
        let vector1 = try await service.generateEmbedding(for: text)
        let vector2 = try await service.generateEmbedding(for: text)
        
        let similarity = cosineSimilarity(vector1, vector2)
        
        // El mismo texto debería producir vectores casi idénticos (> 0.99)
        #expect(similarity > 0.99)
    }
    
    // MARK: - Performance Tests
    
    @Test("Generate embedding completes in reasonable time")
    func testEmbeddingPerformance() async throws {
        let text = "La roya del café es una enfermedad causada por el hongo Hemileia vastatrix"
        
        let startTime = Date()
        _ = try await service.generateEmbedding(for: text)
        let duration = Date().timeIntervalSince(startTime)
        
        // Debería completarse en menos de 2 segundos
        #expect(duration < 2.0)
    }
    
    @Test("Batch embedding generation")
    func testBatchEmbeddingGeneration() async throws {
        let texts = [
            "Roya del café",
            "Deficiencia de nitrógeno",
            "Planta sana",
            "Broca del café",
            "Falta de potasio"
        ]
        
        let vectors = try await withThrowingTaskGroup(of: [Double].self) { group in
            for text in texts {
                group.addTask {
                    try await self.service.generateEmbedding(for: text)
                }
            }
            
            var results: [[Double]] = []
            for try await vector in group {
                results.append(vector)
            }
            return results
        }
        
        #expect(vectors.count == texts.count)
        #expect(vectors.allSatisfy { $0.count == 512 })
    }
    
    // MARK: - Helper Functions
    
    private func cosineSimilarity(_ a: [Double], _ b: [Double]) -> Double {
        guard a.count == b.count else { return 0.0 }
        
        let dotProduct = zip(a, b).map(*).reduce(0, +)
        let magnitudeA = sqrt(a.map { $0 * $0 }.reduce(0, +))
        let magnitudeB = sqrt(b.map { $0 * $0 }.reduce(0, +))
        
        guard magnitudeA > 0, magnitudeB > 0 else { return 0.0 }
        
        return dotProduct / (magnitudeA * magnitudeB)
    }
}
