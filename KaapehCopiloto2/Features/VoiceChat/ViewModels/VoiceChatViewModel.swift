//
//  VoiceChatViewModel.swift
//  KaapehCopiloto2
//
//  ViewModel para Voice Chat con State Machine completo
//

import Foundation
import SwiftUI
import Combine
import SwiftData

@MainActor
final class VoiceChatViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var state: VoiceChatState = .idle
    @Published var messages: [ChatMessage] = []
    @Published var errorMessage: String?
    @Published var volatileTranscript: String = ""
    @Published var currentConversation: Conversation?
    
    // MARK: - Services
    let speechManager: ModernSpeechManager
    let ttsManager: TextToSpeechManager
    let ragService: RAGService
    private let permissionManager: PermissionManager
    
    // MARK: - Computed Properties
    
    /// Icono del estado actual para la UI
    var stateIcon: String {
        state.iconName
    }
    
    /// Color del estado actual para la UI
    var stateColor: Color {
        switch state {
        case .idle:
            return .gray
        case .listening:
            return .red
        case .processingResponse:
            return .blue
        case .speaking:
            return .green
        }
    }
    
    // MARK: - Initialization
    init(ragService: RAGService, conversation: Conversation? = nil) {
        self.ragService = ragService
        self.speechManager = ModernSpeechManager()
        self.ttsManager = TextToSpeechManager()
        self.permissionManager = PermissionManager()
        
        setupCallbacks()
        setupAppIntentsObservers()
        
        if let conversation = conversation {
            loadConversation(conversation)
        } else {
            createNewConversation()
        }
        
        print("🎙️ VoiceChatViewModel inicializado")
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
        
        // TTS: Cuando el asistente termina de hablar → VOLVER A IDLE (NO AUTO-LOOP)
        ttsManager.onSpeechFinished = { [weak self] in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                print("✅ TTS terminado")
                
                // Limpiar el estado del speech manager por si quedó algo pendiente
                self.stopListening()

                self.transition(to: .idle)
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
            stopListening()
            volatileTranscript = "" // Limpiar el transcript volátil
            
        case .speaking:
            // Asegurar que el micrófono esté detenido mientras hablamos
            stopListening()
        }
    }
    
    // MARK: - Public Methods
    
    /// Envía un mensaje de texto (para chat sin voz)
    func sendMessage(_ text: String) async {
        await handleUserTranscript(text)
    }
    
    // MARK: - Listening (STT)
    
    private func startListening() async {
        do {
            // 1. Solicitar permisos si es necesario
            try await permissionManager.requestAllPermissions()
            
            // 2. Iniciar escucha
            try await speechManager.startListening()
            
            print("🎤 Escuchando... (SpeechAnalyzer activo)")
            
        } catch {
            handleError(error)
        }
    }
    
    private func stopListening() {
        print("🛑 Escucha detenida")
        speechManager.stopListening()
    }
    
    // MARK: - Context Window Management
    
    /// Límite aproximado de tokens para el contexto (4096 tokens reales)
    /// Usamos 3500 como límite seguro para dejar espacio al RAG context
    private let maxContextTokens = 3500
    
    /// Estima tokens aproximados (1 token ≈ 4 caracteres en español)
    private func estimateTokens(for text: String) -> Int {
        return text.count / 4
    }
    
    /// Limpia mensajes antiguos si nos acercamos al límite de contexto
    private func pruneMessagesIfNeeded() {
        let totalTokens = messages.reduce(0) { $0 + estimateTokens(for: $1.content) }
        
        guard totalTokens > maxContextTokens else {
            return // Aún hay espacio
        }
        
        print("⚠️ Ventana de contexto cerca del límite (\(totalTokens) tokens)")
        print("🧹 Limpiando mensajes antiguos...")
        
        // Mantener solo los últimos 6 mensajes (3 turnos de conversación)
        if messages.count > 6 {
            let messagesToKeep = messages.suffix(6)
            messages = Array(messagesToKeep)
            
            // Actualizar en la conversación
            saveMessages()
            
            print("✅ Mensajes reducidos a \(messages.count)")
        } else {
            // Si con 6 mensajes aún estamos sobre el límite, crear nueva conversación
            print("⚠️ Incluso con 6 mensajes estamos sobre el límite")
            print("✨ Creando nueva conversación...")
            
            // Guardar la conversación actual
            saveCurrentConversation()
            
            // Crear nueva conversación limpia
            createNewConversation()
        }
    }
    
    // MARK: - Processing (RAG)
    
    private func handleUserTranscript(_ transcript: String) async {
        let cleanedTranscript = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !cleanedTranscript.isEmpty else {
            print("⚠️ Transcript vacío, volviendo a idle")
            transition(to: .idle)
            return
        }
        
        pruneMessagesIfNeeded()
        
        // Transición a "pensando"
        transition(to: .processingResponse)
        
        print("🧠 Generando respuesta para: '\(cleanedTranscript)'")
        
        // Agregar mensaje del usuario
        let userMessage = ChatMessage(content: cleanedTranscript, isFromUser: true)
        messages.append(userMessage)
        saveMessages()
        
        do {
            // Llamar al RAG (devuelve un ChatMessage completo)
            let assistantMessage = try await ragService.answer(query: cleanedTranscript)
            
            // Agregar respuesta del asistente a la lista de mensajes
            messages.append(assistantMessage)
            saveMessages()
            
            print("✅ Respuesta generada:")
            print("   - Content: \(assistantMessage.content.prefix(50))...")
            print("   - Sources: \(assistantMessage.sources?.joined(separator: ", ") ?? "ninguna")")
            
            // Hablar la respuesta
            speakResponse(assistantMessage.content)
            
        } catch let error as NSError {
            if error.localizedDescription.contains("context window") {
                print("🚨 Error de ventana de contexto - Creando nueva conversación")
                
                // Guardar conversación actual
                saveCurrentConversation()
                
                // Crear nueva conversación
                createNewConversation()
                
                // Informar al usuario
                let errorMsg = ChatMessage(
                    content: "He creado una nueva conversación para poder continuar. ¿En qué más puedo ayudarte?",
                    isFromUser: false
                )
                messages.append(errorMsg)
                saveMessages()
                
                // Hablar mensaje de error
                speakResponse(errorMsg.content)
            } else {
                handleError(error)
            }
        } catch {
            handleError(error)
        }
    }
    
    // MARK: - Speaking (TTS)
    
    private func speakResponse(_ text: String) {
        print("🔊 Hablando respuesta...")
        transition(to: .speaking)
        ttsManager.speak(text)
    }
    
    // MARK: - Control Methods
    
    /// Maneja la interacción del usuario con el botón principal
    func handleUserInterrupt() {
        switch state {
        case .idle:
            // Presionar botón → INICIAR GRABACIÓN
            print("🎙️ Usuario presionó botón - Iniciando grabación")
            transition(to: .listening)
            
        case .listening:
            // Presionar botón mientras graba → DETENER Y USAR TRANSCRIPT ACTUAL
            print("⏹️ Usuario presionó botón - Deteniendo grabación y enviando")
            speechManager.stopAndUseCurrentTranscript()
            // El callback onTranscriptionComplete manejará el envío
            
        case .processingResponse:
            // No se puede interrumpir mientras procesa
            print("⚠️ Esperando respuesta del modelo...")
            
        case .speaking:
            // Presionar mientras habla → INTERRUMPIR Y VOLVER A IDLE (NO LISTENING)
            print("⏹️ Usuario interrumpió TTS")
            
            // CRÍTICO: Primero detener y limpiar todo el speech manager
            speechManager.stopListening() // Asegurar que NO está escuchando
            
            // Luego detener TTS
            ttsManager.stopSpeaking()
            
            // Ir directamente a IDLE (el usuario debe presionar de nuevo para hablar)
            transition(to: .idle)
        }
    }
    
    /// Detener todos los servicios activos
    private func stopAllServices() {
        // Usar resetState() para limpieza completa y prevenir callbacks pendientes
        speechManager.resetState()
        ttsManager.stopSpeaking()
        volatileTranscript = ""
    }
    
    /// Maneja errores de manera centralizada
    private func handleError(_ error: Error) {
        // No mostrar error para cancelaciones normales
        let nsError = error as NSError
        
        // 201 = cancelled (normal), 203 = retry, 301 = request was canceled
        if nsError.domain == "kLSRErrorDomain" && (nsError.code == 201 || nsError.code == 203 || nsError.code == 301) {
            print("ℹ️ Reconocimiento cancelado (normal): code \(nsError.code)")
            transition(to: .idle)
            return
        }
        
        // Error real - mostrar al usuario
        errorMessage = "❌ " + error.localizedDescription
        print("🚨 Error en VoiceChat: \(error.localizedDescription)")
        
        // Solo agregar mensaje de error si es crítico
        if nsError.code != 201 && nsError.code != 203 {
            let errorChatMessage = ChatMessage(
                content: "⚠️ Error de reconocimiento. Intenta de nuevo.",
                isFromUser: false
            )
            messages.append(errorChatMessage)
            saveMessages()
        }
        
        // Volver a idle
        transition(to: .idle)
    }
    
    // MARK: - App Intents Support
    
    private func setupAppIntentsObservers() {
        NotificationCenter.default.addObserver(
            forName: .startVoiceChatFromIntent,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self else { return }
            
            Task { @MainActor in
                if let userInfo = notification.userInfo,
                   let initialQuestion = userInfo["question"] as? String {
                    // Si hay pregunta inicial, procesarla directamente
                    await self.handleUserTranscript(initialQuestion)
                } else {
                    // Si no hay pregunta, solo iniciar escucha
                    self.transition(to: .listening)
                }
            }
        }
    }
    
    // MARK: - Message Helpers
    
    private func saveMessages() {
        guard let conversation = currentConversation else { return }
        ConversationService.shared.saveMessages(messages, to: conversation)
    }
}

