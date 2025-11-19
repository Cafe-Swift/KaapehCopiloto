//
//  TextToSpeechManager.swift
//  KaapehCopiloto2
//
//  Servicio TTS usando AVSpeechSynthesizer
//

import AVFoundation
import NaturalLanguage
import Foundation
import Combine

enum TTSError: Error {
    case synthesisUnavailable
    case personalVoiceNotAuthorized
    case noVoiceAvailable
    
    var localizedDescription: String {
        switch self {
        case .synthesisUnavailable:
            return "El sintetizador de voz no está disponible"
        case .personalVoiceNotAuthorized:
            return "No tienes autorización para usar Personal Voice"
        case .noVoiceAvailable:
            return "No hay voces disponibles para este idioma"
        }
    }
}

@MainActor
final class TextToSpeechManager: NSObject, ObservableObject {
    // MARK: - Published Properties
    @Published var isSpeaking: Bool = false
    @Published var personalVoiceAuthStatus: AVSpeechSynthesizer.PersonalVoiceAuthorizationStatus = .notDetermined
    @Published var availablePersonalVoices: [AVSpeechSynthesisVoice] = []
    
    // MARK: - Private Properties
    private let synthesizer: AVSpeechSynthesizer
    private var selectedVoiceIdentifier: String?
    private var currentRate: Float = 0.52
    private var currentPitch: Float = 1.0
    
    // Callback cuando termina de hablar
    var onSpeechFinished: (() -> Void)?
    
    // MARK: - Computed Properties (for UI)
    var personalVoiceAuthorized: Bool {
        personalVoiceAuthStatus == .authorized
    }
    
    var hasPersonalVoices: Bool {
        !availablePersonalVoices.isEmpty
    }
    
    var selectedVoiceID: String? {
        selectedVoiceIdentifier
    }
    
    // MARK: - Initialization
    override init() {
        self.synthesizer = AVSpeechSynthesizer()
        super.init()
        
        // El ViewModel debe ser el delegate
        synthesizer.delegate = self
        
        print("🔊 TextToSpeechManager inicializado")
        
        // Check personal voice auth en background
        Task {
            await checkPersonalVoiceAuthorization()
        }
    }
    
    // MARK: - Public API
    
    /// Habla un texto con detección automática de idioma
    func speak(_ text: String) {
        guard !text.isEmpty else { return }
        
        // Detener cualquier speech en progreso
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        // Crear utterance
        let utterance = AVSpeechUtterance(string: text)
        
        // Detectar idioma del texto
        let detectedLanguage = detectLanguage(in: text)
        
        // Configurar voz
        if let voiceId = selectedVoiceIdentifier,
           let customVoice = AVSpeechSynthesisVoice(identifier: voiceId) {
            utterance.voice = customVoice
            print("🗣️ Usando voz personalizada")
        } else {
            // Usar voz del sistema para el idioma detectado
            utterance.voice = AVSpeechSynthesisVoice(language: detectedLanguage)
            print("🗣️ Usando voz del sistema para: \(detectedLanguage)")
        }
        
        // Configurar parámetros de habla
        utterance.rate = 0.52  // Ligeramente más lento que default
        utterance.pitchMultiplier = 1.0  // Pitch normal
        utterance.volume = 1.0
        utterance.postUtteranceDelay = 0.1  // Breve pausa después
        
        // Hablar
        isSpeaking = true
        synthesizer.speak(utterance)
        
        print("🔊 Hablando (\(detectedLanguage)): '\(text.prefix(50))...'")
    }
    
    /// Detiene el habla inmediatamente
    func stopSpeaking() {
        guard synthesizer.isSpeaking else { return }
        
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
        
        print("🛑 Speech detenido")
    }
    
    /// Pausa el habla (puede resumirse)
    func pauseSpeaking() {
        guard synthesizer.isSpeaking else { return }
        
        synthesizer.pauseSpeaking(at: .immediate)
        print("⏸️ Speech pausado")
    }
    
    /// Resume el habla pausada
    func resumeSpeaking() {
        guard synthesizer.isPaused else { return }
        
        synthesizer.continueSpeaking()
        print("▶️ Speech resumido")
    }
    
    // MARK: - Personal Voice Support
    
