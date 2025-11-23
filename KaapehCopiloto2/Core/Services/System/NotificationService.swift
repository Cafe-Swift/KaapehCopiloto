//
//  NotificationService.swift
//  KaapehCopiloto2
//
//  Sistema de notificaciones locales para recordatorios de tareas
//

import Foundation
import UserNotifications
import Combine

@MainActor
final class NotificationService: ObservableObject {
    
    static let shared = NotificationService()
    
    @Published var isAuthorized: Bool = false
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    
    private let notificationCenter = UNUserNotificationCenter.current()
    
    private init() {
        Task {
            await checkAuthorizationStatus()
        }
    }
    
    // MARK: - Authorization
    
    /// Solicita permisos de notificaciones al usuario
    func requestAuthorization() async throws {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        
        do {
            let granted = try await notificationCenter.requestAuthorization(options: options)
            isAuthorized = granted
            
            if granted {
                print("✅ Permisos de notificaciones otorgados")
            } else {
                print("⚠️ Permisos de notificaciones denegados")
            }
            
            await checkAuthorizationStatus()
        } catch {
            print("❌ Error solicitando permisos: \(error)")
            throw error
        }
    }
    
    /// Verifica el estado de autorización actual
    func checkAuthorizationStatus() async {
        let settings = await notificationCenter.notificationSettings()
        authorizationStatus = settings.authorizationStatus
        isAuthorized = settings.authorizationStatus == .authorized
    }
    
    // MARK: - Task Notifications
    
    /// Programa una notificación para una tarea
    func scheduleTaskReminder(
        for task: ActionItem,
        at date: Date,
        diagnosisTitle: String = "Diagnóstico"
    ) async throws {
        guard isAuthorized else {
            print("⚠️ No hay permisos para notificaciones")
            try await requestAuthorization()
            return
        }
        
        // Cancelar notificación anterior si existe
        await cancelTaskReminder(taskId: task.taskId.uuidString)
        
        // Crear contenido de notificación
        let content = UNMutableNotificationContent()
        content.title = "⏰ Recordatorio de Tarea"
        content.body = task.descriptionText
        content.subtitle = diagnosisTitle
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "TASK_REMINDER"
        
        // Agregar datos personalizados
        content.userInfo = [
            "taskId": task.taskId.uuidString,
            "diagnosisTitle": diagnosisTitle,
            "priority": task.priority
        ]
        
        // Crear trigger basado en fecha
        let triggerDate = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: date
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        // Crear y agregar la solicitud
        let identifier = "task_\(task.taskId.uuidString)"
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        try await notificationCenter.add(request)
        print("✅ Notificación programada para: \(date)")
    }
    
    /// Cancela una notificación de tarea
    func cancelTaskReminder(taskId: String) async {
        let identifier = "task_\(taskId)"
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
        print("🗑️ Notificación cancelada: \(identifier)")
    }
    
    /// Programa notificación para tarea vencida
    func scheduleOverdueNotification(for task: ActionItem, diagnosisTitle: String) async throws {
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "⚠️ Tarea Vencida"
        content.body = task.descriptionText
        content.subtitle = diagnosisTitle
        content.sound = .defaultCritical
        content.badge = 1
        
        // Notificación inmediata (1 segundo)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let identifier = "overdue_\(task.taskId.uuidString)_\(Date().timeIntervalSince1970)"
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        try await notificationCenter.add(request)
    }
    
    // MARK: - Batch Operations
    
    /// Programa recordatorios para múltiples tareas
    func scheduleMultipleReminders(
        tasks: [(task: ActionItem, date: Date, diagnosis: String)]
    ) async throws {
        for item in tasks {
            try await scheduleTaskReminder(
                for: item.task,
                at: item.date,
                diagnosisTitle: item.diagnosis
            )
        }
    }
    
    /// Cancela todas las notificaciones pendientes
    func cancelAllNotifications() async {
        notificationCenter.removeAllPendingNotificationRequests()
        print("🗑️ Todas las notificaciones canceladas")
    }
    
    /// Obtiene todas las notificaciones pendientes
    func getPendingNotifications() async -> [UNNotificationRequest] {
        return await notificationCenter.pendingNotificationRequests()
    }
    
    // MARK: - Badge Management
    
    /// Actualiza el badge de la app
    func updateBadge(count: Int) async {
        try? await notificationCenter.setBadgeCount(count)
    }
    
    /// Limpia el badge
    func clearBadge() async {
        try? await notificationCenter.setBadgeCount(0)
    }
}
