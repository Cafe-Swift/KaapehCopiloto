//
//  NotificationManager.swift
//  KaapehCopiloto2
//
//  Created by Copilot on 23/11/25.
//

import Foundation
import UserNotifications
import SwiftUI
import Combine

/// Gestiona notificaciones locales para recordatorios de tareas
@MainActor
final class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    
    private let center = UNUserNotificationCenter.current()
    
    private init() {
        Task {
            await checkAuthorizationStatus()
        }
    }
    
    // MARK: - Authorization
    
    /// Solicita permisos de notificaciones al usuario
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            await checkAuthorizationStatus()
            
            print(granted ? "✅ Permisos de notificaciones concedidos" : "❌ Permisos de notificaciones denegados")
            
            return granted
        } catch {
            print("❌ Error solicitando permisos de notificaciones: \(error)")
            return false
        }
    }
    
    /// Verifica el estado actual de autorización
    func checkAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        authorizationStatus = settings.authorizationStatus
        
        print("📱 Estado de notificaciones: \(authorizationStatus.rawValue)")
    }
    
    // MARK: - Schedule Notifications
    
    /// Programa una notificación para una tarea
    func scheduleTaskReminder(
        taskId: UUID,
        title: String,
        body: String,
        date: Date,
        priority: TaskPriority
    ) async throws {
        // Verificar permisos
        guard authorizationStatus == .authorized else {
            print("⚠️ No hay permisos para programar notificaciones")
            return
        }
        
        // Verificar que la fecha sea futura
        guard date > Date() else {
            print("⚠️ No se puede programar notificación en el pasado")
            return
        }
        
        // Crear contenido
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "TASK_REMINDER"
        content.userInfo = [
            "taskId": taskId.uuidString,
            "priority": priority.rawValue
        ]
        
        // Configurar trigger
        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: date
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        // Crear request
        let identifier = "task-\(taskId.uuidString)"
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        // Programar
        try await center.add(request)
        
        print("📅 Notificación programada para: \(date.formatted(date: .abbreviated, time: .shortened))")
        print("   Tarea: \(title)")
    }
    
    /// Cancela la notificación de una tarea
    func cancelTaskReminder(taskId: UUID) {
        let identifier = "task-\(taskId.uuidString)"
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        
        print("🗑️ Notificación cancelada para tarea: \(taskId)")
    }
    
    /// Cancela todas las notificaciones pendientes
    func cancelAllReminders() {
        center.removeAllPendingNotificationRequests()
        print("🗑️ Todas las notificaciones canceladas")
    }
    
    /// Obtiene el conteo de notificaciones pendientes
    func getPendingNotificationsCount() async -> Int {
        let pending = await center.pendingNotificationRequests()
        return pending.count
    }
    
    // MARK: - Badge Management
    
    /// Actualiza el badge de la app
    func updateBadgeCount(_ count: Int) {
        Task { @MainActor in
            try? await center.setBadgeCount(count)
        }
    }
    
    /// Limpia el badge
    func clearBadge() {
        updateBadgeCount(0)
    }
}

// MARK: - Authorization Status Extension

extension UNAuthorizationStatus {
    var description: String {
        switch self {
        case .notDetermined: return "No determinado"
        case .denied: return "Denegado"
        case .authorized: return "Autorizado"
        case .provisional: return "Provisional"
        case .ephemeral: return "Efímero"
        @unknown default: return "Desconocido"
        }
    }
}
