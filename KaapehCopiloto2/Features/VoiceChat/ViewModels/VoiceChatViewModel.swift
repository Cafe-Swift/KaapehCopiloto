//
//  VoiceChatViewModel.swift
//  KaapehCopiloto2
//
//  ViewModel para Voice Chat con State Machine completo
//  Orquesta: STT → Foundation Models → TTS → Loop
//  Basado en: Doc 4 (Voice Interface Guide) - Part 4
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class VoiceChatViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var state: VoiceChatState = .idle
    @Published var messages: [ChatMessage] = []
    @Published var errorMessage: String?
    @Published var volatileTranscript: String = ""
    
    // MARK: - Services
    let speechManager: ModernSpeechManager
    let ttsManager: TextToSpeechManager
    private let ragService: RAGService
    private let permissionManager: PermissionManager
    
    // MARK: - Initialization
    init(ragService: RAGService) {
        self.ragService = ragService
        self.speechManager = ModernSpeechManager()
        self.ttsManager = TextToSpeechManager()
        self.permissionManager = PermissionManager()
        
        setupCallbacks()
        setupAppIntentsObservers()
        
        print("🎙️ VoiceChatViewModel inicializado con ModernSpeechManager (SpeechAnalyzer)")
    }
    
    // MARK: - Setup
    
    private func setupCallbacks() {
        // STT: Cuando el usuario termina de hablar (después de silencio)
        speechManager.onTranscriptionComplete = { [weak self] transcript in
            Task { @MainActor [weak self] in
                await self?.handleUserTranscript(transcript)
            }
        }
        
        // STT: Actualización volátil (para feedback visual)
        speechManager.onVolatileUpdate = { [weak self] volatileText in
            Task { @MainActor [weak self] in
                self?.volatileTranscript = volatileText
            }
        }
        
        // STT: Errores de transcripción
        speechManager.onError = { [weak self] error in
            Task { @MainActor [weak self] in
                self?.handleError(error)
            }
        }
        
        // TTS: Cuando el asistente termina de hablar → LOOP AUTOMÁTICO
        ttsManager.onSpeechFinished = { [weak self] in
            Task { @MainActor [weak self] in
                self?.loopBackToListening()
            }
        }
    }
    
    // MARK: - State Machine (CORE)
    
    /// Transición central del estado
    func transition(to newState: VoiceChatState) {
        guard state != newState else { return }
        
        let oldState = state
        state = newState
        
        print("🔄 State: \(oldState.description) → \(newState.description)")
        
        // Ejecutar acciones según el nuevo estado
        switch newState {
        case .idle:
            stopAllServices()
            
        case .listening:
            Task {
                await startListening()
            }
            
        case .processingResponse:
            // Este estado se maneja en handleUserTranscript
            break
            
        case .speaking:
            // Este estado se maneja en speakResponse
            break
        }
    }
    
    // MARK: - Voice Cycle
    
    /// 1. LISTENING: Inicia la escucha
    private func startListening() async {
        do {
            // Verificar permisos primero
            if !permissionManager.allPermissionsGranted {
                try await permissionManager.requestAllPermissions()
            }
            
            // Limpiar transcript volátil anterior
            volatileTranscript = ""
            
            // Iniciar STT (usa locale configurado en ModernSpeechManager)
            try await speechManager.startListening()
            
            print("🎤 Escuchando... (SpeechAnalyzer activo)")
            
        } catch {
            print("❌ Error al iniciar escucha: \(error)")
            handleError(error)
            transition(to: .idle)
        }
    }
    
    /// 2. PROCESSING: Procesa el transcript del usuario
    private func handleUserTranscript(_ transcript: String) async {
        print("📝 Usuario dijo: '\(transcript)'")
        
        // Cambiar a estado de procesamiento
        transition(to: .processingResponse)
        
        // Agregar mensaje del usuario
        let userMessage = ChatMessage(
            content: transcript,
            isFromUser: true
        )
        messages.append(userMessage)
        
        // Generar respuesta usando RAG
        await generateRAGResponse(for: transcript)
    }
    
    /// 3. GENERATE: Genera respuesta con RAG
    private func generateRAGResponse(for query: String) async {
        do {
            print("🧠 Generando respuesta para: '\(query)'")
            
            // Llamar al pipeline RAG completo - devuelve ChatMessage ya formateado
            let assistantMessage = try await ragService.answer(query: query)
            
            print("✅ Respuesta generada:")
            print("   - Content: \(assistantMessage.content.prefix(50))...")
            if let sources = assistantMessage.sources {
                print("   - Sources: \(sources.joined(separator: ", "))")
            }
            
            // Agregar mensaje del asistente
            messages.append(assistantMessage)
            
            // Pasar a estado de habla (leer el contenido completo)
            await speakResponse(assistantMessage.content)
            
        } catch {
            print("❌ Error generando respuesta: \(error)")
            errorMessage = error.localizedDescription
            
            // Respuesta de error
            let errorResponse = "Lo siento, ocurrió un error al procesar tu consulta. ¿Puedes intentar de nuevo?"
            let errorMessage = ChatMessage(
                content: errorResponse,
                isFromUser: false
            )
            messages.append(errorMessage)
            
            await speakResponse(errorResponse)
        }
    }
    
    /// 4. SPEAKING: Lee la respuesta en voz alta
    private func speakResponse(_ text: String) async {
        transition(to: .speaking)
        
        print("🔊 Hablando respuesta...")
        
        // TTS hablará y llamará onSpeechFinished cuando termine
        ttsManager.speak(text)
    }
    
    /// 5. LOOP: Vuelve a escuchar (el ciclo continúa)
    private func loopBackToListening() {
        print("🔄 Loop: Volviendo a escuchar...")
        
        // Pequeño delay para que sea natural
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 segundos
            transition(to: .listening)
        }
    }
    
    // MARK: - Control Methods
    
    /// Maneja errores de manera centralizada
    private func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
        
        // Agregar mensaje de error a la conversación
        let errorChatMessage = ChatMessage(
            content: "❌ Error: \(error.localizedDescription)",
            isFromUser: false
        )
        messages.append(errorChatMessage)
    }
    
    /// Inicia el modo de voz
    func startVoiceMode() {
        guard state == .idle else {
            print("⚠️ Voice mode ya está activo")
            return
        }
        
        // Agregar mensaje de bienvenida
        let welcomeMessage = ChatMessage(
            content: "🎙️ Modo de voz activado. Puedes hablarme ahora.",
            isFromUser: false
        )
        messages.append(welcomeMessage)
        
        transition(to: .listening)
    }
    
    /// Detiene el modo de voz
    func stopVoiceMode() {
        guard state != .idle else { return }
        
        transition(to: .idle)
        
        let goodbyeMessage = ChatMessage(
            content: "👋 Modo de voz desactivado.",
            isFromUser: false
        )
        messages.append(goodbyeMessage)
    }
    
    /// Detiene todos los servicios
    private func stopAllServices() {
        speechManager.stopListening()
        ttsManager.stopSpeaking()
    }
    
    /// Usuario interrumpe (tap en botón durante speaking/listening)
    func handleUserInterrupt() {
        switch state {
        case .idle:
            // Activar voice mode
            startVoiceMode()
            
        case .listening:
            // Usuario quiere forzar el fin de su turno
            speechManager.stopListening()
            // El callback handleUserTranscript se llamará automáticamente
            
        case .processingResponse:
            // No se puede interrumpir el procesamiento
            print("⚠️ Esperando respuesta...")
            
        case .speaking:
            // Usuario interrumpe al asistente
            ttsManager.stopSpeaking()
            transition(to: .listening)
        }
    }
    
    // MARK: - UI Helpers
    
    var stateIcon: String {
        switch state {
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
    
    var stateColor: Color {
        switch state {
        case .idle:
            return .gray
        case .listening:
            return .red
        case .processingResponse:
            return .orange
        case .speaking:
            return .blue
        }
    }
    
    var canInterrupt: Bool {
        state != .processingResponse
    }
    
    // MARK: - App Intents Integration (FASE 8)
    
    /// ✅ Configura observers para App Intents (Siri Shortcuts)
    private func setupAppIntentsObservers() {
        // Observer para "Start Voice Chat"
        NotificationCenter.default.addObserver(
            forName: .startVoiceChatFromIntent,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                
                print("📱 App Intent: Start Voice Chat recibido")
                
                // Extraer pregunta inicial si existe
                if let userInfo = notification.userInfo,
                   let initialQuestion = userInfo["initialQuestion"] as? String,
                   !initialQuestion.isEmpty {
                    
                    // Simular que el usuario hizo esta pregunta
                    await self.handleUserTranscript(initialQuestion)
                } else {
                    // Solo iniciar listening mode
                    self.transition(to: .listening)
                }
            }
        }
        
        // Observer para "Diagnose Plant"
        NotificationCenter.default.addObserver(
            forName: .startDiagnosisFromIntent,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                
                print("📱 App Intent: Diagnose Plant recibido")
                
                // Extraer tipo de análisis
                if let userInfo = notification.userInfo,
                   let analysisType = userInfo["analysisType"] as? String {
                    
                    // TODO: Abrir cámara directamente para diagnóstico
                    let message = "Análisis de tipo \(analysisType) iniciado. Por favor, toma una foto de tu planta."
                    await self.speakMessage(message)
                } else {
                    // Modo genérico
                    let message = "Prepara la cámara para diagnosticar tu planta de café."
                    await self.speakMessage(message)
                }
                
                // Transicionar a listening después del mensaje
                try? await Task.sleep(for: .seconds(2))
                self.transition(to: .listening)
            }
        }
    }
    
    /// Helper para hablar un mensaje del sistema
    private func speakMessage(_ text: String) async {
        let systemMessage = ChatMessage(content: text, isFromUser: false)
        messages.append(systemMessage)
        
        state = .speaking
        ttsManager.speak(text)
    }
    
    // MARK: - Cleanup
    
    func cleanup() {
        stopAllServices()
        messages.removeAll()
        state = .idle
        
        // Remover observers
        NotificationCenter.default.removeObserver(self)
    }
}
