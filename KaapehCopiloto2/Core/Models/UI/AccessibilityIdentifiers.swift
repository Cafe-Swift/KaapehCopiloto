//
//  AccessibilityIdentifiers.swift
//  KaapehCopiloto2
//
//  Identificadores centralizados para:
//  - UI Testing (XCUITest)
//  - Voice Control labels
//  - VoiceOver support
//
//  Basado en: Doc 4 (Voice Interface) - Section 6: Voice Control
//

import Foundation

/// ✅ FASE 8: Identificadores de accesibilidad centralizados
enum AccessibilityID {
    // MARK: - Voice Chat
    enum VoiceChat {
        static let voiceButton = "voice_chat_main_button"
        static let settingsButton = "voice_chat_settings_button"
        static let stateIndicator = "voice_chat_state_indicator"
        static let volatileTranscript = "voice_chat_volatile_transcript"
        static let chatScrollView = "voice_chat_scroll_view"
    }
    
    // MARK: - Chat Messages
    enum ChatMessage {
        static func userBubble(id: String) -> String {
            "chat_bubble_user_\(id)"
        }
        
        static func assistantBubble(id: String) -> String {
            "chat_bubble_assistant_\(id)"
        }
        
        static let sourcesView = "chat_message_sources"
        static let performanceView = "chat_message_performance"
    }
    
    // MARK: - Settings
    enum Settings {
        static let speechRateSlider = "settings_speech_rate_slider"
        static let pitchSlider = "settings_pitch_slider"
        static let personalVoiceToggle = "settings_personal_voice_toggle"
        static let voicePicker = "settings_voice_picker"
    }
    
    // MARK: - Camera
    enum Camera {
        static let captureButton = "camera_capture_button"
        static let sourcePickerButton = "camera_source_picker_button"
        static let imagePreview = "camera_image_preview"
        static let clearImageButton = "camera_clear_image_button"
    }
    
    // MARK: - Diagnosis
    enum Diagnosis {
        static let resultCard = "diagnosis_result_card"
        static let confidenceBadge = "diagnosis_confidence_badge"
        static let treatmentsList = "diagnosis_treatments_list"
        static let preventionList = "diagnosis_prevention_list"
        static let sourcesList = "diagnosis_sources_list"
    }
}

/// ✅ FASE 8: Labels de accesibilidad en español
enum AccessibilityLabel {
    // MARK: - Voice Chat
    enum VoiceChat {
        static let voiceButtonIdle = "Iniciar chat por voz"
        static let voiceButtonListening = "Detener grabación"
        static let voiceButtonProcessing = "Procesando respuesta"
        static let voiceButtonSpeaking = "Detener reproducción"
        
        static let settingsButton = "Configuración de voz"
    }
    
    // MARK: - Camera
    enum Camera {
        static let captureButton = "Capturar foto de planta"
        static let galleryButton = "Seleccionar de galería"
        static let clearButton = "Eliminar foto capturada"
    }
}

/// ✅ FASE 8: Input labels para Voice Control (shortcuts de voz)
enum AccessibilityInputLabels {
    // MARK: - Voice Chat
    enum VoiceChat {
        static let voiceButtonIdle: [String] = [
            "Hablar", "Micrófono", "Grabar", "Iniciar", "Voz"
        ]
        
        static let voiceButtonListening: [String] = [
            "Detener", "Parar", "Enviar", "Terminar"
        ]
        
        static let voiceButtonSpeaking: [String] = [
            "Detener", "Parar", "Interrumpir", "Silenciar"
        ]
        
        static let settingsButton: [String] = [
            "Configuración", "Ajustes", "Opciones"
        ]
    }
    
    // MARK: - Camera
    enum Camera {
        static let captureButton: [String] = [
            "Foto", "Capturar", "Cámara", "Tomar"
        ]
        
        static let galleryButton: [String] = [
            "Galería", "Fotos", "Seleccionar", "Elegir"
        ]
        
        static let clearButton: [String] = [
            "Eliminar", "Borrar", "Limpiar", "Quitar"
        ]
    }
}

/// ✅ FASE 8: Hints para VoiceOver (descripciones contextuales)
enum AccessibilityHint {
    // MARK: - Voice Chat
    enum VoiceChat {
        static let voiceButtonIdle = "Toca para activar el micrófono y comenzar a hablar"
        static let voiceButtonListening = "Toca para detener la grabación y enviar tu mensaje"
        static let voiceButtonProcessing = "Esperando respuesta del asistente"
        static let voiceButtonSpeaking = "Toca para interrumpir al asistente y volver a hablar"
        
        static let settingsButton = "Abre la configuración de velocidad y tono de voz"
    }
    
    // MARK: - Camera
    enum Camera {
        static let captureButton = "Toca para abrir la cámara o seleccionar una foto"
        static let clearButton = "Toca para eliminar la foto actual"
    }
}
