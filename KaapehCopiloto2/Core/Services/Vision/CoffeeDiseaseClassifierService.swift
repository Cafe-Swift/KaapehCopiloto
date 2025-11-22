//
//  CoffeeDiseaseClassifierService.swift
//  KaapehCopiloto2
//
//  Servicio de clasificación de enfermedades de café usando CoreML + Vision
//  Modelo entrenado con 15 clases de deficiencias, enfermedades y plagas
//

import Foundation
import CoreML
import Vision
import UIKit

// MARK: - ML Model Errors

enum MLModelError: LocalizedError {
    case modelNotAvailable
    case modelLoadFailed(Error)
    case predictionFailed(Error)
    case noResults
    
    var errorDescription: String? {
        switch self {
        case .modelNotAvailable:
            return "El modelo de IA no está disponible"
        case .modelLoadFailed(let error):
            return "Error al cargar el modelo: \(error.localizedDescription)"
        case .predictionFailed(let error):
            return "Error al realizar la predicción: \(error.localizedDescription)"
        case .noResults:
            return "No se obtuvieron resultados de la clasificación"
        }
    }
}

/// Resultado de la clasificación de imagen
struct ClassificationResult {
    let label: String
    let confidence: Double
    let allPredictions: [(label: String, confidence: Double)]
    
    /// Convierte el resultado a VisualDiagnosisResult para RAG
    nonisolated func toVisualDiagnosisResult() -> VisualDiagnosisResult {
        let (severity, immediateAction) = determineSeverityAndAction(for: label, confidence: confidence)
        
        return VisualDiagnosisResult(
            label: formatLabel(label),
            confidence: confidence,
            visualDescription: generateVisualDescription(for: label),
            severity: severity,
            immediateAction: immediateAction
        )
    }
    
    // MARK: - Helpers
    
    /// Formatea el label del modelo a texto legible en español
    nonisolated private func formatLabel(_ rawLabel: String) -> String {
        // Diccionario de traducción exacta (case-insensitive)
        let translations: [String: String] = [
            // Deficiencias nutricionales
            "nitrogen-n": "Deficiencia de Nitrógeno (N)",
            "phosphorus-p": "Deficiencia de Fósforo (P)",
            "potassium-k": "Deficiencia de Potasio (K)",
            "calcium-ca": "Deficiencia de Calcio (Ca)",
            "magnesium-mg": "Deficiencia de Magnesio (Mg)",
            "iron-fe": "Deficiencia de Hierro (Fe)",
            "manganese-mn": "Deficiencia de Manganeso (Mn)",
            "boron-b": "Deficiencia de Boro (B)",
            "more-deficiencies": "Múltiples Deficiencias Nutricionales",
            
            // Enfermedades
            "leaf rust": "Roya del Café",
            "phoma": "Mancha de Phoma",
            "cercospora": "Ojo de Gallo (Cercospora)",
            
            // Plagas
            "miner": "Minador de la Hoja",
            "rred spider mite": "Araña Roja",
            
            // Estado saludable
            "healthy": "Planta Saludable"
        ]
        
        let normalized = rawLabel.lowercased()
        
        // Buscar coincidencia exacta
        if let translation = translations[normalized] {
            return translation
        }
        
        // Buscar coincidencias parciales
        for (key, value) in translations {
            if normalized.contains(key) {
                return value
            }
        }
        
        // Si no encuentra traducción, devolver capitalizado
        return rawLabel.capitalized
    }
    
