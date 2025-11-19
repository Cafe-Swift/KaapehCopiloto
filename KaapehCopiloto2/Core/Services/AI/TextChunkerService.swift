//
//  TextChunkerService.swift
//  KaapehCopiloto2
//
//  Servicio para dividir textos largos en chunks manejables
//

import Foundation

final class TextChunkerService {
    
    // MARK: - Configuration
    
    struct ChunkConfig {
        /// Máximo de palabras por chunk (aprox. 400-500 palabras = ~2000 caracteres)
        let maxWordsPerChunk: Int
        
        /// Palabras de overlap entre chunks para mantener contexto
        let overlapWords: Int
        
        static let `default` = ChunkConfig(
            maxWordsPerChunk: 150,
            overlapWords: 25
        )
    }
    
    private let config: ChunkConfig
    
    init(config: ChunkConfig = .default) {
        self.config = config
    }
    
    // MARK: - Chunking
    
    /// Divide un texto largo en chunks manejables con overlap
    func chunkText(
        _ text: String,
        title: String,
        category: String
    ) -> [(title: String, content: String, category: String)] {
        
        print("🔪 Chunking documento: \(title)")
        
        // 1. Limpiar y normalizar texto
        let cleanText = cleanAndNormalizeText(text)
        
        // 2. Dividir en párrafos
        let paragraphs = splitIntoParagraphs(cleanText)
        
        print("   └─> \(paragraphs.count) párrafos encontrados")
        
        // 3. Agrupar párrafos en chunks con overlap
        let chunks = groupParagraphsIntoChunks(
            paragraphs: paragraphs,
            title: title,
            category: category
        )
        
        print("   └─> \(chunks.count) chunks generados")
        
        return chunks
    }
    
    // MARK: - Private Helpers
    
    /// Limpiar y normalizar texto
    private func cleanAndNormalizeText(_ text: String) -> String {
        var cleaned = text
        
        // Eliminar múltiples saltos de línea
        cleaned = cleaned.replacingOccurrences(
            of: "\n\n\n+",
            with: "\n\n",
            options: .regularExpression
        )
        
        // Eliminar espacios múltiples
        cleaned = cleaned.replacingOccurrences(
            of: " +",
            with: " ",
            options: .regularExpression
        )
        
        // Trim espacios al inicio y final
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return cleaned
    }
    
    /// Dividir texto en párrafos
    private func splitIntoParagraphs(_ text: String) -> [String] {
        return text
            .components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
    
    /// Agrupar párrafos en chunks con overlap
    private func groupParagraphsIntoChunks(
        paragraphs: [String],
        title: String,
        category: String
    ) -> [(title: String, content: String, category: String)] {
        
        var chunks: [(String, String, String)] = []
        var currentChunk = ""
        var currentWordCount = 0
        var chunkIndex = 1
        
        for paragraph in paragraphs {
            let paragraphWords = paragraph.split(separator: " ")
            let paragraphWordCount = paragraphWords.count
            
            // Si agregar este párrafo excede el límite
            if currentWordCount + paragraphWordCount > config.maxWordsPerChunk {
                // Guardar el chunk actual si no está vacío
                if !currentChunk.isEmpty {
                    let chunkTitle = chunks.isEmpty
                        ? title  // Primer chunk usa título original
                        : "\(title) - Parte \(chunkIndex)"
                    
                    chunks.append((chunkTitle, currentChunk.trimmingCharacters(in: .whitespacesAndNewlines), category))
                    chunkIndex += 1
                    
                    // Crear overlap: mantener las últimas N palabras
                    let overlapText = createOverlap(from: currentChunk)
                    currentChunk = overlapText
                    currentWordCount = overlapText.split(separator: " ").count
                }
            }
            
            // Agregar párrafo al chunk actual
            if !currentChunk.isEmpty {
                currentChunk += "\n\n"
            }
            currentChunk += paragraph
            currentWordCount += paragraphWordCount
        }
        
        // Agregar último chunk si tiene contenido
        if !currentChunk.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let chunkTitle = chunks.isEmpty
                ? title
                : "\(title) - Parte \(chunkIndex)"
            
            chunks.append((chunkTitle, currentChunk.trimmingCharacters(in: .whitespacesAndNewlines), category))
        }
        
        return chunks
    }
    
    /// Crear overlap: extraer últimas N palabras del chunk
    private func createOverlap(from text: String) -> String {
        let words = text.split(separator: " ")
        guard words.count > config.overlapWords else {
            return text
        }
        
        let overlapWords = words.suffix(config.overlapWords)
        return overlapWords.joined(separator: " ")
    }
    
    // MARK: - Statistics
    
    /// Obtener estadísticas de un texto
    func getTextStatistics(_ text: String) -> (words: Int, chars: Int, paragraphs: Int) {
        let cleaned = cleanAndNormalizeText(text)
        let paragraphs = splitIntoParagraphs(cleaned)
        let words = cleaned.split(separator: " ").count
        let chars = cleaned.count
        
        return (words, chars, paragraphs.count)
    }
}
