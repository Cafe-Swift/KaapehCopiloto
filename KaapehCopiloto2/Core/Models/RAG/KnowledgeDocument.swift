//
//  KnowledgeDocument.swift
//  KaapehCopiloto2
//
//  Modelo para documentos de la base de conocimiento RAG
//

import Foundation
import SwiftData

@Model
final class KnowledgeDocument {
    var id: UUID
    var title: String
    var content: String
    var category: String // "roya", "nutricion", "cuidados", "tratamientos"
    var vector: [Double] // Embedding vector (512-dim from NLContextualEmbedding)
    var createdAt: Date
    var metadata: String? // JSON string con metadata adicional
    
    init(
        id: UUID = UUID(),
        title: String,
        content: String,
        category: String,
        vector: [Double] = [],
        createdAt: Date = Date(),
        metadata: String? = nil
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.category = category
        self.vector = vector
        self.createdAt = createdAt
        self.metadata = metadata
    }
}

// MARK: - Helper Extensions
extension KnowledgeDocument {
    /// Verifica si el documento tiene embedding generado
    var hasEmbedding: Bool {
        !vector.isEmpty && vector.count == 512
    }
    
    /// Categorías válidas del sistema
    static let validCategories = ["roya", "nutricion", "cuidados", "tratamientos", "general"]
    
    /// Emoji representativo de la categoría
    var categoryEmoji: String {
        switch category.lowercased() {
        case "roya":
            return "🍂"
        case "nutricion":
            return "🌱"
        case "cuidados":
            return "🌿"
        case "tratamientos":
            return "💊"
        default:
            return "📄"
        }
    }
    
    /// Nombre formateado de la categoría
    var categoryDisplayName: String {
        switch category.lowercased() {
        case "roya":
            return "Roya del Café"
        case "nutricion":
            return "Nutrición"
        case "cuidados":
            return "Cuidados"
        case "tratamientos":
            return "Tratamientos"
        default:
            return "General"
        }
    }
    
    /// Tamaño del contenido (para debugging/stats)
    var contentSize: Int {
        content.utf8.count
    }
    
    /// Preview del contenido (primeros 150 caracteres)
    var contentPreview: String {
        String(content.prefix(150)) + (content.count > 150 ? "..." : "")
    }
}

/// Resultado de búsqueda RAG con score de similitud
struct RAGSearchResult {
    let document: KnowledgeDocument
    let similarityScore: Double
    
    /// Formato human-readable del score
    var scorePercentage: String {
        String(format: "%.1f%%", similarityScore * 100)
    }
    
    /// Badge de relevancia
    var relevanceBadge: (color: String, text: String) {
        if similarityScore >= 0.85 {
            return ("green", "Muy relevante")
        } else if similarityScore >= 0.7 {
            return ("blue", "Relevante")
        } else if similarityScore >= 0.5 {
            return ("orange", "Parcialmente relevante")
        } else {
            return ("gray", "Baja relevancia")
        }
    }
}

// MARK: - Static Helpers
extension KnowledgeDocument {
    /// Valida si una categoría es válida
    static func isValidCategory(_ category: String) -> Bool {
        validCategories.contains(category.lowercased())
    }
    
    /// Estadísticas de documentos por categoría
    static func categoryStats(from documents: [KnowledgeDocument]) -> [String: Int] {
        var stats: [String: Int] = [:]
        for doc in documents {
            stats[doc.category, default: 0] += 1
        }
        return stats
    }
}
