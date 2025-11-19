//
//  CopilotChatView.swift
//  KaapehCopiloto2
//
//  Created by Cafe Swift Team on 06/11/25.
//

import SwiftUI

struct CopilotChatView: View {
    @State private var viewModel: CopilotViewModel?
    @FocusState private var isInputFocused: Bool
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        ZStack {
            Color(red: 0.95, green: 0.92, blue: 0.88)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel?.messages ?? [], id: \.id) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                            }
                            
                            if viewModel?.isProcessing == true {
                                TypingIndicator()
                            }
                        }
                        .padding()
                    }
                    .onChange(of: viewModel?.messages.count ?? 0) { oldValue, newValue in
                        if let lastMessage = viewModel?.messages.last {
                            withAnimation(.smooth) {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                inputBar
            }
        }
        .navigationTitle("Copiloto Káapeh")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color(red: 0.4, green: 0.26, blue: 0.13), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(role: .destructive) {
                        viewModel?.clearChat()
                    } label: {
                        Label("Limpiar Chat", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle.fill")
                        .foregroundStyle(.white)
                        .font(.title3)
                }
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = CopilotViewModel(modelContext: modelContext)
            }
        }
    }
    
    private var inputBar: some View {
        HStack(spacing: 12) {
            // Voice button
            Button {
                // Voice input - Sprint 2
            } label: {
                Image(systemName: "mic.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 50, height: 50)
                    .background(
                        LinearGradient(
                            colors: [Color(red: 0.2, green: 0.5, blue: 0.3), Color(red: 0.15, green: 0.4, blue: 0.25)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
            }
            .accessibilityLabel("Entrada por voz")
            .accessibilityHint("Toca para hablar con el copiloto")
            
            // Text input
            TextField("Escribe tu pregunta...", text: Binding(
                get: { viewModel?.currentInput ?? "" },
                set: { viewModel?.currentInput = $0 }
            ), axis: .vertical)
                .textFieldStyle(.plain)
                .padding(14)
                .background(Color.white)
                .foregroundStyle(.black)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
                .focused($isInputFocused)
                .lineLimit(1...5)
                .font(.body)
            
            // Send button
            Button {
                // ✅ Ocultar teclado PRIMERO para evitar congelamiento
                isInputFocused = false
                
                Task {
                    await viewModel?.sendMessage()
                }
            } label: {
                let isEmpty = viewModel?.currentInput.isEmpty ?? true
                Image(systemName: isEmpty ? "paperplane" : "paperplane.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 50, height: 50)
                    .background {
                        if isEmpty {
                            Color.gray.opacity(0.3)
                        } else {
                            LinearGradient(
                                colors: [Color(red: 0.6, green: 0.4, blue: 0.2), Color(red: 0.4, green: 0.26, blue: 0.13)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        }
                    }
                    .clipShape(Circle())
                    .shadow(color: isEmpty ? .clear : .black.opacity(0.2), radius: 8, y: 4)
            }
            .disabled(viewModel?.currentInput.isEmpty ?? true)
            .accessibilityLabel("Enviar mensaje")
            .animation(.easeInOut, value: viewModel?.currentInput.isEmpty ?? true)
        }
        .padding(16)
        .background(Color(red: 0.98, green: 0.96, blue: 0.94))
        .shadow(color: .black.opacity(0.1), radius: 10, y: -5)
    }
}

// MARK: - Message Bubble
struct MessageBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if message.isFromUser {
                Spacer(minLength: 60)
            } else {
                // Avatar del copiloto para mensajes del sistema
                Image(systemName: "leaf.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Color(red: 0.2, green: 0.5, blue: 0.3))
                    .frame(width: 36, height: 36)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.1), radius: 4)
            }
            
            VStack(alignment: message.isFromUser ? .trailing : .leading, spacing: 6) {
                Text(message.content)
                    .font(.body)
                    .foregroundStyle(message.isFromUser ? .white : .black)
                    .padding(16)
                    .background {
                        if message.isFromUser {
                            // Mensajes del usuario
                            LinearGradient(
                                colors: [Color(red: 0.4, green: 0.26, blue: 0.13), Color(red: 0.35, green: 0.21, blue: 0.10)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        } else {
                            // Mensajes del copiloto
                            Color.white
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                
                Text(message.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
            }
            .frame(maxWidth: .infinity * 0.75, alignment: message.isFromUser ? .trailing : .leading)
            
            if !message.isFromUser {
                Spacer(minLength: 60)
            } else {
                // Avatar del usuario
                Image(systemName: "person.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Color(red: 0.4, green: 0.26, blue: 0.13))
                    .frame(width: 36, height: 36)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.1), radius: 4)
            }
        }
    }
}

// MARK: - Typing Indicator
struct TypingIndicator: View {
    @State private var animationPhase = 0
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "leaf.circle.fill")
                .font(.title2)
                .foregroundStyle(Color(red: 0.2, green: 0.5, blue: 0.3))
                .frame(width: 36, height: 36)
                .background(Color.white)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.1), radius: 4)
            
            HStack(spacing: 8) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color(red: 0.2, green: 0.5, blue: 0.3))
                        .frame(width: 10, height: 10)
                        .scaleEffect(animationPhase == index ? 1.3 : 1.0)
                        .animation(
                            .easeInOut(duration: 0.6)
                                .repeatForever()
                                .delay(Double(index) * 0.2),
                            value: animationPhase
                        )
                }
            }
            .padding(16)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
            
            Spacer(minLength: 60)
        }
        .onAppear {
            animationPhase = 1
        }
    }
}

#Preview {
    NavigationStack {
        CopilotChatView()
    }
}
