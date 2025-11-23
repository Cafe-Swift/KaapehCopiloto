//
//  DiagnosisViewModel.swift
//  KaapehCopiloto2
//
//  Created by Cafe Swift Team on 05/11/25.
//

import Foundation
import SwiftUI
import SwiftData
import AVFoundation
import Combine

@MainActor
@Observable
final class DiagnosisViewModel {
    var user: UserProfile
    var selectedImage: UIImage?
    var isProcessing: Bool = false
    var currentDiagnosis: DiagnosisRecord?
    var errorMessage: String?
    
    private let dataService = SwiftDataService.shared
    
    init(user: UserProfile) {
        self.user = user
    }
    
    // MARK: - Image Processing
    
    func processImage(_ image: UIImage) async {
        isProcessing = true
        errorMessage = nil
        selectedImage = image
        
        print("📸 Procesando imagen con modelo CoreML...")
        
        do {
            // USAR EL CLASIFICADOR REAL DE COREML
            let classificationResult = try await CoffeeDiseaseClassifierService.shared.classify(image: image)
            
            print("✅ Clasificación completada:")
            print("   - Problema detectado: \(classificationResult.label)")
            print("   - Confianza: \(String(format: "%.2f%%", classificationResult.confidence * 100))")
            
            // Guardar el diagnóstico en SwiftData
            let diagnosis = try dataService.createDiagnosisRecord(
                for: user,
                detectedIssue: classificationResult.label,
                confidence: classificationResult.confidence,
                imagePath: nil // TODO: Implementar guardado de imagen en Sprint 3
            )
            
            currentDiagnosis = diagnosis
            
            print("💾 Diagnóstico guardado exitosamente en SwiftData")
            
            // Generar tareas automáticas basadas en el problema detectado
            await generateActionItems(for: diagnosis, issue: classificationResult.label)
            
            print("✅ Tareas automáticas generadas")
            
        } catch {
            print("❌ Error en procesamiento de imagen: \(error)")
            errorMessage = "Error al procesar la imagen: \(error.localizedDescription)"
            
            // En caso de error, crear un diagnóstico genérico
            do {
                let fallbackDiagnosis = try dataService.createDiagnosisRecord(
                    for: user,
                    detectedIssue: "Error en clasificación",
                    confidence: 0.0,
                    imagePath: nil
                )
                currentDiagnosis = fallbackDiagnosis
            } catch {
                print("❌ Error al guardar diagnóstico fallback: \(error)")
            }
        }
        
        isProcessing = false
    }
    
    // MARK: - Feedback
    
    func submitFeedback(isCorrect: Bool, correctedIssue: String? = nil) async {
        guard let diagnosis = currentDiagnosis else { return }
        
        do {
            try dataService.updateDiagnosisFeedback(
                record: diagnosis,
                isCorrect: isCorrect,
                correctedIssue: correctedIssue
            )
        } catch {
            errorMessage = "Error al guardar feedback: \(error.localizedDescription)"
        }
    }
    
    func reset() {
        selectedImage = nil
        currentDiagnosis = nil
        errorMessage = nil
    }
    
    // MARK: - Action Items Generation
    
    /// Genera tareas automáticas basadas en el problema detectado usando RAG
    private func generateActionItems(for diagnosis: DiagnosisRecord, issue: String) async {
        print("🔍 Intentando generar tareas desde RAG para: \(issue)")
        
        // Intentar obtener tareas del RAG primero
        let ragTasks = await extractTasksFromRAG(for: issue)
        
        if !ragTasks.isEmpty {
            print("✅ \(ragTasks.count) tareas extraídas del RAG")
            await saveTasksToDiagnosis(diagnosis: diagnosis, tasks: ragTasks)
            return
        }
        
        print("⚠️ No se pudieron extraer tareas del RAG, usando tareas predeterminadas")
        
        // Fallback: usar diccionario de tareas predefinidas
        let actionItemsMap: [String: [String]] = [
            "Roya del Café": [
                "Aplicar fungicida a base de cobre",
                "Eliminar hojas infectadas",
                "Mejorar ventilación entre plantas",
                "Monitorear clima para prevenir humedad excesiva",
                "Revisar plantas cada 3 días"
            ],
            "Minador de la Hoja": [
                "Aplicar control biológico con parasitoides",
                "Eliminar hojas muy afectadas",
                "Mantener plantas bien nutridas",
                "Evitar exceso de nitrógeno",
                "Inspeccionar plantas semanalmente"
            ],
            "Broca del Café": [
                "Recolectar granos maduros frecuentemente",
                "Eliminar frutos caídos",
                "Aplicar hongos entomopatógenos",
                "Usar trampas con atrayentes",
                "Revisar cultivo cada 2 días"
            ],
            "Ojo de Gallo": [
                "Aplicar fungicida sistémico",
                "Mejorar drenaje del suelo",
                "Reducir humedad en el ambiente",
                "Eliminar ramas enfermas",
                "Monitorear condiciones climáticas"
            ],
            "Deficiencia de Nitrógeno": [
                "Aplicar fertilizante nitrogenado",
                "Realizar análisis de suelo",
                "Ajustar pH del suelo si es necesario",
                "Considerar abono orgánico",
                "Monitorear crecimiento cada semana"
            ],
            "Deficiencia de Potasio": [
                "Aplicar sulfato de potasio",
                "Realizar análisis foliar",
                "Mejorar fertilización general",
                "Aumentar materia orgánica",
                "Revisar desarrollo de frutos"
            ],
            "Deficiencia de Magnesio": [
                "Aplicar sulfato de magnesio",
                "Corregir pH del suelo",
                "Realizar fertilización foliar",
                "Balancear uso de potasio",
                "Monitorear hojas más viejas"
            ],
            "Planta Saludable": [
                "Mantener programa de fertilización",
                "Continuar monitoreo preventivo",
                "Registrar prácticas exitosas",
                "Revisar plantas semanalmente"
            ]
        ]
        
        // Tareas genéricas por defecto
        let defaultTasks = [
            "Monitorear la evolución del problema",
            "Registrar cambios observados",
            "Consultar con agrónomo si persiste",
            "Revisar plantas cercanas"
        ]
        
        // Obtener tareas específicas o usar genéricas
        let tasks = actionItemsMap[issue] ?? defaultTasks
        
        await saveTasksToDiagnosis(diagnosis: diagnosis, tasks: tasks)
    }
    
