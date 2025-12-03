//
//  TasksViewModel.swift
//  KaapehCopiloto2
//
//  ViewModel para la gestión de tareas
//

import Foundation
import SwiftData
import Observation

// MARK: - Task Group Model

struct TaskGroup: Identifiable {
    let id: UUID
    let diagnosis: DiagnosisRecord
    var allTasks: [ActionItem]
    
    var pendingTasks: [ActionItem] {
        allTasks.filter { !$0.isCompleted }
    }
    
    var completedTasks: [ActionItem] {
        allTasks.filter { $0.isCompleted }
    }
    
    // Tareas vencidas
    var overdueTasks: [ActionItem] {
        allTasks.filter { $0.isOverdue }
    }
    
    // Tareas que vencen pronto
    var dueSoonTasks: [ActionItem] {
        allTasks.filter { $0.isDueSoon }
    }
    
    init(diagnosis: DiagnosisRecord) {
        self.id = diagnosis.recordId
        self.diagnosis = diagnosis
        self.allTasks = diagnosis.actionPlanItems ?? []
    }
}

// MARK: - Task Filter Options

enum TaskFilter: String, CaseIterable {
    case all = "Todas"
    case pending = "Pendientes"
    case completed = "Completadas"
    case overdue = "Vencidas"
    case dueSoon = "Próximas a vencer"
    case highPriority = "Alta Prioridad"
}

// MARK: - Task Sort Options

enum TaskSort: String, CaseIterable {
    case dueDate = "Fecha de vencimiento"
    case priority = "Prioridad"
    case createdDate = "Fecha de creación"
    case alphabetical = "Alfabético"
}

// MARK: - Tasks ViewModel

@MainActor
@Observable
final class TasksViewModel {
    // MARK: - Properties
    
    private let user: UserProfile
    private let swiftDataService: SwiftDataService
    
    var groupedTasks: [TaskGroup] = []
    var isLoading: Bool = false
    var errorMessage: String?
    
    // Confetti trigger
    var showConfetti: Bool = false
    
    // Filtros y búsqueda
    var searchText: String = ""
    var selectedFilter: TaskFilter = .all
    var selectedSort: TaskSort = .dueDate
    var showCompletedTasks: Bool = true
    
    var hiddenCompletedTaskIds: Set<UUID> = []
    
    // Estadísticas calculadas
    var pendingCount: Int {
        filteredTasks.filter { !$0.isCompleted }.count
    }
    
    var completedCount: Int {
        filteredTasks.filter { $0.isCompleted }.count
    }
    
    var totalCount: Int {
        filteredTasks.count
    }
    
    // Estadísticas adicionales
    var overdueCount: Int {
        filteredTasks.filter { $0.isOverdue }.count
    }
    
    var dueSoonCount: Int {
        filteredTasks.filter { $0.isDueSoon }.count
    }
    
    var highPriorityCount: Int {
        filteredTasks.filter { $0.taskPriority == .high || $0.taskPriority == .urgent }.count
    }
    
    // Tareas filtradas y ordenadas
    var filteredTasks: [ActionItem] {
        let allTasks = groupedTasks.flatMap { $0.allTasks }
        
        // Aplicar búsqueda
        var tasks = allTasks
        if !searchText.isEmpty {
            tasks = tasks.filter {
                $0.descriptionText.localizedCaseInsensitiveContains(searchText) ||
                $0.category?.localizedCaseInsensitiveContains(searchText) ?? false
            }
        }
        
        // Aplicar filtro
        switch selectedFilter {
        case .all:
            break
        case .pending:
            tasks = tasks.filter { !$0.isCompleted }
        case .completed:
            tasks = tasks.filter { $0.isCompleted }
        case .overdue:
            tasks = tasks.filter { $0.isOverdue }
        case .dueSoon:
            tasks = tasks.filter { $0.isDueSoon }
        case .highPriority:
            tasks = tasks.filter { $0.taskPriority == .high || $0.taskPriority == .urgent }
        }
        
        // Aplicar ordenamiento
        switch selectedSort {
        case .dueDate:
            tasks = tasks.sorted { (t1, t2) -> Bool in
                guard let d1 = t1.dueDate else { return false }
                guard let d2 = t2.dueDate else { return true }
                return d1 < d2
            }
        case .priority:
            tasks = tasks.sorted { $0.taskPriority.sortOrder < $1.taskPriority.sortOrder }
        case .createdDate:
            tasks = tasks.sorted { $0.createdAt > $1.createdAt }
        case .alphabetical:
            tasks = tasks.sorted { $0.descriptionText < $1.descriptionText }
        }
        
        return tasks
    }
    
    // MARK: - Initialization
    
    init(user: UserProfile) {
        self.user = user
        self.swiftDataService = SwiftDataService.shared
    }
    
    // Para testing con inyección de dependencias
    init(user: UserProfile, swiftDataService: SwiftDataService) {
        self.user = user
        self.swiftDataService = swiftDataService
    }
    
