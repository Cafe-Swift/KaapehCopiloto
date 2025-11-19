//
//  ModernSpeechManager.swift
//  KaapehCopiloto2
//
//  Servicio de Speech-to-Text usando SFSpeechRecognizer
//

import Foundation
import Speech
import AVFoundation

// MARK: - Errors
enum TranscriptionError: Error, LocalizedError {
    case notAuthorized
    case localeNotSupported
    case transcriptionFailed
    case modelDownloadFailed
    case audioEngineFailed
    
    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Permiso de reconocimiento de voz no otorgado"
        case .localeNotSupported:
            return "El idioma no está soportado"
        case .transcriptionFailed:
            return "Error en la transcripción"
        case .modelDownloadFailed:
            return "Error descargando el modelo de idioma"
        case .audioEngineFailed:
            return "Error configurando el audio"
        }
    }
}

// MARK: - ModernSpeechManager
@MainActor
final class ModernSpeechManager {
    // MARK: - Properties
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioEngine = AVAudioEngine()
    
    // Estado
    var isListening: Bool = false
    var currentLocale: Locale = Locale.current
    
    // Transcripción acumulada
    private var currentTurnTranscript: String = ""
    var volatileTranscript: String = ""
    
    // Temporizador de silencio (fin de turno)
    private var endOfTurnTimer: Timer?
    private let silenceDuration: TimeInterval = 1.5
    
    // Callbacks
    var onTranscriptionComplete: ((String) -> Void)?
    var onVolatileUpdate: ((String) -> Void)?
    var onError: ((Error) -> Void)?
    
    // MARK: - Initialization
    init(locale: Locale = Locale(identifier: "es-MX")) {
        self.currentLocale = locale
        self.speechRecognizer = SFSpeechRecognizer(locale: locale)
        print("🎙️ ModernSpeechManager inicializado para \(locale.identifier)")
    }
    
    // MARK: - Public API
    
    /// Inicia la escucha y transcripción
    func startListening() async throws {
        guard !isListening else {
            print("⚠️ Ya está escuchando")
            return
        }
        
        // Verificar autorización
        let authStatus = SFSpeechRecognizer.authorizationStatus()
        guard authStatus == .authorized else {
            throw TranscriptionError.notAuthorized
        }
        
        // Verificar que el recognizer esté disponible
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            throw TranscriptionError.localeNotSupported
        }
        
        // Limpiar estado previo
        currentTurnTranscript = ""
        volatileTranscript = ""
        
        // Configurar audio session
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        // Crear request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            throw TranscriptionError.transcriptionFailed
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // Configurar audio engine
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        
        // Iniciar reconocimiento
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            Task { @MainActor in
                if let result = result {
                    self.handleRecognitionResult(result)
                }
                
                if let error = error {
                    print("❌ Error en reconocimiento: \(error)")
                    self.onError?(error)
                    self.stopListening()
                }
            }
        }
        
        isListening = true
        print("✅ Escuchando...")
    }
    
    /// Detiene la escucha
    func stopListening() {
        guard isListening else { return }
        
        endOfTurnTimer?.invalidate()
        endOfTurnTimer = nil
        
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        
        recognitionTask?.cancel()
        recognitionTask = nil
        
        isListening = false
        print("🛑 Escucha detenida")
    }
    
    // MARK: - Private Methods
    
    private func handleRecognitionResult(_ result: SFSpeechRecognitionResult) {
        let transcribedText = result.bestTranscription.formattedString
        
        if result.isFinal {
            // Resultado final
            currentTurnTranscript = transcribedText
            volatileTranscript = ""
            onVolatileUpdate?("")
            
            // Esperar silencio para confirmar fin de turno
            resetEndOfTurnTimer()
        } else {
            // Resultado parcial (volátil)
            volatileTranscript = transcribedText
            onVolatileUpdate?(transcribedText)
            
            // Resetear temporizador de silencio
            resetEndOfTurnTimer()
        }
    }
    
    private func resetEndOfTurnTimer() {
        endOfTurnTimer?.invalidate()
        
        endOfTurnTimer = Timer.scheduledTimer(withTimeInterval: silenceDuration, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                self.handleEndOfTurn()
            }
        }
    }
    
    private func handleEndOfTurn() {
        print("🔇 Silencio detectado - Fin de turno")
        
        let finalTranscript = currentTurnTranscript.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if !finalTranscript.isEmpty {
            onTranscriptionComplete?(finalTranscript)
        }
        
        // Limpiar para el próximo turno
        currentTurnTranscript = ""
        volatileTranscript = ""
    }
}
