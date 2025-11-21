//
//  MultimodalChatView.swift
//  KaapehCopiloto2
//
//  Vista unificada de chat multimodal (texto + voz + historial)
//

import SwiftUI
import AVFoundation

struct MultimodalChatView: View {
    @StateObject private var viewModel: VoiceChatViewModel
    @State private var inputText: String = ""
    @State private var showConversationList = false
    @Environment(AccessibilityManager.self) private var accessibilityManager
    
    init() {
        // Inicializar el ViewModel con un nuevo servicio RAG
        _viewModel = StateObject(wrappedValue: VoiceChatViewModel(ragService: RAGService()))
    }
    
    var body: some View {
        ZStack {
            accessibilityManager.backgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // MARK: - Header con Historial
                headerView
                
                // MARK: - Área de mensajes
                messagesArea
                
                // MARK: - Barra de entrada
                inputBar
            }
        }
        .navigationTitle("Copiloto Káapeh")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(Color(red: 0.4, green: 0.26, blue: 0.13), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $showConversationList) {
            ConversationListView(viewModel: viewModel, isPresented: $showConversationList)
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            if viewModel.state != .idle {
                HStack(spacing: 8) {
                    Image(systemName: viewModel.stateIcon)
                        .foregroundStyle(viewModel.stateColor)
                        .font(.system(size: 20))
                    
                    Text(viewModel.state.description)
                        .font(.system(size: accessibilityManager.captionFontSize))
                        .foregroundColor(viewModel.stateColor)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(accessibilityManager.cardBackgroundColor)
                        .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
                )
            }
            
            Spacer()
            
            // Botón de historial - Estilo consistente con el resto de la app
            Button(action: {
                showConversationList = true
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "clock.arrow.circlepath")
                    Text("Historial")
                }
                .font(.system(size: accessibilityManager.bodyFontSize))
                .foregroundStyle(accessibilityManager.primaryTextColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(accessibilityManager.cardBackgroundColor)
                        .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
                )
            }
        }
        .padding()
    }
    
    // MARK: - Messages Area
    private var messagesArea: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.messages) { message in
                        MessageBubbleView(
                            message: message,
                            accessibilityManager: accessibilityManager
                        )
                        .id(message.id)
                    }
                    
                    if viewModel.state == .listening && !viewModel.volatileTranscript.isEmpty {
                        VoiceTranscriptView(
                            text: viewModel.volatileTranscript,
                            accessibilityManager: accessibilityManager
                        )
                    }
                }
                .padding()
            }
            .onChange(of: viewModel.messages.count) {
                if let lastMessage = viewModel.messages.last {
                    withAnimation(.smooth) {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }
    
    // MARK: - Input Bar
    private var inputBar: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.gray.opacity(0.3))
            
            HStack(spacing: 12) {
                // Botón de voz con animación
                Button(action: {
                    viewModel.handleUserInterrupt()
                }) {
                    Image(systemName: viewModel.stateIcon)
                        .font(.system(size: 24))
                        .foregroundStyle(
                            LinearGradient(
                                colors: viewModel.state == .idle
                                    ? [AppTheme.Colors.coffeeGreen, AppTheme.Colors.coffeeBrown]
                                    : [viewModel.stateColor, viewModel.stateColor],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(accessibilityManager.cardBackgroundColor)
                                .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
                        )
                }
                .accessibilityLabel("Botón de voz")
                .accessibilityHint(viewModel.state == .idle ? "Toca para activar el modo de voz" : "Toca para desactivar el modo de voz")
                
                // Campo de texto con botón enviar
                HStack(spacing: 8) {
                    TextField("Escribe tu mensaje...", text: $inputText)
                        .font(.system(size: accessibilityManager.bodyFontSize))
                        .foregroundColor(accessibilityManager.primaryTextColor)
                        .disabled(viewModel.state == .listening)
                        .submitLabel(.send)
                        .onSubmit {
                            sendMessage()
                        }
                    
                    // Botón enviar (aparece cuando hay texto)
                    if !inputText.isEmpty {
                        Button(action: {
                            sendMessage()
                        }) {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [AppTheme.Colors.coffeeGreen, AppTheme.Colors.coffeeBrown],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                        .disabled(viewModel.state == .listening)
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 22)
                        .fill(accessibilityManager.cardBackgroundColor)
                        .shadow(color: .black.opacity(0.06), radius: 3, y: 1)
                )
            }
            .padding()
            .background(
                accessibilityManager.backgroundColor
                    .shadow(color: .black.opacity(0.08), radius: 5, y: -2)
            )
        }
    }
    
    // MARK: - Helpers
    private func sendMessage() {
        let message = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty else { return }
        
        inputText = ""
        
        Task {
            await viewModel.sendMessage(message)
        }
    }
}