    // MARK: - Public Methods
    
    /// Carga todas las tareas del usuario
    func loadTasks() {
        isLoading = true
        errorMessage = nil
        
        Task { @MainActor in
            do {
                // Obtener diagnósticos del usuario que tengan tareas
                let allDiagnoses = try swiftDataService.fetchDiagnosisHistory(
                    for: user,
                    limit: 100
                )
                
                // Filtrar solo diagnósticos con tareas
                let diagnosesWithTasks = allDiagnoses.filter { diagnosis in
                    guard let tasks = diagnosis.actionPlanItems else { return false }
                    return !tasks.isEmpty
                }
                
                // Agrupar por diagnóstico
                self.groupedTasks = diagnosesWithTasks.map { TaskGroup(diagnosis: $0) }
                
                // Ordenar: primero los que tienen tareas pendientes
                self.groupedTasks = self.groupedTasks.sorted { (group1: TaskGroup, group2: TaskGroup) -> Bool in
                    let pending1 = group1.pendingTasks.count
                    let pending2 = group2.pendingTasks.count
                    
                    if pending1 == pending2 {
                        return group1.diagnosis.timestamp > group2.diagnosis.timestamp
                    }
                    return pending1 > pending2
                }
                
                print("📋 Tareas cargadas: \(self.totalCount) total (\(self.pendingCount) pendientes)")
                
                // Verificar tareas vencidas
                await checkOverdueTasks()
                
            } catch {
                self.errorMessage = "Error al cargar tareas: \(error.localizedDescription)"
                print("❌ Error cargando tareas: \(error)")
            }
            
            self.isLoading = false
        }
    }
    
    /// Marca o desmarca una tarea como completada
    func toggleTask(_ task: ActionItem) {
        // Verificar si este era el último pending del diagnóstico antes de cambiar
        let wasLastPending = checkIfLastPendingTask(task)
        
        task.toggleCompletion()
        
        // Guardar cambios en SwiftData
        guard let context = swiftDataService.modelContext else {
            print("❌ Error: ModelContext no disponible")
            errorMessage = "Error: Context no disponible"
            return
        }
        
        do {
            try context.save()
            print("✅ Tarea actualizada: \(task.descriptionText)")
            
            // Mostrar confetti si era la última tarea pendiente
            if wasLastPending && task.isCompleted {
                triggerConfetti()
            }
            
            // Recargar para actualizar contadores
            loadTasks()
        } catch {
            print("❌ Error guardando tarea: \(error)")
            errorMessage = "Error al actualizar la tarea"
        }
        
        Task { @MainActor in
            if task.isCompleted {
                NotificationManager.shared.cancelTaskReminder(taskId: task.taskId)
            } else if let reminderDate = task.reminderDate, reminderDate > Date() {
                try? await scheduleNotificationForTask(task)
            }
        }
    }
    
    /// Marca una tarea como completada
    func completeTask(_ task: ActionItem) {
        if !task.isCompleted {
            toggleTask(task)
        }
    }
    
    /// Marca todas las tareas de un diagnóstico como completadas
    func completeAllTasksForDiagnosis(_ diagnosis: DiagnosisRecord) {
        Task { @MainActor in
            guard let tasks = diagnosis.actionPlanItems else { return }
            guard let context = swiftDataService.modelContext else { return }
            
            for task in tasks where !task.isCompleted {
                task.complete()
            }
            
            do {
                try context.save()
                loadTasks()
            } catch {
                errorMessage = "Error al completar tareas"
            }
        }
    }
    
    /// Elimina todas las tareas completadas
    func deleteCompletedTasks() {
        Task { @MainActor in
            guard let context = swiftDataService.modelContext else {
                errorMessage = "Error: Context no disponible"
                return
            }
            
            do {
                for group in groupedTasks {
                    for task in group.completedTasks {
                        context.delete(task)
                    }
                }
                
                try context.save()
                loadTasks()
                
            } catch {
                errorMessage = "Error al eliminar tareas"
            }
        }
    }
    
    // Actualizar prioridad de tarea
    func updatePriority(task: ActionItem, priority: TaskPriority) {
        task.updatePriority(priority)
        saveContext()
    }
    
    // Actualizar fecha de vencimiento
    func updateDueDate(task: ActionItem, date: Date?) {
        task.updateDueDate(date)
        saveContext()
        
        // Programar notificación si hay fecha
        if date != nil, let reminderDate = task.reminderDate {
            Task {
                try? await NotificationService.shared.scheduleTaskReminder(
                    for: task,
                    at: reminderDate,
                    diagnosisTitle: "Tarea de Káapeh"
                )
            }
        }
    }
    
    // Programar recordatorio
    func scheduleReminder(task: ActionItem, reminderDate: Date) {
        task.reminderDate = reminderDate
        saveContext()
        
        Task {
            do {
                try await NotificationService.shared.scheduleTaskReminder(
                    for: task,
                    at: reminderDate,
                    diagnosisTitle: findDiagnosisTitleForTask(task)
                )
            } catch {
                errorMessage = "Error al programar recordatorio"
            }
        }
    }
    
