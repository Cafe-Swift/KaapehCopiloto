//
//  MockEmbeddingService.swift
//  KaapehCopiloto2
//
//  Servicio de embeddings SIMULADO para desarrollo en simulador
//  ⚠️ NO usar en producción - Solo para testing de UI
//

import Foundation

#if targetEnvironment(simulator)
#warning("⚠️ SIMULADOR: MockEmbeddingService disponible para testing de UI. Ejecutar en dispositivo físico para producción.")
#endif

/// Servicio mock que genera embeddings aleatorios (solo para testing de UI en simulador)
final class MockEmbeddingService {
    
    /// Genera embedding simulado basado en hash del texto
    /// - Parameter text: Texto de entrada
    /// - Returns: Vector de 512 dimensiones normalizado
    func generateMockEmbedding(for text: String) -> [Double] {
        // Usar hash del texto como seed para consistencia
        let seed = abs(text.hashValue)
        var rng = SeededRandomNumberGenerator(seed: UInt64(seed))
        
        // Generar vector de 512 dimensiones con valores normalizados
        var vector: [Double] = []
        var sumSquares: Double = 0.0
        
        for _ in 0..<512 {
            let value = Double.random(in: -1.0...1.0, using: &rng)
            vector.append(value)
            sumSquares += value * value
        }
        
        // Normalizar vector (magnitud = 1)
        let magnitude = sqrt(sumSquares)
        return vector.map { $0 / magnitude }
    }
}

// MARK: - Seeded Random Number Generator

/// Generador de números aleatorios con seed fijo para reproducibilidad
struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64
    
    init(seed: UInt64) {
        state = seed
    }
    
    mutating func next() -> UInt64 {
        // Linear Congruential Generator
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}