// MARK: - Message Bubble View
struct MessageBubbleView: View {
    let message: ChatMessage
    let accessibilityManager: AccessibilityManager
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            if !message.isFromUser {
                // Avatar del asistente - icono de cerebro en círculo
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 24))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [AppTheme.Colors.coffeeBrown, AppTheme.Colors.espresso],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(accessibilityManager.cardBackgroundColor)
                            .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
                    )
            } else {
                Spacer(minLength: 60)
            }
            
            VStack(alignment: message.isFromUser ? .trailing : .leading, spacing: 6) {
                // Contenido del mensaje con mejor contraste
                Text(message.content)
                    .font(.system(size: accessibilityManager.bodyFontSize))
                    .foregroundColor(message.isFromUser ? .white : accessibilityManager.primaryTextColor)
                    .padding(14)
                    .background(
                        Group {
                            if message.isFromUser {
                                // Mensajes del usuario: gradiente verde-café del tema
                                LinearGradient(
                                    colors: [AppTheme.Colors.coffeeGreen, AppTheme.Colors.coffeeBrown],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            } else {
                                // Mensajes del asistente: fondo de tarjeta con sombra
                                accessibilityManager.cardBackgroundColor
                            }
                        }
                    )
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
                
                // Metadata - hora y fuentes
                HStack(spacing: 4) {
                    Text(message.formattedTime)
                        .font(.system(size: accessibilityManager.captionFontSize))
                        .foregroundStyle(accessibilityManager.secondaryTextColor)
                    
                    // Indicador de fuentes (si existen)
                    if let sources = message.sources, !sources.isEmpty {
                        Image(systemName: "book.closed.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(AppTheme.Colors.coffeeBrown)
                    }
                }
                .padding(.horizontal, 8)
            }
            
            if message.isFromUser {
                // Avatar del usuario - persona en círculo
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [AppTheme.Colors.coffeeGreen, AppTheme.Colors.coffeeGreen.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(accessibilityManager.cardBackgroundColor)
                            .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
                    )
            } else {
                Spacer(minLength: 60)
            }
        }
    }
}

// MARK: - Voice Transcript View (para mostrar texto mientras se escucha)
struct VoiceTranscriptView: View {
    let text: String
    let accessibilityManager: AccessibilityManager
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "waveform")
                .font(.system(size: 20))
                .foregroundStyle(
                    LinearGradient(
                        colors: [AppTheme.Colors.coffeeGreen, AppTheme.Colors.coffeeBrown],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            
            Text(text)
                .font(.system(size: accessibilityManager.bodyFontSize))
                .foregroundStyle(accessibilityManager.secondaryTextColor)
                .italic()
            
            Spacer()
            
            ProgressView()
                .tint(AppTheme.Colors.coffeeGreen)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(accessibilityManager.cardBackgroundColor)
                .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
        )
        .padding(.horizontal)
    }
}

#Preview {
    NavigationStack {
        MultimodalChatView()
            .environment(AccessibilityManager.shared)
    }
}