    /// Extrae tareas dinámicamente desde el RAG
    private func extractTasksFromRAG(for issue: String) async -> [String] {
        // Crear el servicio RAG
        let ragService = RAGService()
        
        // Verificar que el servicio esté listo
        guard ragService.isReady else {
            print("⚠️ RAGService no está listo")
            return []
        }
        
        do {
            // Consultar al RAG por tratamientos y medidas de prevención específicas
            let query = """
            Lista las acciones específicas de tratamiento y prevención para \(issue) en formato de lista. 
            Proporciona entre 5 y 8 acciones concretas y prácticas.
            """
            
            let response = try await ragService.answer(query: query)
            
            // Parsear el contenido para extraer las tareas
            let tasks = parseTasksFromResponse(response.content)
            
            // Limitar a máximo 8 tareas
            return Array(tasks.prefix(8))
            
        } catch {
            print("⚠️ Error extrayendo tareas del RAG: \(error)")
            return []
        }
    }
    
    /// Parsea el contenido de la respuesta para extraer tareas individuales
    private func parseTasksFromResponse(_ content: String) -> [String] {
        var tasks: [String] = []
        
        // Dividir por líneas
        let lines = content.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Buscar líneas que sean tareas (empiezan con números, bullets, o guiones)
            if trimmed.isEmpty { continue }
            
            // Patrones comunes de listas:
            // - "1. Tarea"
            // - "• Tarea"
            // - "- Tarea"
            // - "* Tarea"
            let taskPrefixes = ["•", "-", "*", "–", "→"]
            let isListItem = taskPrefixes.contains(where: { trimmed.hasPrefix($0) }) ||
                             trimmed.matches(of: /^\d+[\.)]\s+/).count > 0
            
            if isListItem {
                // Limpiar el prefijo
                var task = trimmed
                
                // Eliminar prefijos de lista
                for prefix in taskPrefixes {
                    if task.hasPrefix(prefix) {
                        task = String(task.dropFirst(prefix.count))
                        break
                    }
                }
                
                // Eliminar números al inicio (ej: "1. ", "2) ")
                task = task.replacingOccurrences(of: #"^\d+[\.)]\s+"#, with: "", options: .regularExpression)
                
                // Limpiar espacios
                task = task.trimmingCharacters(in: .whitespacesAndNewlines)
                
                // Solo agregar si tiene contenido sustancial (más de 10 caracteres)
                if task.count > 10 {
                    tasks.append(task)
                }
            }
        }
        
