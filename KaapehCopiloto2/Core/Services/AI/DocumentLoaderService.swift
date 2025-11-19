//
//  DocumentLoaderService.swift
//  KaapehCopiloto2
//
//  Servicio para cargar documentos desde Bundle o file system
//

import Foundation
import PDFKit

enum DocumentError: Error, LocalizedError {
    case fileNotFound
    case unsupportedFormat
    case pdfReadError
    case emptyDocument
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "Archivo no encontrado en el Bundle"
        case .unsupportedFormat:
            return "Formato de archivo no soportado (usa .txt o .pdf)"
        case .pdfReadError:
            return "No se pudo leer el archivo PDF"
        case .emptyDocument:
            return "El documento está vacío"
        }
    }
}

// Removed @MainActor - este servicio solo procesa archivos, no necesita main thread
final class DocumentLoaderService {
    
    // MARK: - Load from Bundle
    
    /// Cargar documento desde Bundle de la app
    func loadFromBundle(filename: String, subdirectory: String = "Resources/KnowledgeBase") throws -> String {
        print("📂 Intentando cargar: \(filename) desde Bundle")
        
        // Primero intentar cargar con el subdirectory exacto
        var url = Bundle.main.url(forResource: filename, withExtension: nil, subdirectory: subdirectory)
        
        // Si no funciona, intentar con "KnowledgeBase" directamente
        if url == nil {
            url = Bundle.main.url(forResource: filename, withExtension: nil, subdirectory: "KnowledgeBase")
        }
        
        // Si aún no funciona, buscar en el bundle principal
        if url == nil {
            let nameWithoutExtension = (filename as NSString).deletingPathExtension
            let ext = (filename as NSString).pathExtension
            url = Bundle.main.url(forResource: nameWithoutExtension, withExtension: ext.isEmpty ? nil : ext)
        }
        
        guard let finalURL = url else {
            print("❌ Archivo no encontrado: \(filename)")
            throw DocumentError.fileNotFound
        }
        
        print("✅ Archivo encontrado en: \(finalURL.path)")
        
        // Detectar tipo de archivo y extraer texto
        if filename.hasSuffix(".pdf") {
            return try extractTextFromPDF(url: finalURL)
        } else if filename.hasSuffix(".txt") || filename.hasSuffix(".md") {
            let content = try String(contentsOf: finalURL, encoding: .utf8)
            guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw DocumentError.emptyDocument
            }
            return content
        } else {
            throw DocumentError.unsupportedFormat
        }
    }
    
    // MARK: - PDF Extraction
    
    /// Extraer texto de archivo PDF
    private func extractTextFromPDF(url: URL) throws -> String {
        guard let pdfDocument = PDFDocument(url: url) else {
            throw DocumentError.pdfReadError
        }
        
        var fullText = ""
        let pageCount = pdfDocument.pageCount
        
        print("📄 PDF tiene \(pageCount) páginas")
        
        for pageIndex in 0..<pageCount {
            guard let page = pdfDocument.page(at: pageIndex),
                  let pageText = page.string else {
                continue
            }
            
            fullText += pageText + "\n\n"
        }
        
        guard !fullText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw DocumentError.emptyDocument
        }
        
        print("✅ Extraído texto de PDF: \(fullText.count) caracteres")
        return fullText
    }
    
    // MARK: - Batch Loading
    
    /// Cargar todos los documentos de la base de conocimiento
    func loadAllDocuments() throws -> [(filename: String, content: String, category: String)] {
        print("📚 Cargando todos los documentos de la base de conocimiento...")
        
        // LISTA DE DOCUMENTOS A CARGAR
        // ✅ PDFs reales cargados por el usuario en Resources/KnowledgeBase/
        let documents: [(filename: String, category: String)] = [
            // Fichas Técnicas y Organización
            ("Ficha Técnica TERRA.IO - Káapeh México ESP.pdf", "organizacion"),
            ("Kaapeh Mexico NGO - ESP.pdf", "organizacion"),
            
            // Tratamientos y Control de Enfermedades (ROYA)
            ("Manual 1 Biopreparado para control de la roya y nutrición.pdf", "roya"),
            
            // Nutrición del Café
            ("3. Valoración nutricional de la planta a través de las hojas Final1.pdf", "nutricion"),
            ("Triptico Analisis Deficiencia Nutrientes.pdf", "nutricion"),
            
            // Química y Ciencia del Café
            ("La química del café.pdf", "ciencia"),
            
            // Tecnología y Comunicación (Contexto)
            ("Towards pluriversal views of digital technologies  the experiences of community and indigenous radios .pdf", "tecnologia")
        ]
        
        var results: [(String, String, String)] = []
        var loadedCount = 0
        var errorCount = 0
        
        for (filename, category) in documents {
            do {
                let content = try loadFromBundle(filename: filename)
                results.append((filename, content, category))
                loadedCount += 1
                print("  ✅ \(filename)")
            } catch {
                errorCount += 1
                print("  ⚠️ \(filename): \(error.localizedDescription)")
                // Continuar con los demás documentos
            }
        }
        
        print("📊 Carga completada:")
        print("   ✅ Exitosos: \(loadedCount)")
        print("   ⚠️  Errores: \(errorCount)")
        
        return results
    }
    
    // MARK: - Load from Documents Directory
    
    /// Cargar documento desde carpeta Documents del usuario
    func loadFromDocumentsDirectory(filename: String) throws -> String {
        let documentsURL = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first!
        
        let fileURL = documentsURL.appendingPathComponent(filename)
        
        if filename.hasSuffix(".pdf") {
            return try extractTextFromPDF(url: fileURL)
        } else {
            return try String(contentsOf: fileURL, encoding: .utf8)
        }
    }
}
