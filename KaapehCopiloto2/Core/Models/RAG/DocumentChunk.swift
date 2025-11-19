//
//  DocumentChunk.swift
//  KaapehCopiloto2
//
//  Entity de ObjectBox para almacenar chunks de documentos con embeddings
//  Usa HNSW index para búsquedas vectoriales ultra-rápidas (<10ms)
//

import Foundation
import ObjectBox

// MARK: - ObjectBox Entity
/// Chunk de documento con embedding vectorial para búsqueda semántica
/// ObjectBox lo convierte automáticamente en una tabla optimizada
// objectbox: entity
final class DocumentChunk {
    // MARK: - Properties
    
    /// ID único de ObjectBox (auto-incremental)
    var id: Id = 0
    
    /// Título del documento original
    var title: String = ""
    
    /// Contenido del chunk de texto
    var content: String = ""
    
    /// Categoría del documento ("roya", "nutricion", "cuidados", "tratamientos")
    var category: String = ""
    
    /// Embedding vector de 512 dimensiones (NLContextualEmbedding)
    /// CRÍTICO: Este campo tiene el HNSW index para búsquedas rápidas
    // objectbox: index(type:.hnsw)
    var vector: [Float] = []
    
    /// ID del documento original en SwiftData (para compatibilidad)
    var originalDocumentId: String = ""
    
    /// Fecha de creación
    var createdAt: Date = Date()
    
    /// Metadata adicional como JSON string
    var metadata: String? = nil
    
    // MARK: - Computed Properties
    
    /// Verifica si tiene embedding válido
    var hasValidEmbedding: Bool {
        return vector.count == 512
    }
    
    /// Tamaño del contenido en caracteres
    var contentSize: Int {
        return content.count
    }
    
    // MARK: - Initialization
    
    /// Constructor requerido por ObjectBox
    required init() {}
    
    /// Constructor conveniente
    init(
        title: String,
        content: String,
        category: String,
        vector: [Float],
        originalDocumentId: String,
        metadata: String? = nil
    ) {
        self.title = title
        self.content = content
        self.category = category
        self.vector = vector
        self.originalDocumentId = originalDocumentId
        self.metadata = metadata
        self.createdAt = Date()
    }
}

// MARK: - Conversions
extension DocumentChunk {
    /// Convierte desde KnowledgeDocument (SwiftData) a DocumentChunk (ObjectBox)
    static func from(knowledgeDoc: KnowledgeDocument) -> DocumentChunk {
        let chunk = DocumentChunk()
        chunk.title = knowledgeDoc.title
        chunk.content = knowledgeDoc.content
        chunk.category = knowledgeDoc.category
        chunk.vector = knowledgeDoc.vector.map { Float($0) } // Double → Float
        chunk.originalDocumentId = knowledgeDoc.id.uuidString
        chunk.metadata = knowledgeDoc.metadata
        chunk.createdAt = knowledgeDoc.createdAt
        return chunk
    }
    
    /// Convierte de vuelta a KnowledgeDocument para compatibilidad
    func toKnowledgeDocument() -> KnowledgeDocument {
        return KnowledgeDocument(
            id: UUID(uuidString: originalDocumentId) ?? UUID(),
            title: title,
            content: content,
            category: category,
            vector: vector.map { Double($0) }, // Float → Double
            createdAt: createdAt,
            metadata: metadata
        )
    }
}

// MARK: - Identifiable Extension
extension DocumentChunk: Identifiable {
    // ObjectBox usa 'id' como Id, pero para SwiftUI necesitamos UUID
    var uuid: UUID {
        return UUID(uuidString: originalDocumentId) ?? UUID()
    }
}
