//
//  VoiceChatView.swift
//  KaapehCopiloto2
//
//  Vista completa de Voice Chat con State Machine visual
//

import SwiftUI
import AVFAudio

struct VoiceChatView: View {
    @StateObject private var viewModel: VoiceChatViewModel
    @State private var showingSettings = false
    @State private var showingConversationList = false
    
    // MARK: - Initialization
    init(ragService: RAGService, conversation: Conversation? = nil) {
        _viewModel = StateObject(wrappedValue: VoiceChatViewModel(
            ragService: ragService,
            conversation: conversation
        ))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Chat history
                    chatScrollView
                    
                    // Voice control panel
                    voiceControlPanel
                        .padding()
                        .background(.ultraThinMaterial)
                }
            }
            .navigationTitle(viewModel.currentConversation?.title ?? "🎙️ Chat por Voz")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showingConversationList = true }) {
                        Image(systemName: "list.bullet")
                            .font(.system(size: 17))
                            .accessibilityLabel("Historial")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { viewModel.createNewConversation() }) {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 17))
                            .accessibilityLabel("Nuevo chat")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gear")
                            .font(.system(size: 17))
                            .accessibilityLabel("Configuración")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                VoiceSettingsView(ttsManager: viewModel.ttsManager)
            }
            .sheet(isPresented: $showingConversationList) {
                ConversationListView(viewModel: viewModel, isPresented: $showingConversationList)
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            }
            .onDisappear {
                viewModel.cleanup()
            }
        }
    }
    
    // MARK: - Chat History
    
    private var chatScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.messages) { message in
                        ChatBubbleView(message: message)
                            .id(message.id)
                    }
                }
                .padding()
            }
            .onChange(of: viewModel.messages.count) { _, _ in
                // Auto-scroll al último mensaje
                if let lastMessage = viewModel.messages.last {
                    withAnimation {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }
    
    // MARK: - Voice Control Panel
    
    private var voiceControlPanel: some View {
        VStack(spacing: 20) {
            // State indicator
            stateIndicator
            
            // Live transcript (volatile)
            if viewModel.state == .listening && !viewModel.speechManager.volatileTranscript.isEmpty {
                Text(viewModel.speechManager.volatileTranscript)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            // Main voice button
            voiceButton
        }
    }
    
    private var stateIndicator: some View {
        HStack(spacing: 8) {
            // Animated pulse for listening state
            if viewModel.state == .listening {
                Circle()
                    .fill(Color.red)
                    .frame(width: 8, height: 8)
                    .scaleEffect(viewModel.state == .listening ? 1.5 : 1.0)
                    .opacity(viewModel.state == .listening ? 0.5 : 1.0)
                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: viewModel.state)
            }
            
            Text(viewModel.state.description)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(viewModel.stateColor)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(
            Capsule()
                .fill(viewModel.stateColor.opacity(0.15))
        )
    }
    
    private var voiceButton: some View {
        Button(action: {
            viewModel.handleUserInterrupt()
        }) {
            ZStack {
                // Background circle
                Circle()
                    .fill(viewModel.stateColor.opacity(0.2))
                    .frame(width: 100, height: 100)
                
                // Icon
                Image(systemName: viewModel.stateIcon)
                    .font(.system(size: 40))
                    .foregroundColor(viewModel.stateColor)
                    .symbolEffect(.pulse, options: .repeating, value: viewModel.state == .listening)
            }
        }
        .disabled(!viewModel.canInterrupt && viewModel.state != .idle)
        .accessibilityLabel(voiceButtonAccessibilityLabel)
        .accessibilityInputLabels(["Grabar", "Hablar", "Micrófono", "Escuchar"])
        .accessibilityHint(voiceButtonAccessibilityHint)
    }
    
    // MARK: - Accessibility
    
    private var voiceButtonAccessibilityLabel: String {
        switch viewModel.state {
        case .idle:
            return "Iniciar chat por voz"
        case .listening:
            return "Detener grabación"
        case .processingResponse:
            return "Procesando respuesta"
        case .speaking:
            return "Detener reproducción"
        }
    }
    
    private var voiceButtonAccessibilityHint: String {
        switch viewModel.state {
        case .idle:
            return "Toca para activar el micrófono y comenzar a hablar"
        case .listening:
            return "Toca para detener la grabación y enviar tu mensaje"
        case .processingResponse:
            return "Esperando respuesta del asistente"
        case .speaking:
            return "Toca para interrumpir al asistente y volver a hablar"
        }
    }
}

// MARK: - Chat Bubble View
struct ChatBubbleView: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isFromUser {
                Spacer(minLength: 60)
            }
            
            VStack(alignment: message.isFromUser ? .trailing : .leading, spacing: 8) {
                // Message content
                Text(message.content)
                    .padding(12)
                    .background(message.isFromUser ? Color.blue : Color(.systemGray5))
                    .foregroundColor(message.isFromUser ? .white : .primary)
                    .cornerRadius(16)
                    .accessibilityLabel(accessibilityLabel)
                    .accessibilityAddTraits(message.isFromUser ? [.isStaticText] : [.isStaticText, .playsSound])
                
                // Metadata (sources, performance)
                if let sources = message.sources, !sources.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("📚 Fuentes:")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        ForEach(sources, id: \.self) { source in
                            Text("• \(source)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 8)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Fuentes consultadas: \(sources.joined(separator: ", "))")
                }
                
                // Performance stats
                if let metadata = message.ragMetadata {
                    Text(metadata.performanceSummary)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .accessibilityLabel("Estadísticas de rendimiento: \(metadata.performanceSummary)")
                }
                
                // Timestamp
                Text(message.formattedTime)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .accessibilityHidden(true) // El timestamp no es crucial para VoiceOver
            }
            
            if !message.isFromUser {
                Spacer(minLength: 60)
            }
        }
        .accessibilityElement(children: .contain)
    }
    
    private var accessibilityLabel: String {
        if message.isFromUser {
            return "Tú dijiste: \(message.content)"
        } else {
            let sourcesInfo = message.sources?.isEmpty == false ?
                " Basado en \(message.sources!.count) fuentes." : ""
            return "Asistente respondió: \(message.content)\(sourcesInfo)"
        }
    }
}

