//
//  ConversationHistoryView.swift
//  KaapehCopiloto2
//
//  Vista del historial de conversaciones con diseño café/crema consistente
//

import SwiftUI

struct ConversationHistoryView: View {
    @ObservedObject var viewModel: VoiceChatViewModel
    @Environment(AccessibilityManager.self) private var accessibilityManager
    @Environment(\.dismiss) private var dismiss
    @State private var conversations: [Conversation] = []
    @State private var showDeleteAlert = false
    @State private var conversationToDelete: Conversation?
    
    var body: some View {
        ZStack {
            accessibilityManager.backgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                customHeader
                
                if conversations.isEmpty {
                    emptyStateView
                } else {
                    conversationsList
                }
            }
        }
        .onAppear {
            loadConversations()
        }
        .alert("Eliminar Conversación", isPresented: $showDeleteAlert) {
            Button("Cancelar", role: .cancel) {}
            Button("Eliminar", role: .destructive) {
                if let conv = conversationToDelete {
                    deleteConversation(conv)
                }
            }
        } message: {
            Text("¿Estás seguro de que deseas eliminar esta conversación?")
        }
    }
    
    // MARK: - Custom Header
    
    private var customHeader: some View {
        VStack(spacing: 0) {
            HStack {
                // Botón Cerrar
                Button(action: { dismiss() }) {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                        Text("Cerrar")
                            .font(.system(size: accessibilityManager.bodyFontSize, weight: .medium))
                    }
                    .foregroundColor(AppTheme.Colors.coffeeBrown)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(AppTheme.Colors.creamBrown.opacity(0.5))
                    )
                }
                
                Spacer()
                
                // Botón Nueva Conversación
                Button(action: {
                    viewModel.createNewConversation()
                    dismiss()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 18))
                        Text("Nueva")
                            .font(.system(size: accessibilityManager.bodyFontSize, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [AppTheme.Colors.coffeeBrown, AppTheme.Colors.espresso],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                    .shadow(color: AppTheme.Colors.coffeeBrown.opacity(0.3), radius: 8, y: 4)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 12)
            
            // Título
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Historial de Conversaciones")
                        .font(.system(size: accessibilityManager.titleFontSize, weight: .bold))
                        .foregroundColor(accessibilityManager.primaryTextColor)
                    
                    Text("\(conversations.count) conversación\(conversations.count == 1 ? "" : "es")")
                        .font(.system(size: accessibilityManager.captionFontSize))
                        .foregroundColor(accessibilityManager.secondaryTextColor)
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
            
            // Divider con gradiente
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            AppTheme.Colors.coffeeBrown.opacity(0.3),
                            AppTheme.Colors.coffeeBrown.opacity(0.1),
                            AppTheme.Colors.coffeeBrown.opacity(0.3)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
        }
        .background(
            accessibilityManager.cardBackgroundColor
                .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
        )
    }
    
    // MARK: - Conversations List
    
    private var conversationsList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(conversations) { conversation in
                    ConversationCard(
                        conversation: conversation,
                        accessibilityManager: accessibilityManager,
                        onSelect: {
                            viewModel.loadConversation(conversation)
                            dismiss()
                        },
                        onDelete: {
                            conversationToDelete = conversation
                            showDeleteAlert = true
                        }
                    )
                }
            }
            .padding(20)
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            // Icono con gradiente café
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                AppTheme.Colors.creamBrown.opacity(0.3),
                                AppTheme.Colors.lightBrown.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Image(systemName: "bubble.left.and.bubble.right")
                    .font(.system(size: 56, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [AppTheme.Colors.coffeeBrown, AppTheme.Colors.espresso],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            .padding(.top, 60)
            
            VStack(spacing: 12) {
                Text("Sin Conversaciones")
                    .font(.system(size: accessibilityManager.titleFontSize, weight: .bold))
                    .foregroundStyle(accessibilityManager.primaryTextColor)
                
                Text("Tus conversaciones con el copiloto\naparecerán aquí")
                    .font(.system(size: accessibilityManager.bodyFontSize))
                    .foregroundStyle(accessibilityManager.secondaryTextColor)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            
            // Botón con estilo café
            Button {
                viewModel.createNewConversation()
                dismiss()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                    Text("Iniciar Nueva Conversación")
                        .font(.system(size: accessibilityManager.bodyFontSize, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 28)
                .padding(.vertical, 16)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [AppTheme.Colors.coffeeBrown, AppTheme.Colors.espresso],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
                .shadow(color: AppTheme.Colors.coffeeBrown.opacity(0.4), radius: 12, y: 6)
            }
            .padding(.top, 12)
            
            Spacer()
        }
        .padding(.horizontal, 40)
    }
    
    // MARK: - Data Management
    
    private func loadConversations() {
        conversations = ConversationService.shared.fetchAllConversations()
    }
    
    private func deleteConversation(_ conversation: Conversation) {
        ConversationService.shared.delete(conversation)
        conversations.removeAll { $0.id == conversation.id }
        
        // Si se eliminó la conversación activa, crear una nueva
        if viewModel.currentConversation?.id == conversation.id {
            viewModel.createNewConversation()
        }
    }
}

// MARK: - Conversation Card (Rediseñada)

struct ConversationCard: View {
    let conversation: Conversation
    let accessibilityManager: AccessibilityManager
    let onSelect: () -> Void
    let onDelete: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [
                                    AppTheme.Colors.creamBrown.opacity(0.6),
                                    AppTheme.Colors.lightBrown.opacity(0.3)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 64, height: 64)
                    
                    // Icono principal
                    Image(systemName: conversation.isVoiceChat ? "waveform.circle.fill" : "text.bubble.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [AppTheme.Colors.coffeeBrown, AppTheme.Colors.espresso],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    // Título
                    Text(conversation.title)
                        .font(.system(size: accessibilityManager.bodyFontSize, weight: .semibold))
                        .foregroundStyle(accessibilityManager.primaryTextColor)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    // Fecha y hora con nuevo estilo
                    HStack(spacing: 6) {
                        Image(systemName: "clock")
                            .font(.system(size: 11))
                        Text(conversation.formattedDate)
                            .font(.system(size: accessibilityManager.captionFontSize))
                    }
                    .foregroundStyle(accessibilityManager.secondaryTextColor)
                    
                    if conversation.isVoiceChat {
                        HStack(spacing: 5) {
                            Image(systemName: "mic.fill")
                                .font(.system(size: 10, weight: .semibold))
                            Text("Conversación de Voz")
                                .font(.system(size: accessibilityManager.captionFontSize - 2, weight: .medium))
                        }
                        .foregroundStyle(AppTheme.Colors.coffeeGreen)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(AppTheme.Colors.coffeeGreen.opacity(0.12))
                        )
                        .overlay(
                            Capsule()
                                .strokeBorder(AppTheme.Colors.coffeeGreen.opacity(0.3), lineWidth: 1)
                        )
                    }
                }
                
                Spacer(minLength: 8)
                
                Button(action: onDelete) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.Colors.creamBrown.opacity(0.5))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: "trash.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.red.opacity(0.8), .red.opacity(0.6)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(accessibilityManager.cardBackgroundColor)
                    .shadow(
                        color: isPressed ? AppTheme.Colors.coffeeBrown.opacity(0.2) : .black.opacity(0.06),
                        radius: isPressed ? 4 : 10,
                        y: isPressed ? 2 : 4
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                AppTheme.Colors.coffeeBrown.opacity(0.1),
                                AppTheme.Colors.creamBrown.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = false
                    }
                }
        )
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var viewModel = VoiceChatViewModel(
        ragService: RAGService(
            foundationModelsService: FoundationModelsService(),
            embeddingService: EmbeddingService(),
            vectorDatabase: VectorDatabaseService.shared
        )
    )
    
    return ConversationHistoryView(viewModel: viewModel)
        .environment(AccessibilityManager.shared)
}
