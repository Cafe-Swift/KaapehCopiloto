//
//  VoiceChatState.swift
//  KaapehCopiloto2
//
//  State Machine para conversación por voz
//  Basado en: Doc 4 (Voice Interface)
//

import Foundation

/// Estados del sistema de conversación por voz
enum VoiceChatState: Equatable {
    case idle              // Voice mode está OFF
    case listening         // 🎤 Micrófono activo, transcribiendo
    case processingResponse // 🧠 Enviando a Foundation Models, generando respuesta
    case speaking          // 🔊 AVSpeechSynthesizer leyendo respuesta
    
    /// Descripción human-readable del estado
    var description: String {
        switch self {
        case .idle:
            return "Inactivo"
        case .listening:
            return "Escuchando..."
        case .processingResponse:
            return "Pensando..."
        case .speaking:
            return "Hablando..."
        }
    }
    
    /// Icono SF Symbol para cada estado
    var iconName: String {
        switch self {
        case .idle:
            return "mic.slash"
        case .listening:
            return "waveform.circle.fill"
        case .processingResponse:
            return "ellipsis.circle"
        case .speaking:
            return "speaker.wave.2.circle.fill"
        }
    }
    
    /// Color para el estado actual
    var colorName: String {
        switch self {
        case .idle:
            return "gray"
        case .listening:
            return "red"
        case .processingResponse:
            return "blue"
        case .speaking:
            return "green"
        }
    }
    
    /// Indica si el micrófono debe estar activo
    var isMicrophoneActive: Bool {
        self == .listening
    }
    
    /// Indica si el usuario puede interrumpir
    var canInterrupt: Bool {
        self == .speaking
    }
}

// MARK: - Metadata de Transcripción
/// Metadata de una transcripción de voz
struct TranscriptionMetadata {
    let text: String
    let language: String
    let confidence: Double
    let duration: TimeInterval
    let timestamp: Date
    
    init(text: String, language: String = "es-MX", confidence: Double = 1.0, duration: TimeInterval = 0) {
        self.text = text
        self.language = language
        self.confidence = confidence
        self.duration = duration
        self.timestamp = Date()
    }
}

// MARK: - Configuración de Voz
/// Configuración global para el sistema de voz
struct VoiceConfiguration {
    // STT (Speech-to-Text)
    var preferredLocale: String = "es-MX"  // Español México por defecto
    var silenceTimeout: TimeInterval = 1.5  // Segundos de silencio para detectar fin
    var enableOnDeviceProcessing: Bool = true
    
    // TTS (Text-to-Speech)
    var speechRate: Float = 0.57           // Velocidad (0.5 es default)
    var pitchMultiplier: Float = 0.9       // Tono (1.0 es default)
    var postUtteranceDelay: TimeInterval = 0.2
    var enablePersonalVoice: Bool = false
    var selectedVoiceIdentifier: String?
    
    // Idiomas soportados
    static let supportedLanguages: [String: String] = [
        "es-MX": "Español (México)",
        "es-ES": "Español (España)",
        // Tsotsil se agregará cuando esté disponible
    ]
    
    /// Configuración por defecto
    static let `default` = VoiceConfiguration()
}