    nonisolated private func determineSeverityAndAction(for label: String, confidence: Double) -> (severity: String, action: String) {
        let normalizedLabel = label.lowercased()
        
        let severity: String
        let action: String
        
        // 1. PLANTA SANA
        if normalizedLabel.contains("healthy") {
            severity = "ninguna"
            action = "¡Excelente! La planta está saludable. Continuar con el mantenimiento regular y monitoreo preventivo."
        }
        
        // 2. ROYA (LEAF RUST) - PRIORIDAD ALTA
        else if normalizedLabel.contains("leaf rust") || normalizedLabel.contains("rust") {
            if confidence > 0.8 {
                severity = "severa"
                action = "🚨 URGENTE: Aplicar fungicida cúprico inmediatamente. Podar hojas afectadas y quemarlas. Mejorar ventilación entre plantas."
            } else if confidence > 0.6 {
                severity = "moderada"
                action = "Aplicar fungicida preventivo (cúprico o sistémico). Monitorear propagación cada 3 días. Mejorar aireación."
            } else {
                severity = "leve"
                action = "Inspeccionar de cerca para confirmar. Preparar tratamiento preventivo. Observar evolución diaria."
            }
        }
        
        // 3. DEFICIENCIAS NUTRICIONALES
        
        // Nitrógeno (N)
        else if normalizedLabel.contains("nitrogen") {
            severity = confidence > 0.7 ? "moderada" : "leve"
            action = "Aplicar fertilizante nitrogenado (urea o sulfato de amonio). Realizar análisis de suelo. Ajustar plan de fertilización."
        }
        
        // Fósforo (P)
        else if normalizedLabel.contains("phosphorus") {
            severity = confidence > 0.7 ? "moderada" : "leve"
            action = "Aplicar fertilizante fosforado (superfosfato triple). Verificar pH del suelo (debe estar entre 6.0-6.5)."
        }
        
        // Potasio (K)
        else if normalizedLabel.contains("potassium") {
            severity = confidence > 0.7 ? "moderada" : "leve"
            action = "Aplicar fertilizante rico en potasio (cloruro o sulfato de potasio). Mejorar retención de agua en el suelo."
        }
        
        // Calcio (Ca)
        else if normalizedLabel.contains("calcium") {
            severity = confidence > 0.7 ? "moderada" : "leve"
            action = "Aplicar cal agrícola o yeso. Mejorar pH del suelo. Asegurar riego adecuado para absorción de calcio."
        }
        
        // Magnesio (Mg)
        else if normalizedLabel.contains("magnesium") {
            severity = confidence > 0.7 ? "moderada" : "leve"
            action = "Aplicar sulfato de magnesio (sales de Epsom). Verificar balance con potasio. Realizar análisis foliar."
        }
        
        // Hierro (Fe)
        else if normalizedLabel.contains("iron") {
            severity = confidence > 0.7 ? "moderada" : "leve"
            action = "Aplicar quelatos de hierro foliarmente. Verificar pH del suelo (Fe se absorbe mejor en pH 5.5-6.5). Mejorar drenaje."
        }
        
        // Manganeso (Mn)
        else if normalizedLabel.contains("manganese") {
            severity = confidence > 0.7 ? "moderada" : "leve"
            action = "Aplicar sulfato de manganeso. Verificar pH del suelo. Evitar exceso de cal que bloquea absorción de Mn."
        }
        
        // Boro (B)
        else if normalizedLabel.contains("boron") {
            severity = confidence > 0.7 ? "moderada" : "leve"
            action = "⚠️ Aplicar bórax o ácido bórico CON PRECAUCIÓN (el boro es tóxico en exceso). Realizar aplicación foliar diluida."
        }
        
        // Múltiples deficiencias
        else if normalizedLabel.contains("more-deficiencies") || normalizedLabel.contains("deficiencies") {
            severity = "moderada"
            action = "🔬 Realizar análisis completo de suelo y foliar URGENTE. Aplicar fertilizante completo NPK + micronutrientes. Consultar agrónomo."
        }
        
        // 4. ENFERMEDADES FÚNGICAS
        
        // Phoma
        else if normalizedLabel.contains("phoma") {
            severity = confidence > 0.7 ? "moderada" : "leve"
            action = "Aplicar fungicida sistémico (azoxystrobin o tebuconazole). Eliminar tejido afectado. Mejorar drenaje del suelo."
        }
        
        // Cercospora (Ojo de Gallo)
        else if normalizedLabel.contains("cercospora") {
            severity = confidence > 0.7 ? "moderada" : "leve"
            action = "Aplicar fungicida sistémico (clorotalonil o mancozeb). Podar para mejorar aireación. Controlar humedad."
        }
        
        // 5. PLAGAS
        
        // Minador de la hoja (Miner)
        else if normalizedLabel.contains("miner") {
            severity = confidence > 0.7 ? "moderada" : "leve"
            action = "Aplicar insecticida sistémico (imidacloprid). Eliminar hojas muy afectadas. Controlar malezas hospederas."
        }
        
        // Araña Roja (Red Spider Mite)
        else if normalizedLabel.contains("spider") || normalizedLabel.contains("mite") {
            severity = confidence > 0.8 ? "severa" : "moderada"
            action = "Aplicar acaricida específico (abamectina o azufre). Aumentar humedad ambiental. Lavar hojas con agua a presión."
        }
        
        // CASO POR DEFECTO
        else {
            severity = confidence > 0.7 ? "moderada" : "leve"
            action = "Monitorear la planta de cerca. Considerar análisis foliar completo. Consultar con agrónomo si persiste."
        }
        
        return (severity, action)
    }
    
