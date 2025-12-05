import Foundation
import SwiftUI
import Combine

class KaapehTranslator: ObservableObject {
    
    static let shared = KaapehTranslator()
    
    // Diccionario final: [ "frase en español" : "frase en tzotzil" ]
    @Published var dictionary: [String: String] = [:]
    
    // Variable para saber si el modo Tzotzil está activado
    @Published var isTzotzilActive: Bool = false
    
    init() {
        loadVocabularies()
    }
    
    func loadVocabularies() {
        
        let spanishFilename = "vocab_spanish"  // ← Cambia aquí si renombraste
        let tzotzilFilename = "vocab_tsotsil"  // ← Cambia aquí si renombraste
        
        // 1. Cargar JSON Español
        let spanishMap = loadJSONNewFormat(filename: spanishFilename)
        print("📖 Español cargado: \(spanishMap.count) entradas")
        
        // 2. Cargar JSON Tzotzil
        let tzotzilMap = loadJSONNewFormat(filename: tzotzilFilename)
        print("📖 Tzotzil cargado: \(tzotzilMap.count) entradas")
        
        // 3. Cruzar los datos usando los IDs como clave común
        for (id, spanishText) in spanishMap {
            if let tzotzilText = tzotzilMap[id] {
                // Guardamos en el diccionario final
                self.dictionary[spanishText] = tzotzilText
                
                // También guardamos la versión en minúsculas para búsqueda flexible
                self.dictionary[spanishText.lowercased()] = tzotzilText
            }
        }
        
        print("✅ Vocabularios cargados. Frases listas: \(dictionary.count)")
        
        // Debug: Imprime algunas traducciones
        #if DEBUG
        print("📖 Ejemplos de traducciones:")
        let examples = Array(dictionary.prefix(10))
        for (es, tso) in examples {
            print("   '\(es)' → '\(tso)'")
        }
        #endif
    }
    
    // Carga del nuevo formato JSON: {"0": "texto", "1": "texto", ...}
    private func loadJSONNewFormat(filename: String) -> [String: String] {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "json") else {
            print("❌ No se encontró el archivo: \(filename).json")
            print("   Verifica que el archivo esté en tu proyecto y agregado al target")
            return [:]
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode([String: String].self, from: data)
            print("✅ Archivo \(filename).json cargado correctamente")
            return decoded
        } catch {
            print("❌ Error leyendo JSON '\(filename)': \(error)")
            
            // Intenta con el formato antiguo como fallback
            do {
                let data = try Data(contentsOf: url)
                let decodedOld = try JSONDecoder().decode([String: Int].self, from: data)
                print("⚠️ Archivo está en formato antiguo (palabra: ID)")
                print("   Convierte el formato o usa loadJSONOldFormat()")
                
                // Convertir formato antiguo a nuevo
                var converted: [String: String] = [:]
                for (word, id) in decodedOld {
                    converted[String(id)] = word
                }
                return converted
            } catch {
                print("❌ No se pudo cargar ni en formato nuevo ni antiguo")
                return [:]
            }
        }
    }
    
    // FUNCIÓN PRINCIPAL QUE USARÁS EN LA UI
    func t(_ text: String) -> String {
        // Si no está activo el modo Tzotzil, devuelve el español original
        if !isTzotzilActive {
            return text
        }
        
        // 1. Intenta buscar la frase exacta
        if let translation = dictionary[text] {
            return translation
        }
        
        // 2. Intenta buscar en minúsculas
        let lowerText = text.lowercased()
        if let translation = dictionary[lowerText] {
            // Si el original tenía mayúscula inicial, capitalizamos la traducción
            if text.first?.isUppercase == true {
                return translation.prefix(1).uppercased() + translation.dropFirst()
            }
            return translation
        }
        
        // 3. Búsqueda parcial: si el texto contiene alguna frase conocida
        for (key, value) in dictionary {
            if text.lowercased().contains(key.lowercased()) {
                return text.replacingOccurrences(
                    of: key,
                    with: value,
                    options: .caseInsensitive
                )
            }
        }
        
        // 4. Si no encuentra nada, devuelve el texto original
        print("⚠️ Traducción no encontrada para: '\(text)'")
        return text
    }
    
    // Función para cambiar el idioma
    func toggleLanguage() {
        isTzotzilActive.toggle()
        print("🌐 Idioma cambiado a: \(isTzotzilActive ? "Tsotsil" : "Español")")
    }
    
    // Función para establecer el idioma por código
    func setLanguage(_ languageCode: String) {
        // Evitar publicar cambios si ya está en el estado correcto
        let shouldBeActive = (languageCode == "tsz" || languageCode == "tsotsil")
        
        if isTzotzilActive != shouldBeActive {
            // Usar DispatchQueue para evitar "Publishing changes from within view updates"
            DispatchQueue.main.async {
                self.isTzotzilActive = shouldBeActive
                self.objectWillChange.send()
                print("🌐 Idioma establecido a: \(languageCode) (Tsotsil: \(shouldBeActive))")
            }
        }
    }
    
    // Helper: Traducir múltiples textos a la vez
    func translateBatch(_ texts: [String]) -> [String] {
        texts.map { t($0) }
    }
    
    // Helper: Verificar si una traducción existe
    func hasTranslation(for text: String) -> Bool {
        dictionary[text] != nil || dictionary[text.lowercased()] != nil
    }
}

// MARK: - Extension para usar en SwiftUI más fácilmente
extension String {
    func translated() -> String {
        KaapehTranslator.shared.t(self)
    }
}

// MARK: - View Modifier para traducción automática
struct TranslatedText: ViewModifier {
    let text: String
    @ObservedObject var translator = KaapehTranslator.shared
    
    func body(content: Content) -> some View {
        content
            .onChange(of: translator.isTzotzilActive) { _ in
                // Forzar redibujado cuando cambia el idioma
            }
    }
}

extension View {
    func translatable() -> some View {
        self.modifier(TranslatedText(text: ""))
    }
}