// MARK: - Voice Settings View
struct VoiceSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var ttsManager: TextToSpeechManager
    
    @State private var rate: Float = 0.52
    @State private var pitch: Float = 1.0
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Velocidad de Voz") {
                    VStack {
                        Slider(value: $rate, in: 0.3...0.7, step: 0.01)
                            .onChange(of: rate) { _, newValue in
                                ttsManager.setRate(newValue)
                            }
                        
                        HStack {
                            Text("Lento")
                                .font(.caption)
                            Spacer()
                            Text(String(format: "%.2f", rate))
                                .font(.caption)
                                .fontWeight(.bold)
                            Spacer()
                            Text("Rápido")
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }
                }
                
                Section("Tono de Voz") {
                    VStack {
                        Slider(value: $pitch, in: 0.8...1.2, step: 0.05)
                            .onChange(of: pitch) { _, newValue in
                                ttsManager.setPitch(newValue)
                            }
                        
                        HStack {
                            Text("Grave")
                                .font(.caption)
                            Spacer()
                            Text(String(format: "%.2f", pitch))
                                .font(.caption)
                                .fontWeight(.bold)
                            Spacer()
                            Text("Agudo")
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }
                }
                
                // Personal Voice section
                if ttsManager.personalVoiceAuthorized && ttsManager.hasPersonalVoices {
                    Section("Voz Personal") {
                        ForEach(ttsManager.availablePersonalVoices, id: \.identifier) { voice in
                            Button(action: {
                                ttsManager.selectPersonalVoice(withIdentifier: voice.identifier)
                            }) {
                                HStack {
                                    Text(voice.name)
                                    Spacer()
                                    if ttsManager.selectedVoiceID == voice.identifier {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                        }
                        
                        Button("Usar voz del sistema") {
                            ttsManager.clearPersonalVoiceSelection()
                        }
                        .foregroundColor(.secondary)
                    }
                } else if !ttsManager.personalVoiceAuthorized {
                    Section("Voz Personal") {
                        Button("Activar Personal Voice") {
                            Task {
                                await ttsManager.checkPersonalVoiceAvailability()
                            }
                        }
                    }
                }
                
                Section {
                    Button("Probar Voz") {
                        ttsManager.speak("Hola, soy tu asistente Káapeh. ¿En qué puedo ayudarte hoy?")
                    }
                }
            }
            .navigationTitle("Configuración de Voz")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Listo") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    VoiceChatView(ragService: RAGService())
}
