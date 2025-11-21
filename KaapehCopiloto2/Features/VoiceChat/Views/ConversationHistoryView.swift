//
//  ConversationHistoryView.swift
//  KaapehCopiloto2
//
//  Vista del historial de conversaciones con diseño unificado
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
        NavigationStack {
            ZStack {
                // Fondo dinámico basado en configuración de accesibilidad
                accessibilityManager.backgroundColor
                    .ignoresSafeArea()
                
                if conversations.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
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
                        .padding()
                    }
                }
            }
            .navigationTitle("Historial")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color(red: 0.4, green: 0.26, blue: 0.13), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(.white.opacity(0.9))
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.createNewConversation()
                        dismiss()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(.white.opacity(0.9))
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
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 64))
                .foregroundStyle(
                    LinearGradient(
                        colors: [AppTheme.Colors.coffeeBrown, AppTheme.Colors.espresso],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            
            Text("Sin Conversaciones")
                .font(.system(size: accessibilityManager.titleFontSize, weight: .bold))
                .foregroundStyle(accessibilityManager.primaryTextColor)
            
            Text("Tus conversaciones con el copiloto aparecerán aquí")
                .font(.system(size: accessibilityManager.bodyFontSize))
                .foregroundStyle(accessibilityManager.secondaryTextColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button {
                viewModel.createNewConversation()
                dismiss()
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Nueva Conversación")
                }
                .font(.system(size: accessibilityManager.bodyFontSize, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [AppTheme.Colors.coffeeBrown, AppTheme.Colors.espresso],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
            }
        }
        .padding()
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

// MARK: - Conversation Card

struct ConversationCard: View {
    let conversation: Conversation
    let accessibilityManager: AccessibilityManager
    let onSelect: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                // Icono con gradiente
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    AppTheme.Colors.coffeeBrown.opacity(0.2),
                                    AppTheme.Colors.espresso.opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: conversation.isVoiceChat ? "waveform.circle.fill" : "text.bubble.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [AppTheme.Colors.coffeeBrown, AppTheme.Colors.espresso],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
                
                // Información de la conversación
                VStack(alignment: .leading, spacing: 6) {
                    Text(conversation.title)
                        .font(.system(size: accessibilityManager.bodyFontSize, weight: .semibold))
                        .foregroundStyle(accessibilityManager.primaryTextColor)
                        .lineLimit(2)
                    
                    HStack(spacing: 8) {
                        Image(systemName: "clock")
                            .font(.system(size: 12))
                        Text(conversation.formattedDate)
                            .font(.system(size: accessibilityManager.captionFontSize))
                    }
                    .foregroundStyle(accessibilityManager.secondaryTextColor)
                    
                    // Indicador de modo de voz
                    if conversation.isVoiceChat {
                        HStack(spacing: 4) {
                            Image(systemName: "mic.fill")
                                .font(.system(size: 10))
                            Text("Voz")
                                .font(.system(size: accessibilityManager.captionFontSize - 2))
                        }
                        .foregroundStyle(AppTheme.Colors.coffeeGreen)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(AppTheme.Colors.coffeeGreen.opacity(0.15))
                        )
                    }
                }
                
                Spacer()
                
                // Botón de eliminar
                Button(action: onDelete) {
                    Image(systemName: "trash.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.red.opacity(0.8))
                }
                .buttonStyle(.plain)
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(accessibilityManager.secondaryTextColor.opacity(0.5))
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(accessibilityManager.cardBackgroundColor)
                    .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
            )
        }
        .buttonStyle(.plain)
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