    /// Verifica y solicita autorización para Personal Voice
    func checkPersonalVoiceAuthorization() async {
        let currentStatus = AVSpeechSynthesizer.personalVoiceAuthorizationStatus
        personalVoiceAuthStatus = currentStatus
        
        if currentStatus == .notDetermined {
            print("🔐 Solicitando autorización Personal Voice...")
            let newStatus = await AVSpeechSynthesizer.requestPersonalVoiceAuthorization()
            personalVoiceAuthStatus = newStatus
        }
        
        if personalVoiceAuthStatus == .authorized {
            await loadPersonalVoices()
        }
        
        print("🎙️ Personal Voice status: \(personalVoiceAuthStatus)")
    }
    
    /// Carga las voces personales disponibles
    private func loadPersonalVoices() async {
        let allVoices = AVSpeechSynthesisVoice.speechVoices()
        
        // Filtrar voces personales
        availablePersonalVoices = allVoices.filter { voice in
            voice.voiceTraits.contains(.isPersonalVoice)
        }
        
        print("🎙️ Voces personales disponibles: \(availablePersonalVoices.count)")
        
        // Seleccionar la primera voz personal por defecto
        if let firstPersonalVoice = availablePersonalVoices.first {
            selectedVoiceIdentifier = firstPersonalVoice.identifier
            print("✅ Voz personal seleccionada: \(firstPersonalVoice.name)")
        }
    }
    
    /// Selecciona una voz específica
    func selectVoice(identifier: String) {
        selectedVoiceIdentifier = identifier
        print("🎚️ Voz seleccionada: \(identifier)")
    }
    
    /// Resetea a la voz del sistema
    func useSystemVoice() {
        selectedVoiceIdentifier = nil
        print("🎚️ Usando voz del sistema")
    }
    
    // MARK: - Language Detection
    
    /// Detecta el idioma de un texto usando NaturalLanguage
    private func detectLanguage(in text: String) -> String {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        
        if let languageCode = recognizer.dominantLanguage?.rawValue {
            // Validar que haya una voz disponible para este idioma
            if AVSpeechSynthesisVoice(language: languageCode) != nil {
                return languageCode
            }
        }
        
        // Fallback a español de México
        return "es-MX"
    }
    
    // MARK: - Voice Info
    
    /// Obtiene información sobre voces disponibles
    func getAvailableVoices(for language: String? = nil) -> [AVSpeechSynthesisVoice] {
        if let language = language {
            return AVSpeechSynthesisVoice.speechVoices().filter { $0.language.hasPrefix(language) }
        } else {
            return AVSpeechSynthesisVoice.speechVoices()
        }
    }
    
    /// Información sobre la voz actual
    var currentVoiceInfo: String {
        if let voiceId = selectedVoiceIdentifier,
           let voice = AVSpeechSynthesisVoice(identifier: voiceId) {
            return "Personal: \(voice.name) (\(voice.language))"
        } else {
            return "Sistema (auto-detect)"
        }
    }
    
    // MARK: - UI Configuration Methods (for Settings)
    
    /// Configura la velocidad de habla
    func setRate(_ rate: Float) {
        currentRate = rate
        print("🎚️ Rate ajustado: \(rate)")
    }
    
    /// Configura el tono de voz
    func setPitch(_ pitch: Float) {
        currentPitch = pitch
        print("🎚️ Pitch ajustado: \(pitch)")
    }
    
    /// Selecciona una voz personal
    func selectPersonalVoice(withIdentifier identifier: String) {
        selectedVoiceIdentifier = identifier
        print("✅ Voz personal seleccionada: \(identifier)")
    }
    
    /// Limpia la selección de voz personal
    func clearPersonalVoiceSelection() {
        selectedVoiceIdentifier = nil
        print("🎚️ Usando voz del sistema")
    }
    
    /// Alias para checkPersonalVoiceAuthorization
    func checkPersonalVoiceAvailability() async {
        await checkPersonalVoiceAuthorization()
    }
}

// MARK: - AVSpeechSynthesizerDelegate
extension TextToSpeechManager: AVSpeechSynthesizerDelegate {
    /// Se llama cuando empieza a hablar
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        Task { @MainActor in
            print("🔊 TTS iniciado")
            self.isSpeaking = true
        }
    }
    
    /// Se llama cuando termina de hablar
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            print("✅ TTS terminado")
            self.isSpeaking = false
            
            // Notificar que terminó para volver a escuchar
            self.onSpeechFinished?()
        }
    }
    
    /// Se llama si se cancela
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            print("❌ TTS cancelado")
            self.isSpeaking = false
        }
    }
}
