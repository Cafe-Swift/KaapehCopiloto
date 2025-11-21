//
//  VoiceChatViewModel.swift
//  KaapehCopiloto2
//
//  ViewModel para Voice Chat con State Machine completo
//  CORREGIDO: Sin loop automático, botón toggle para voz
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
                print("✅ TTS terminado")
                // NO volvemos a escuchar automáticamente
                // El usuario debe presionar el botón nuevamente
                self?.transition(to: .idle)
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
    
    // MARK: - Processing (RAG)
    
    private func handleUserTranscript(_ transcript: String) async {
        let cleanedTranscript = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !cleanedTranscript.isEmpty else {
            print("⚠️ Transcript vacío, volviendo a idle")
            transition(to: .idle)
            return
        }
        
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
            // Presionar mientras habla → INTERRUMPIR
            print("⏹️ Usuario interrumpió TTS")
            ttsManager.stopSpeaking()
            transition(to: .idle)
        }
    }
    
    /// Detener todos los servicios activos
    private func stopAllServices() {
        stopListening()
        ttsManager.stopSpeaking()
        volatileTranscript = ""
    }
    
    /// Maneja errores de manera centralizada
    private func handleError(_ error: Error) {
        errorMessage = "❌ " + error.localizedDescription
        print("🚨 Error en VoiceChat: \(error.localizedDescription)")
        
        // Agregar mensaje de error visible en la UI
        let errorChatMessage = ChatMessage(
            content: "⚠️ Error: \(error.localizedDescription)",
            isFromUser: false
        )
        messages.append(errorChatMessage)
        saveMessages()
        
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