        return tasks
    }
    
    /// Guarda las tareas en el diagnóstico
    /// Guarda tareas con prioridad y fechas automáticas
    private func saveTasksToDiagnosis(diagnosis: DiagnosisRecord, tasks: [String]) async {
        // Limpiar tareas anteriores si existen
        if diagnosis.actionPlanItems == nil {
            diagnosis.actionPlanItems = []
        }
        
        // Determinar prioridad base según la severidad del problema
        let basePriority = determinePriority(for: diagnosis.detectedIssue)
        
        // Determinar categoría
        let category = determineCategory(for: diagnosis.detectedIssue)
        
        // Crear nuevos items con prioridad y fechas
        for (index, taskDescription) in tasks.enumerated() {
            // Asignar prioridad específica por tarea
            let taskPriority = determineTaskPriority(
                taskDescription: taskDescription,
                basePriority: basePriority,
                index: index
            )
            
            // Calcular fecha de vencimiento
            let dueDate = calculateDueDate(
                taskDescription: taskDescription,
                priority: taskPriority,
                index: index
            )
            
            // Calcular recordatorio (1 hora antes)
            let reminderDate = dueDate.map { Calendar.current.date(byAdding: .hour, value: -1, to: $0) ?? $0 }
            
            let actionItem = ActionItem(
                descriptionText: taskDescription,
                priority: taskPriority,
                dueDate: dueDate,
                reminderDate: reminderDate,
                category: category
            )
            
            diagnosis.actionPlanItems?.append(actionItem)
            
            print("   📌 Tarea: \(taskDescription)")
            print("      Prioridad: \(taskPriority.rawValue)")
            print("      Vence: \(dueDate?.formatted(date: .abbreviated, time: .shortened) ?? "Sin fecha")")
        }
        
        // Guardar cambios
        guard let context = dataService.modelContext else {
            print("❌ Error: ModelContext no disponible")
            return
        }
        
        do {
            try context.save()
            print("📋 \(tasks.count) tareas generadas con prioridad y fechas para: \(diagnosis.detectedIssue)")
        } catch {
            print("❌ Error guardando tareas: \(error)")
        }
    }
    
    /// Determina la prioridad base según el tipo de problema
    private func determinePriority(for issue: String) -> TaskPriority {
        let urgentIssues = ["Roya del Café", "Broca del Café", "Minador de la Hoja"]
        let highIssues = ["Ojo de Gallo", "Deficiencia de Nitrógeno"]
        
        if urgentIssues.contains(where: { issue.localizedCaseInsensitiveContains($0) }) {
            return .urgent
        } else if highIssues.contains(where: { issue.localizedCaseInsensitiveContains($0) }) {
            return .high
        } else if issue.localizedCaseInsensitiveContains("Deficiencia") {
            return .medium
        } else if issue.localizedCaseInsensitiveContains("Saludable") {
            return .low
        }
        
        return .medium
    }
    
    /// Determina la prioridad específica de una tarea
    private func determineTaskPriority(
        taskDescription: String,
        basePriority: TaskPriority,
        index: Int
    ) -> TaskPriority {
        let description = taskDescription.lowercased()
        
        // Palabras clave que indican urgencia
        let urgentKeywords = ["eliminar", "aplicar fungicida", "aplicar control", "inmediato"]
        let highKeywords = ["mejorar", "ajustar", "corregir", "prevenir"]
        let monitorKeywords = ["monitorear", "revisar", "inspeccionar", "registrar"]
        
        // Las primeras tareas suelen ser más urgentes
        if index == 0 {
            return basePriority
        }
        
        // Ajustar según palabras clave
        if urgentKeywords.contains(where: { description.contains($0) }) {
            return basePriority.sortOrder == 0 ? .urgent : .high
        } else if highKeywords.contains(where: { description.contains($0) }) {
            return basePriority == .urgent ? .high : basePriority
        } else if monitorKeywords.contains(where: { description.contains($0) }) {
            return basePriority == .urgent ? .high : .medium
        }
        
        return basePriority
    }
    
    /// Calcula la fecha de vencimiento según la prioridad
    private func calculateDueDate(
        taskDescription: String,
        priority: TaskPriority,
        index: Int
    ) -> Date? {
        let now = Date()
        let description = taskDescription.lowercased()
        
        // Tareas de monitoreo continuo no tienen fecha fija
        if description.contains("monitoreo") && description.contains("continuo") {
            return nil
        }
        
        // Calcular días según prioridad
        let daysToAdd: Int
        switch priority {
        case .urgent:
            daysToAdd = 1 // 1 día
        case .high:
            daysToAdd = 3 // 3 días
        case .medium:
            daysToAdd = 7 // 1 semana
        case .low:
            daysToAdd = 14 // 2 semanas
        }
        
        // Agregar delay adicional por posición (para espaciar tareas)
        let additionalDelay = index / 2 // Cada 2 tareas, agregar 1 día más
        
        return Calendar.current.date(
            byAdding: .day,
            value: daysToAdd + additionalDelay,
            to: now
        )
    }
    
    /// Determina la categoría de la tarea
    private func determineCategory(for issue: String) -> String {
        if issue.localizedCaseInsensitiveContains("Roya") ||
           issue.localizedCaseInsensitiveContains("Broca") ||
           issue.localizedCaseInsensitiveContains("Minador") ||
           issue.localizedCaseInsensitiveContains("Ojo de Gallo") {
            return "tratamiento"
        } else if issue.localizedCaseInsensitiveContains("Deficiencia") {
            return "nutrición"
        } else if issue.localizedCaseInsensitiveContains("Saludable") {
            return "prevención"
        }
        
        return "general"
    }
}