    // Verificar tareas vencidas
    func checkOverdueTasks() async {
        // Create a local copy of overdue tasks with their titles to avoid actor isolation issues
        let overdueTasksWithTitles: [(task: ActionItem, title: String)] = groupedTasks.flatMap { group in
            group.overdueTasks.map { task in
                (task: task, title: group.diagnosis.detectedIssue)
            }
        }
        
        if !overdueTasksWithTitles.isEmpty {
            print("⚠️ \(overdueTasksWithTitles.count) tareas vencidas detectadas")
            
            // Notificar sobre tareas vencidas
            for item in overdueTasksWithTitles.prefix(3) { // Max 3 notificaciones
                try? await NotificationService.shared.scheduleOverdueNotification(
                    for: item.task,
                    diagnosisTitle: item.title
                )
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func saveContext() {
        guard let context = swiftDataService.modelContext else {
            errorMessage = "Error: Context no disponible"
            return
        }
        
        do {
            try context.save()
        } catch {
            errorMessage = "Error al guardar cambios"
            print("❌ Error: \(error)")
        }
    }
    
    private func findDiagnosisTitleForTask(_ task: ActionItem) -> String {
        for group in groupedTasks {
            if group.allTasks.contains(where: { $0.taskId == task.taskId }) {
                // Access the property directly without nonisolated access
                let title = group.diagnosis.detectedIssue
                return title
            }
        }
        return "Tarea de Káapeh"
    }
    
    /// Programa una notificación para una tarea
    private func scheduleNotificationForTask(_ task: ActionItem) async throws {
        guard let reminderDate = task.reminderDate, reminderDate > Date() else {
            return
        }
        
        // Corregido: usar TaskPriority.urgent en lugar de String.urgent
        let title = task.taskPriority == .urgent ? "🔴 Tarea Urgente" : "📋 Recordatorio de Tarea"
        let body = task.descriptionText
        
        // Corregido: pasar task.taskPriority (que ya es TaskPriority) en lugar de task.priority (String)
        try await NotificationManager.shared.scheduleTaskReminder(
            taskId: task.taskId,
            title: title,
            body: body,
            date: reminderDate,
            priority: task.taskPriority  // Usar taskPriority en lugar de priority
        )
    }

    /// Programa notificaciones para todas las tareas pendientes
    private func scheduleNotificationsForPendingTasks() async {
        for group in groupedTasks {
            for task in group.pendingTasks {
                try? await scheduleNotificationForTask(task)
            }
        }
    }
    
    // MARK: - Confetti Helpers
    
    /// Verifica si esta tarea es la última pendiente de su diagnóstico
    private func checkIfLastPendingTask(_ task: ActionItem) -> Bool {
        // Buscar el diagnóstico de esta tarea
        guard let diagnosis = findDiagnosisForTask(task) else { return false }
        guard let tasks = diagnosis.actionPlanItems else { return false }
        
        // Contar cuántas están pendientes (sin contar la actual si ya está marcada)
        let pendingCount = tasks.filter { $0.taskId != task.taskId && !$0.isCompleted }.count
        
        // Es la última si no hay otras pendientes y la actual no está completada
        return pendingCount == 0 && !task.isCompleted
    }
    
    /// Busca el diagnóstico al que pertenece una tarea
    private func findDiagnosisForTask(_ task: ActionItem) -> DiagnosisRecord? {
        for group in groupedTasks {
            if group.allTasks.contains(where: { $0.taskId == task.taskId }) {
                return group.diagnosis
            }
        }
        return nil
    }
    
    /// Trigger confetti animation
    private func triggerConfetti() {
        showConfetti = true
        
        // Auto-hide después de 3 segundos
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(3))
            showConfetti = false
        }
    }
    
    func hideCompletedTask(_ task: ActionItem) {
        guard task.isCompleted else { return }
        hiddenCompletedTaskIds.insert(task.taskId)
        print("👁️ Tarea ocultada (permanece en DB): \(task.descriptionText)")
    }
    
    func showAllHiddenTasks() {
        hiddenCompletedTaskIds.removeAll()
    }
    
    // MARK: - Tareas filtradas y ordenadas (actualizado para ocultar las eliminadas visualmente)
    var visibleFilteredTasks: [ActionItem] {
        let visible = filteredTasks.filter { !hiddenCompletedTaskIds.contains($0.taskId) }
        print("🔍 DEBUG visibleFilteredTasks:")
        print("   - Total filteredTasks: \(filteredTasks.count)")
        print("   - Hidden IDs: \(hiddenCompletedTaskIds.count)")
        print("   - Visible después del filtro: \(visible.count)")
        print("   - Filtro actual: \(selectedFilter)")
        print("   - Texto búsqueda: '\(searchText)'")
        return visible
    }
}