    nonisolated private func generateVisualDescription(for label: String) -> String {
        let normalizedLabel = label.lowercased()
        
        // Deficiencias nutricionales
        if normalizedLabel.contains("nitrogen") {
            return "Las hojas muestran clorosis general (amarillamiento), especialmente en hojas más viejas. Crecimiento débil y raquítico."
        }
        if normalizedLabel.contains("phosphorus") {
            return "Las hojas presentan tonalidad verde oscuro con posible tinte púrpura o bronceado. Crecimiento lento y raíces poco desarrolladas."
        }
        if normalizedLabel.contains("potassium") {
            return "Se observa necrosis (muerte de tejido) en los bordes de las hojas, con posible enrollamiento. Frutos pequeños."
        }
        if normalizedLabel.contains("calcium") {
            return "Hojas jóvenes deformadas con bordes necróticos. Puntas de brotes marchitas. Posible muerte apical."
        }
        if normalizedLabel.contains("magnesium") {
            return "Clorosis intervenal en hojas viejas (amarillamiento entre nervaduras). Las nervaduras permanecen verdes."
        }
        if normalizedLabel.contains("iron") {
            return "Clorosis intervenal severa en hojas jóvenes. Hojas completamente amarillas o blancas en casos graves."
        }
        if normalizedLabel.contains("manganese") {
            return "Clorosis intervenal en hojas jóvenes. Puntos necróticos entre las nervaduras."
        }
        if normalizedLabel.contains("boron") {
            return "Hojas deformadas y quebradizas. Muerte de puntos de crecimiento. Frutos deformes."
        }
        if normalizedLabel.contains("more-deficiencies") || normalizedLabel.contains("deficiencies") {
            return "Se observan múltiples síntomas combinados: clorosis, necrosis, deformaciones. Requiere análisis detallado."
        }
        
        // Enfermedades
        if normalizedLabel.contains("leaf rust") || normalizedLabel.contains("rust") {
            return "Se observan manchas anaranjadas-amarillentas circulares en el envés de las hojas, características de la roya del café (Hemileia vastatrix)."
        }
        if normalizedLabel.contains("phoma") {
            return "Manchas necróticas irregulares con bordes oscuros. Puede afectar hojas, ramas y frutos. Tejido muerto de color marrón."
        }
        if normalizedLabel.contains("cercospora") {
            return "Manchas circulares con centro claro y borde oscuro, similares a un 'ojo'. Pueden tener anillos concéntricos."
        }
        
        // Plagas
        if normalizedLabel.contains("miner") {
            return "Galerías o túneles sinuosos de color blanco-plateado en las hojas. Daño visible en el tejido foliar."
        }
        if normalizedLabel.contains("spider") || normalizedLabel.contains("mite") {
            return "Hojas con puntos amarillentos o bronceados. Posible presencia de finas telarañas. Hojas secas y caída prematura."
        }
        
        // Planta sana
        if normalizedLabel.contains("healthy") {
            return "La planta presenta hojas verdes vigorosas, sin manchas ni decoloración. Aspecto saludable y crecimiento normal."
        }
        
        // Caso por defecto
        return "Se detectan síntomas que requieren análisis más detallado para diagnóstico preciso."
    }
}

/// Servicio singleton para clasificación de enfermedades de café
final class CoffeeDiseaseClassifierService {
    static let shared = CoffeeDiseaseClassifierService()
    
    // ML Model
    private var mlModel: VNCoreMLModel?
    private var isModelAvailable: Bool = false
    
    // Configuración
    private let modelRetryCount = 2
    private var loadAttempts = 0
    
    private init() {
        loadMLModel()
    }
    
    // MARK: - ML Model Management
    
