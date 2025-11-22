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

/// Resultado de la clasificación de imagen
struct ClassificationResult {
    let label: String
    let confidence: Double
    let allPredictions: [(label: String, confidence: Double)]
    
    /// Convierte el resultado a VisualDiagnosisResult para RAG
    func toVisualDiagnosisResult() -> VisualDiagnosisResult {
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
    private func formatLabel(_ rawLabel: String) -> String {
        let normalized = rawLabel.lowercased()
        
        // Deficiencias nutricionales
        if normalized.contains("nitrogen") { return "Deficiencia de Nitrógeno (N)" }
        if normalized.contains("phosphorus") { return "Deficiencia de Fósforo (P)" }
        if normalized.contains("potassium") { return "Deficiencia de Potasio (K)" }
        if normalized.contains("calcium") { return "Deficiencia de Calcio (Ca)" }
        if normalized.contains("magnesium") { return "Deficiencia de Magnesio (Mg)" }
        if normalized.contains("iron") { return "Deficiencia de Hierro (Fe)" }
        if normalized.contains("manganese") { return "Deficiencia de Manganeso (Mn)" }
        if normalized.contains("boron") { return "Deficiencia de Boro (B)" }
        if normalized.contains("more-deficiencies") || normalized.contains("deficiencies") {
            return "Múltiples Deficiencias Nutricionales"
        }
        
        // Enfermedades
        if normalized.contains("leaf rust") || normalized.contains("rust") { return "Roya del Café" }
        if normalized.contains("phoma") { return "Mancha de Phoma" }
        if normalized.contains("cercospora") { return "Ojo de Gallo (Cercospora)" }
        
        // Plagas
        if normalized.contains("miner") { return "Minador de la Hoja" }
        if normalized.contains("spider") || normalized.contains("mite") { return "Araña Roja" }
        
        // Planta sana
        if normalized.contains("healthy") { return "Planta Saludable" }
        
        // Si no coincide, devolver el original
        return rawLabel
    }
    
    private func determineSeverityAndAction(for label: String, confidence: Double) -> (severity: String, action: String) {
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
    
    private func generateVisualDescription(for label: String) -> String {
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
@MainActor
final class CoffeeDiseaseClassifierService {
    static let shared = CoffeeDiseaseClassifierService()
    
    private var model: VNCoreMLModel?
    private var isModelLoaded = false
    
    private init() {
        Task {
            await loadModel()
        }
    }
    
    // MARK: - Model Loading
    
    /// Carga el modelo CoreML de forma asíncrona
    func loadModel() async {
        guard !isModelLoaded else { return }
        
        do {
            print("🔄 Cargando modelo CoreML 'coffeeProblems 1'...")
            print("   📋 Modelo entrenado con 15 clases:")
            print("   • Deficiencias: N, P, K, Ca, Mg, Fe, Mn, B, Múltiples")
            print("   • Enfermedades: Roya, Phoma, Cercospora")
            print("   • Plagas: Minador, Araña Roja")
            print("   • Estado: Planta Saludable")
            
            // Cargar el modelo usando la clase generada
            let mlModel = try await coffeeProblems_1.load()
            
            // Crear el modelo de Vision
            let visionModel = try VNCoreMLModel(for: mlModel.model)
            
            self.model = visionModel
            self.isModelLoaded = true
            
            print("✅ Modelo CoreML cargado exitosamente")
            
        } catch {
            print("❌ Error al cargar modelo CoreML: \(error)")
            print("   Detalle: \(error.localizedDescription)")
            self.isModelLoaded = false
        }
    }
    
    // MARK: - Classification
    
    /// Clasifica una imagen usando el modelo CoreML
    /// - Parameter image: UIImage a clasificar
    /// - Returns: ClassificationResult con la predicción
    func classify(image: UIImage) async throws -> ClassificationResult {
        // Asegurar que el modelo está cargado
        if !isModelLoaded {
            await loadModel()
        }
        
        guard let model = self.model else {
            throw ClassificationError.modelNotLoaded
        }
        
        guard let cgImage = image.cgImage else {
            throw ClassificationError.invalidImage
        }
        
        print("🔍 Clasificando imagen con modelo de 15 clases...")
        
        return try await withCheckedThrowingContinuation { continuation in
            // Crear el request de Vision
            let request = VNCoreMLRequest(model: model) { request, error in
                if let error = error {
                    print("❌ Error en clasificación: \(error)")
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let results = request.results as? [VNClassificationObservation] else {
                    print("❌ No se obtuvieron resultados de clasificación")
                    continuation.resume(throwing: ClassificationError.noResults)
                    return
                }
                
                guard let topResult = results.first else {
                    print("❌ Lista de resultados vacía")
                    continuation.resume(throwing: ClassificationError.noResults)
                    return
                }
                
                // Convertir todos los resultados
                let allPredictions = results.map { observation in
                    (label: observation.identifier, confidence: Double(observation.confidence))
                }
                
                let result = ClassificationResult(
                    label: topResult.identifier,
                    confidence: Double(topResult.confidence),
                    allPredictions: allPredictions
                )
                
                print("✅ Clasificación exitosa:")
                print("   🏷️  Clase detectada: \(result.label)")
                print("   📊 Confianza: \(String(format: "%.2f%%", result.confidence * 100))")
                print("   📋 Top 5 predicciones:")
                for (index, pred) in allPredictions.prefix(5).enumerated() {
                    print("      \(index + 1). \(pred.label) - \(String(format: "%.2f%%", pred.confidence * 100))")
                }
                
                continuation.resume(returning: result)
            }
            
            // Configurar el request para mejor rendimiento
            request.imageCropAndScaleOption = .centerCrop
            
            // Crear el handler y ejecutar
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                print("❌ Error al ejecutar request: \(error)")
                continuation.resume(throwing: error)
            }
        }
    }
    
    /// Clasifica una imagen y devuelve directamente un VisualDiagnosisResult
    /// - Parameter image: UIImage a clasificar
    /// - Returns: VisualDiagnosisResult para usar con RAG
    func classifyAndDiagnose(image: UIImage) async throws -> VisualDiagnosisResult {
        let result = try await classify(image: image)
        return result.toVisualDiagnosisResult()
    }
}

// MARK: - Errors

enum ClassificationError: LocalizedError {
    case modelNotLoaded
    case invalidImage
    case noResults
    case lowConfidence
    
    var errorDescription: String? {
        switch self {
        case .modelNotLoaded:
            return "El modelo de clasificación no está cargado"
        case .invalidImage:
            return "La imagen proporcionada no es válida"
        case .noResults:
            return "No se obtuvieron resultados de clasificación"
        case .lowConfidence:
            return "La confianza de clasificación es demasiado baja"
        }
    }
}