// MARK: - Conversation Management Extension

extension VoiceChatViewModel {
    
    /// Crear nueva conversación
    func createNewConversation() {
        // Guardar conversación actual si existe
        saveCurrentConversation()
        
        // Crear nueva conversación
        currentConversation = ConversationService.shared.createConversation(isVoice: true)
        
        // Limpiar mensajes
        messages = []
        
        print("✨ Nueva conversación creada: \(currentConversation?.id.uuidString ?? "unknown")")
    }
    
    /// Cargar conversación existente
    func loadConversation(_ conversation: Conversation) {
        // Guardar conversación actual primero
        saveCurrentConversation()
        
        // Cargar nueva conversación
        currentConversation = conversation
        
        // Cargar mensajes desde la conversación
        messages = ConversationService.shared.loadMessages(from: conversation)
        
        print("📖 \(messages.count) mensajes cargados desde conversación")
        print("📖 Conversación cargada: \(conversation.title)")
    }
    
    /// Guardar conversación actual
    func saveCurrentConversation() {
        guard let conversation = currentConversation else {
            print("⚠️ No hay conversación actual para guardar")
            return
        }
        
        // Solo guardar si hay mensajes
        guard !messages.isEmpty else {
            print("ℹ️ Conversación vacía, no se guarda")
            return
        }
        
        // Guardar mensajes
        ConversationService.shared.saveMessages(messages, to: conversation)
        print("💾 Conversación guardada: \(conversation.title)")
    }
    
    /// Eliminar conversación actual
    func deleteCurrentConversation() {
        guard let conversation = currentConversation else { return }
        
        ConversationService.shared.delete(conversation)
        
        // Crear nueva conversación vacía
        createNewConversation()
        
        print("🗑️ Conversación eliminada")
    }
    
    /// Actualizar título de conversación
    func updateConversationTitle(_ newTitle: String) {
        guard let conversation = currentConversation else { return }
        
        conversation.title = newTitle
        try? SwiftDataService.shared.modelContext?.save()
        print("✏️ Título actualizado: \(newTitle)")
    }
}
