//
//  KaapehAppShortcuts.swift
//  KaapehCopiloto2
//
//  Define los shortcuts de app disponibles para Siri, Spotlight y Shortcuts app
//  Enseña a Siri qué frases escuchar
//
//  Basado en: Doc 4 (Voice Interface) - Section 5.3: Teaching Siri
//

import AppIntents

/// Proveedor de shortcuts para la app Káapeh Copiloto
struct KaapehAppShortcuts: AppShortcutsProvider {
    // MARK: - App Shortcuts
    
    static var appShortcuts: [AppShortcut] {
        // ✅ Shortcut 1: Diagnosticar Planta
        AppShortcut(
            intent: DiagnosePlantIntent(),
            phrases: [
                "Diagnosticar planta en \(.applicationName)",
                "Analizar mi café en \(.applicationName)",
                "Revisar salud de planta en \(.applicationName)",
                "Detectar enfermedad en \(.applicationName)",
                "Usar \(.applicationName) para diagnosticar"
            ],
            shortTitle: "Diagnosticar Planta",
            systemImageName: "leaf.circle"
        )
        
        // ✅ Shortcut 2: Iniciar Voice Chat
        AppShortcut(
            intent: StartVoiceChatIntent(),
            phrases: [
                "Pregunta al copiloto de \(.applicationName)",
                "Habla con \(.applicationName)",
                "Abre chat de voz en \(.applicationName)",
                "Consulta con \(.applicationName)",
                "Necesito ayuda con café en \(.applicationName)"
            ],
            shortTitle: "Chat de Voz",
            systemImageName: "mic.circle"
        )
        
        // ✅ Shortcut 3: Análisis Rápido (sin parámetros)
        AppShortcut(
            intent: DiagnosePlantIntent(),
            phrases: [
                "Escanear planta en \(.applicationName)",
                "Foto de planta en \(.applicationName)",
                "Análisis rápido en \(.applicationName)"
            ],
            shortTitle: "Análisis Rápido",
            systemImageName: "camera.circle"
        )
    }
    
    // MARK: - Shortcut Tiles
    
    /// Shortcuts que aparecen en Spotlight y Shortcuts app
    static var shortcutTileColor: ShortcutTileColor = .orange
}

// MARK: - Extensions para mejor integración

extension DiagnosePlantIntent {
    /// Metadata para sugerencias proactivas
    static var suggestedInvocationPhrase: String {
        "Diagnosticar mi planta de café"
    }
}

extension StartVoiceChatIntent {
    /// Metadata para sugerencias proactivas
    static var suggestedInvocationPhrase: String {
        "Pregunta al copiloto de café"
    }
}