    /// Carga el modelo CoreML
    private func loadMLModel() {
        do {
            print("🤖 Cargando modelo CoreML: coffeeProblems 1")
            
            // Configuración optimizada
            let configuration = MLModelConfiguration()
            configuration.computeUnits = .all // CPU + GPU + Neural Engine
            
            // Cargar el modelo compilado
            guard let modelURL = Bundle.main.url(forResource: "coffeeProblems 1", withExtension: "mlmodelc") else {
                print("❌ No se encontró el modelo en el bundle")
                throw MLModelError.modelNotAvailable
            }
            
            let compiledModel = try MLModel(contentsOf: modelURL, configuration: configuration)
            let visionModel = try VNCoreMLModel(for: compiledModel)
            
            self.mlModel = visionModel
            self.isModelAvailable = true
            
            print("✅ Modelo CoreML cargado exitosamente")
            
        } catch {
            print("❌ Error cargando ML Model: \(error)")
            self.isModelAvailable = false
            
            // Retry automático
            if loadAttempts < modelRetryCount {
                loadAttempts += 1
                print("🔄 Reintentando cargar modelo... (\(loadAttempts)/\(modelRetryCount))")
                
                DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) { [weak self] in
                    self?.loadMLModel()
                }
            }
        }
    }
    
    /// Verifica si el modelo está disponible y lo recarga si es necesario
    func ensureModelAvailable() throws {
        if !isModelAvailable || mlModel == nil {
            print("⚠️ Modelo no disponible - intentando recargar...")
            loadMLModel()
            
            // Esperar un momento para que cargue
            Thread.sleep(forTimeInterval: 0.5)
            
            guard isModelAvailable, mlModel != nil else {
                throw MLModelError.modelNotAvailable
            }
        }
    }
    
    // MARK: - Classification
    
    /// Clasifica una imagen usando el modelo CoreML
    func classify(image: UIImage) async throws -> ClassificationResult {
        // 1. Verificar que el modelo esté disponible
        try ensureModelAvailable()
        
        guard let model = mlModel else {
            throw MLModelError.modelNotAvailable
        }
        
        // 2. Convertir UIImage a CIImage
        guard let ciImage = CIImage(image: image) else {
            throw MLModelError.predictionFailed(NSError(
                domain: "CoffeeDiseaseClassifier",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "No se pudo convertir la imagen"]
            ))
        }
        
        // 3. Crear y configurar la request
        let request = VNCoreMLRequest(model: model)
        request.imageCropAndScaleOption = .scaleFill
        
        // 4. Ejecutar la clasificación
        let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        
        do {
            try handler.perform([request])
        } catch {
            throw MLModelError.predictionFailed(error)
        }
        
        // 5. Procesar resultados
        guard let results = request.results as? [VNClassificationObservation],
              !results.isEmpty else {
            throw MLModelError.noResults
        }
        
        // 6. Obtener el resultado principal (mayor confianza)
        let topResult = results[0]
        
        // 7. Mapear todas las predicciones
        let allPredictions = results.prefix(5).map { (
            label: mapRawLabelToSpanish($0.identifier),
            confidence: Double($0.confidence)
        )}
        
        print("🎯 Clasificación completada:")
        print("   - Top: \(topResult.identifier) (\(String(format: "%.2f%%", topResult.confidence * 100)))")
        
        return ClassificationResult(
            label: mapRawLabelToSpanish(topResult.identifier),
            confidence: Double(topResult.confidence),
            allPredictions: allPredictions
        )
    }
    
    // MARK: - Label Mapping
    
    /// Mapea las labels del modelo (inglés) a español legible
    private func mapRawLabelToSpanish(_ rawLabel: String) -> String {
        let normalized = rawLabel.lowercased()
        
        // Deficiencias nutricionales
        if normalized.contains("nitrogen") || normalized.contains("n") { return "Deficiencia de Nitrógeno (N)" }
        if normalized.contains("phosphorus") || normalized.contains("p") { return "Deficiencia de Fósforo (P)" }
        if normalized.contains("potassium") || normalized.contains("k") { return "Deficiencia de Potasio (K)" }
        if normalized.contains("calcium") || normalized.contains("ca") { return "Deficiencia de Calcio (Ca)" }
        if normalized.contains("magnesium") || normalized.contains("mg") { return "Deficiencia de Magnesio (Mg)" }
        if normalized.contains("iron") || normalized.contains("fe") { return "Deficiencia de Hierro (Fe)" }
        if normalized.contains("manganese") || normalized.contains("mn") { return "Deficiencia de Manganeso (Mn)" }
        if normalized.contains("boron") || normalized.contains("b") { return "Deficiencia de Boro (B)" }
        if normalized.contains("more") || normalized.contains("deficiencies") { return "Múltiples Deficiencias" }
        
        // Enfermedades
        if normalized.contains("leaf rust") || normalized.contains("rust") { return "Roya del Café" }
        if normalized.contains("phoma") { return "Mancha de Phoma" }
        if normalized.contains("cercospora") { return "Ojo de Gallo (Cercospora)" }
        
        // Plagas
        if normalized.contains("miner") { return "Minador de la Hoja" }
        if normalized.contains("spider") || normalized.contains("mite") { return "Araña Roja" }
        
        // Planta sana
        if normalized.contains("healthy") { return "Planta Saludable" }
        
        // Fallback
        return rawLabel
    }
}
