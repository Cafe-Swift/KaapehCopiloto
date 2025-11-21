//
//  VectorDatabaseService.swift
//  KaapehCopiloto2
//
//  Base de datos vectorial con persistencia y búsqueda por similitud de coseno
//

import Foundation
import SwiftData

// MARK: - Document Chunk Model

struct DocumentChunkSimple: Codable {
    let id: UUID
    let title: String
    let content: String
    let category: String
    let vector: [Float]
    let originalDocumentId: String
    let createdAt: Date
}

// MARK: - Vector Database Service

@MainActor
final class VectorDatabaseService {
    
    // MARK: - Singleton para compartir datos entre servicios
    static let shared = VectorDatabaseService()
    
    // MARK: - Properties
    private var documents: [DocumentChunkSimple] = []
    private var isInitialized = false
    private var embeddingService: EmbeddingService?
    
    // Persistencia
    private let fileManager = FileManager.default
    private var persistenceURL: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dbDirectory = appSupport.appendingPathComponent("VectorDB", isDirectory: true)
        
        // Crear directorio si no existe
        try? fileManager.createDirectory(at: dbDirectory, withIntermediateDirectories: true)
        
        return dbDirectory.appendingPathComponent("vector_chunks.json")
    }
    
    // MARK: - Initialization
    
    /// Inicialización privada para singleton
    private init() {
        print("🗄️ VectorDatabaseService (Singleton) inicializado")
        self.embeddingService = EmbeddingService()
        
        // Intentar cargar datos persistidos al inicio
        Task {
            await loadPersistedData()
        }
    }
    
    /// Inicialización pública para compatibilidad con código existente
    convenience init(dummy: Void = ()) {
        self.init()
    }
    
    // MARK: - Persistence Methods
    
    /// Guarda los chunks actuales en disco
    func saveToDisDisk() async {
        guard !documents.isEmpty else {
            print("⚠️ No hay datos para guardar")
            return
        }
        
        do {
            let startTime = Date()
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            
            let jsonData = try encoder.encode(documents)
            try jsonData.write(to: persistenceURL)
            
            let duration = Date().timeIntervalSince(startTime)
            let sizeInMB = Double(jsonData.count) / 1_048_576.0
            
            print("💾 Base de datos guardada exitosamente")
            print("   📊 \(documents.count) chunks persistidos")
            print("   📦 Tamaño: \(String(format: "%.2f", sizeInMB)) MB")
            print("   ⏱️ Tiempo: \(String(format: "%.3f", duration))s")
        } catch {
            print("❌ Error guardando base de datos: \(error.localizedDescription)")
        }
    }
    
    /// Carga los chunks desde disco
    func loadPersistedData() async {
        guard fileManager.fileExists(atPath: persistenceURL.path) else {
            print("ℹ️ No hay base de datos persistida para cargar")
            return
        }
        
        do {
            let startTime = Date()
            let jsonData = try Data(contentsOf: persistenceURL)
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            let loadedDocuments = try decoder.decode([DocumentChunkSimple].self, from: jsonData)
            
            self.documents = loadedDocuments
            self.isInitialized = true
            
            let duration = Date().timeIntervalSince(startTime)
            let sizeInMB = Double(jsonData.count) / 1_048_576.0
            
            print("✅ Base de datos cargada desde disco")
            print("   📊 \(documents.count) chunks restaurados")
            print("   📦 Tamaño: \(String(format: "%.2f", sizeInMB)) MB")
            print("   ⏱️ Tiempo: \(String(format: "%.3f", duration))s")
        } catch {
            print("❌ Error cargando base de datos: \(error.localizedDescription)")
            print("   💡 La base de datos será reinicializada")
        }
    }
    
    /// Elimina la base de datos persistida
    func deletePersistentData() {
        guard fileManager.fileExists(atPath: persistenceURL.path) else {
            print("ℹ️ No hay base de datos persistida para eliminar")
            return
        }
        
        do {
            try fileManager.removeItem(at: persistenceURL)
            print("🗑️ Base de datos persistida eliminada")
        } catch {
            print("❌ Error eliminando base de datos: \(error.localizedDescription)")
        }
    }
    
    /// Verifica si hay datos persistidos
    var hasPersistedData: Bool {
        return fileManager.fileExists(atPath: persistenceURL.path)
    }
    
    // MARK: - Data Management
    
    /// Agregar un chunk a la base de datos
    func add(chunk: DocumentChunkSimple) throws {
        documents.append(chunk)
        isInitialized = true
    }
    
    /// Agregar múltiples chunks
    func addBatch(chunks: [DocumentChunkSimple]) async throws {
        documents.append(contentsOf: chunks)
        isInitialized = true
        print("✅ Agregados \(chunks.count) chunks. Total: \(documents.count)")
        
        // Auto-guardar después de agregar batch
        await saveToDisDisk()
    }
    
    /// Limpiar toda la base de datos (memoria y disco)
    func clear() {
        documents.removeAll()
        isInitialized = false
        deletePersistentData()
        print("🗑️ Base de datos vectorial limpiada (memoria y disco)")
    }
    
    /// Obtener estadísticas
    func getStats() -> (totalDocuments: Int, categories: Set<String>) {
        let categories = Set(documents.map { $0.category })
        return (documents.count, categories)
    }
    
    // MARK: - Vector Search
    
    /// Buscar documentos por query usando similitud de coseno
    func search(
        query: String,
        topK: Int = 3,
        categoryFilter: String? = nil,
        minSimilarity: Double = 0.7 
    ) async throws -> [RAGSearchResult] {
        
        guard !documents.isEmpty else {
            print("⚠️ Base de datos vacía")
            return []
        }
        
        // 1. Generar embedding del query
        guard let embeddingService = self.embeddingService else {
            print("⚠️ EmbeddingService no está inicializado")
            return []
        }
        
        guard embeddingService.isReady else {
            print("⚠️ EmbeddingService no está listo")
            return []
        }
        
        let queryVector = try await embeddingService.generateEmbedding(for: query)
        let queryVectorFloat = queryVector.map { Float($0) }
        
        // 2. Filtrar por categoría si se especifica
        var candidateDocuments = documents
        if let category = categoryFilter {
            candidateDocuments = documents.filter { $0.category == category }
        }
        
        guard !candidateDocuments.isEmpty else {
            print("⚠️ No hay documentos en la categoría: \(categoryFilter ?? "ninguna")")
            return []
        }
        
        // 3. Calcular similitud de coseno para cada documento
        print("📊 Calculando similitud para \(candidateDocuments.count) documentos...")
        let results: [(doc: DocumentChunkSimple, score: Double)] = candidateDocuments.map { doc in
            let similarity = cosineSimilarity(queryVectorFloat, doc.vector)
            return (doc, similarity)
        }
        
        // Log de los mejores scores para debugging
        let top5 = results.sorted { $0.score > $1.score }.prefix(5)
        print("🎯 Top 5 similitudes:")
        for (index, result) in top5.enumerated() {
            print("   \(index + 1). \(result.doc.title) - Score: \(String(format: "%.3f", result.score))")
        }
        
        // BÚSQUEDA ADAPTATIVA: Si no hay resultados con minSimilarity, bajar el threshold
        var currentMinSimilarity = minSimilarity
        var filteredResults = results
            .filter { $0.score >= currentMinSimilarity }
            .sorted { $0.score > $1.score }
            .prefix(topK)
        
        // Si no hay resultados, intentar con threshold más bajo
        if filteredResults.isEmpty && currentMinSimilarity > 0.3 {
            print("⚠️ No se encontraron resultados con minSimilarity \(minSimilarity)")
            print("   🔄 Reintentando con threshold más bajo...")
            
            currentMinSimilarity = 0.3
            filteredResults = results
                .filter { $0.score >= currentMinSimilarity }
                .sorted { $0.score > $1.score }
                .prefix(topK)
            
            if !filteredResults.isEmpty {
                print("   ✅ Encontrados \(filteredResults.count) resultados con threshold \(currentMinSimilarity)")
            }
        }
        
        print("📋 Después del filtro (minSimilarity: \(currentMinSimilarity)): \(filteredResults.count) documentos")
        
        // 5. Convertir a RAGSearchResult
        let searchResults = filteredResults.map { result in
            // Crear KnowledgeDocument desde DocumentChunkSimple
            let knowledgeDoc = KnowledgeDocument(
                title: result.doc.title,
                content: result.doc.content,
                category: result.doc.category
            )
            knowledgeDoc.id = result.doc.id
            knowledgeDoc.createdAt = result.doc.createdAt
            
            return RAGSearchResult(
                document: knowledgeDoc,
                similarityScore: result.score
            )
        }
        
        print("🔍 Búsqueda completada: \(searchResults.count) resultados (de \(candidateDocuments.count) documentos)")
        
        return Array(searchResults)
    }
    
    // MARK: - Vector Math
    
    /// Calcular similitud de coseno entre dos vectores
    private func cosineSimilarity(_ a: [Float], _ b: [Float]) -> Double {
        guard a.count == b.count else { return 0.0 }
        
        var dotProduct: Float = 0.0
        var magnitudeA: Float = 0.0
        var magnitudeB: Float = 0.0
        
        for i in 0..<a.count {
            dotProduct += a[i] * b[i]
            magnitudeA += a[i] * a[i]
            magnitudeB += b[i] * b[i]
        }
        
        guard magnitudeA > 0 && magnitudeB > 0 else { return 0.0 }
        
        return Double(dotProduct / (sqrt(magnitudeA) * sqrt(magnitudeB)))
    }
    
    // MARK: - Status
    
    var hasDocuments: Bool {
        return !documents.isEmpty
    }
    
    var documentCount: Int {
        return documents.count
    }
    
    // MARK: - Database Maintenance
    
    /// Limpia documentos duplicados de la base de datos
    func removeDuplicates() async {
        print("🧹 Limpiando duplicados en base de datos...")
        
        let originalCount = documents.count
        print("   📊 Total chunks en DB: \(originalCount)")
        
        var seenSignatures: Set<String> = []
        var uniqueDocuments: [DocumentChunkSimple] = []
        
        for doc in documents {
            // Crear una "firma" única basada en título y contenido
            let signature = "\(doc.title)-\(doc.content.prefix(100))"
            
            if !seenSignatures.contains(signature) {
                seenSignatures.insert(signature)
                uniqueDocuments.append(doc)
            }
        }
        
        documents = uniqueDocuments
        let duplicatesRemoved = originalCount - documents.count
        
        if duplicatesRemoved > 0 {
            print("   ✅ Eliminados \(duplicatesRemoved) duplicados")
            print("   📊 Chunks restantes: \(documents.count)")
            
            // Guardar cambios
            await saveToDisDisk()
        } else {
            print("   ✅ No se encontraron duplicados")
        }
    }
}
