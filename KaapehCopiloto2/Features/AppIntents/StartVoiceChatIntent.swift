//
//  StartVoiceChatIntent.swift
//  KaapehCopiloto2
//
//  App Intent para iniciar chat de voz desde Siri
//  "Hey Siri, pregunta al copiloto de Káapeh"
//
//  Basado en: Doc 4 (Voice Interface) - Part 5: App Intents
//

import AppIntents
import SwiftUI

/// Intent para iniciar chat de voz desde Siri
struct StartVoiceChatIntent: AppIntent {
    // MARK: - Metadata
    
    static var title: LocalizedStringResource = "Iniciar Chat de Voz"
    
    static var description = IntentDescription(
        """
        Inicia una conversación de voz con el copiloto de café. \
        Puedes hacer preguntas sobre cultivo, enfermedades, tratamientos y más.
        """
    )
    
    static var openAppWhenRun: Bool = true
    
    // MARK: - Parameters
    
    // Opcional: Pregunta inicial
    @Parameter(title: "Pregunta Inicial", description: "Tu primera pregunta al copiloto")
    var initialQuestion: String?
    
    // MARK: - Perform
    
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        // Notificar al sistema que se debe abrir el voice chat
        NotificationCenter.default.post(
            name: .startVoiceChatFromIntent,
            object: nil,
            userInfo: ["initialQuestion": initialQuestion ?? ""]
        )
        
        // Mensaje de confirmación
        let dialog: IntentDialog
        if let question = initialQuestion, !question.isEmpty {
            dialog = IntentDialog(
                "Abriendo Káapeh Copiloto. Te ayudaré con: \(question)"
            )
        } else {
            dialog = IntentDialog(
                "Abriendo Káapeh Copiloto. ¿En qué puedo ayudarte con tu café?"
            )
        }
        
        return .result(dialog: dialog)
    }
}

// MARK: - Notification Extension

extension Notification.Name {
    static let startVoiceChatFromIntent = Notification.Name("startVoiceChatFromIntent")
}
