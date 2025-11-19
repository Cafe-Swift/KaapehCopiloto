//
//  KnowledgeBaseInitializer.swift
//  KaapehCopiloto2
//
//  Orquestador principal para inicializar la base de conocimiento RAG
//

import Foundation
import Combine
import NaturalLanguage

enum KnowledgeBaseError: Error, LocalizedError {
    case servicesNotAvailable
    case noDocumentsLoaded
    case initializationFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .servicesNotAvailable:
            return "Los servicios de IA no están disponibles"
        case .noDocumentsLoaded:
            return "No se pudieron cargar documentos"
        case .initializationFailed(let reason):
            return "Error en la inicialización: \(reason)"
        }
    }
}

@MainActor
final class KnowledgeBaseInitializer: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isInitializing = false
    @Published var progress: Double = 0.0
    @Published var statusMessage = ""
    @Published var totalChunksIndexed = 0
    
    // MARK: - Services
    
    private let documentLoader = DocumentLoaderService()
    private let textChunker = TextChunkerService()
    private var embeddingService: EmbeddingService?
    private var vectorDatabase: VectorDatabaseService?
    
    // MARK: - Statistics
    
    struct InitializationStats {
        var documentsLoaded = 0
        var documentsWithErrors = 0
        var totalChunks = 0
        var totalVectors = 0
        var durationSeconds: TimeInterval = 0
    }
    
    private(set) var stats = InitializationStats()
    
    // MARK: - Initialization
    
    init() {
        self.embeddingService = EmbeddingService()
    }
    
    // MARK: - Public API
    
    /// Inicializar base de conocimiento completa
    func initialize() async throws {
        let startTime = Date()
        isInitializing = true
        progress = 0.0
        totalChunksIndexed = 0
        stats = InitializationStats()
        
        defer {
            isInitializing = false
            stats.durationSeconds = Date().timeIntervalSince(startTime)
        }
        
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📚 INICIALIZANDO BASE DE CONOCIMIENTO RAG")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        // 1. Verificar servicios
        try await verifyServices()
        updateStatus("Servicios verificados")
        progress = 0.1
        
        // 2. Cargar documentos del Bundle
        let documents = try await loadDocuments()
        updateStatus("Documentos cargados: \(documents.count)")
        progress = 0.2
        
        guard !documents.isEmpty else {
            throw KnowledgeBaseError.noDocumentsLoaded
        }
        
        // 3. Procesar cada documento
        try await processDocuments(documents)
        progress = 1.0
        
        // 4. Imprimir resumen
        printSummary()
        
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("✅ INICIALIZACIÓN COMPLETADA")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        // 5. 🧹 Limpiar duplicados
        print("")
        vectorDatabase?.removeDuplicates()
    }
    
    // MARK: - Private Methods
    
    /// Verificar que todos los servicios estén disponibles
    private func verifyServices() async throws {
        print("🔍 Verificando servicios...")
        
        // Verificar EmbeddingService
        guard let embeddingService = embeddingService else {
            throw KnowledgeBaseError.servicesNotAvailable
        }
        
        // Inicializar si no está listo
        if !embeddingService.isReady {
            print("   ⏳ Esperando a que EmbeddingService esté listo...")
        }
        
        // Usar singleton de VectorDatabaseService
        self.vectorDatabase = VectorDatabaseService.shared
        print("   ✅ VectorDatabaseService (shared) listo")
        
        print("   ✅ Todos los servicios disponibles")
    }
    
    /// Cargar documentos del Bundle
    private func loadDocuments() async throws -> [(filename: String, content: String, category: String)] {
        print("📂 Cargando documentos del Bundle...")
        
        let documents = try documentLoader.loadAllDocuments()
        
        stats.documentsLoaded = documents.count
        
        return documents
    }
    
    /// Procesar todos los documentos
    private func processDocuments(_ documents: [(String, String, String)]) async throws {
        print("⚙️  Procesando documentos...")
        
        guard let embeddingService = embeddingService,
              let vectorDatabase = vectorDatabase else {
            throw KnowledgeBaseError.servicesNotAvailable
        }
        
        let totalDocuments = documents.count
        var processedDocuments = 0
        
        for (filename, content, category) in documents {
            print("")
            print("📄 Procesando: \(filename)")
            
                // 1. Dividir en chunks
                let chunks = textChunker.chunkText(
                    content,
                    title: filename.replacingOccurrences(of: ".pdf", with: "").replacingOccurrences(of: ".txt", with: ""),
                    category: category
                )
                
                stats.totalChunks += chunks.count
                print("   └─> \(chunks.count) chunks generados")
                
                // 2. Procesar cada chunk
                var chunksIndexed = 0
                for (chunkTitle, chunkContent, chunkCategory) in chunks {
                    do {
                        // Generar embedding
                        let vector = try await embeddingService.generateEmbedding(
                            for: chunkContent,
                            language: .spanish
                        )
                        
                        // Crear chunk
                        let chunk = DocumentChunkSimple(
                            id: UUID(),
                            title: chunkTitle,
                            content: chunkContent,
                            category: chunkCategory,
                            vector: vector.map { Float($0) },
                            originalDocumentId: filename,
                            createdAt: Date()
                        )
                        
                        // Almacenar en vector database
                        try vectorDatabase.add(chunk: chunk)
                        
                        chunksIndexed += 1
                        totalChunksIndexed += 1
                        stats.totalVectors += 1
                        
                    } catch {
                        print("   ⚠️ Error procesando chunk: \(error.localizedDescription)")
                    }
                }
                
                print("   ✅ \(chunksIndexed)/\(chunks.count) chunks indexados")
                
                processedDocuments += 1
                progress = 0.2 + (0.8 * Double(processedDocuments) / Double(totalDocuments))
                updateStatus("Procesados: \(processedDocuments)/\(totalDocuments)")
                
        }
    }
    
    /// Actualizar mensaje de estado
    private func updateStatus(_ message: String) {
        statusMessage = message
        print("   📊 \(message)")
    }
    
    /// Imprimir resumen de inicialización
    private func printSummary() {
        print("")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📊 RESUMEN DE INICIALIZACIÓN")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📄 Documentos procesados:    \(stats.documentsLoaded)")
        print("⚠️  Documentos con errores:   \(stats.documentsWithErrors)")
        print("🔪 Chunks totales:            \(stats.totalChunks)")
        print("🧠 Vectores indexados:        \(stats.totalVectors)")
        print("⏱️  Duración:                  \(String(format: "%.2f", stats.durationSeconds))s")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        // Calcular estadísticas adicionales
        if stats.totalChunks > 0 {
            let avgVectorsPerChunk = Double(stats.totalVectors) / Double(stats.totalChunks)
            print("📈 Tasa de éxito:             \(String(format: "%.1f", avgVectorsPerChunk * 100))%")
        }
        
        if stats.durationSeconds > 0 {
            let chunksPerSecond = Double(stats.totalChunks) / stats.durationSeconds
            print("⚡ Chunks/segundo:            \(String(format: "%.2f", chunksPerSecond))")
        }
    }
    
    // MARK: - Quick Test
    
    /// Función de prueba rápida
    func quickTest() async throws {
        print("🧪 Ejecutando prueba rápida de RAG...")
        
        guard let vectorDatabase = vectorDatabase else {
            print("❌ Vector database no disponible")
            return
        }
        
        // Hacer una búsqueda de prueba
        let testQuery = "¿Cómo tratar la roya del café?"
        
        do {
            let results = try await vectorDatabase.search(query: testQuery, topK: 3)
            
            print("✅ Búsqueda de prueba exitosa:")
            print("   Query: \(testQuery)")
            print("   Resultados: \(results.count)")
            
            for (index, result) in results.enumerated() {
                print("   \(index + 1). \(result.document.title) (score: \(String(format: "%.3f", result.similarityScore)))")
            }
        } catch {
            print("❌ Error en búsqueda de prueba: \(error)")
        }
    }
}
