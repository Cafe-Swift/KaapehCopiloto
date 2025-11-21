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
    private let silenceDuration: TimeInterval = 2.0
    
    // Callbacks
    var onTranscriptionComplete: ((String) async -> Void)?
    var onTranscriptionUpdate: ((String) async -> Void)?
    var onVolatileUpdate: ((String) -> Void)?
    var onError: ((Error) -> Void)?
    
    //  Recognizers para múltiples idiomas
    private var spanishRecognizer: SFSpeechRecognizer?
    private var systemRecognizer: SFSpeechRecognizer?
    
    // MARK: - Initialization
    init(locale: Locale = Locale(identifier: "es-MX")) {
        self.currentLocale = locale
        
        // 🎯 PRIORIDAD: Inicializar recognizer para español SIEMPRE
        // Esto permite reconocer español independientemente del idioma del sistema
        self.spanishRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "es-MX"))
        
        // Fallback: crear recognizer para el idioma del sistema solo si no es español
        let systemLocale = Locale.current.identifier
        if systemLocale != "es-MX" && systemLocale != "es-ES" && systemLocale != "es" {
            self.systemRecognizer = SFSpeechRecognizer(locale: Locale.current)
        }
        
        // ✅ Preferir español por defecto (independientemente del idioma del sistema)
        self.speechRecognizer = self.spanishRecognizer
        
        print("🎙️ ModernSpeechManager inicializado")
        print("   📍 Idioma del dispositivo: \(systemLocale)")
        print("   ✅ Recognizer español (es-MX): \(spanishRecognizer?.isAvailable == true ? "Disponible" : "No disponible")")
        if let systemRecognizer = systemRecognizer {
            print("   ℹ️  Recognizer del sistema (\(systemRecognizer.locale.identifier)): Disponible como fallback")
        }
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
            print("❌ Speech recognition no autorizado: \(authStatus.rawValue)")
            throw TranscriptionError.notAuthorized
        }
        
        // Intentar usar español primero, luego fallback al sistema
        if let spanish = spanishRecognizer, spanish.isAvailable {
            print("   ✅ Usando recognizer español")
            speechRecognizer = spanish
        } else if let system = systemRecognizer, system.isAvailable {
            print("   ⚠️ Español no disponible, usando recognizer del sistema")
            speechRecognizer = system
        } else {
            print("❌ No hay recognizer disponible")
            throw TranscriptionError.localeNotSupported
        }
        
        guard let speechRecognizer = speechRecognizer else {
            throw TranscriptionError.localeNotSupported
        }
        
        // Limpiar estado previo
        currentTurnTranscript = ""
        volatileTranscript = ""
        
        // Configurar audio session con mejor calidad
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        // Crear request con configuración mejorada
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            throw TranscriptionError.transcriptionFailed
        }
        
        // Configuración optimizada para conversación
        recognitionRequest.shouldReportPartialResults = true
        
        // Permitir server para mejor precisión en español
        if #available(iOS 13.0, *) {
            recognitionRequest.requiresOnDeviceRecognition = false
        }
        
        // Configurar audio engine
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        
        // Iniciar reconocimiento con manejo mejorado de errores
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            Task { @MainActor in
                if let result = result {
                    self.handleRecognitionResult(result)
                }
                
                if let error = error {
                    let nsError = error as NSError
                    print("❌ Error en reconocimiento: \(error.localizedDescription)")
                    print("   - Domain: \(nsError.domain)")
                    print("   - Code: \(nsError.code)")
                    
                    // Solo reportar errores críticos, ignorar cancelaciones normales
                    if nsError.code != 201 && nsError.code != 203 { // 201 = cancelled, 203 = retry
                        self.onError?(error)
                    }
                    
                    if result == nil || !result!.isFinal {
                        // Si no es final y hay error, detener
                        self.stopListening()
                    }
                }
            }
        }
        
        isListening = true
        print("✅ Escuchando con \(speechRecognizer.locale.identifier)...")
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
        
        print("📝 Transcripción: '\(transcribedText)' (final: \(result.isFinal))")
        
        if result.isFinal {
            // Resultado final actualizar transcript acumulado
            if !transcribedText.isEmpty {
                currentTurnTranscript = transcribedText
                volatileTranscript = ""
                self.onVolatileUpdate?("")
                Task { await self.onTranscriptionUpdate?("") }
                
                print("   ✅ Final transcript: '\(currentTurnTranscript)'")
            }
            
            // Esperar silencio adicional para confirmar fin de turno
            resetEndOfTurnTimer()
        } else {
            // Resultado parcial
            volatileTranscript = transcribedText
            self.onVolatileUpdate?(transcribedText)
            Task { await self.onTranscriptionUpdate?(transcribedText) }
            
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
        
        print("   📝 Transcript final limpio: '\(finalTranscript)'")
        
        if !finalTranscript.isEmpty {
            Task {
                await self.onTranscriptionComplete?(finalTranscript)
            }
        } else {
            print("   ⚠️ Transcript vacío, no se envía")
        }
        
        // Limpiar para el próximo turno
        currentTurnTranscript = ""
        volatileTranscript = ""
    }
}
