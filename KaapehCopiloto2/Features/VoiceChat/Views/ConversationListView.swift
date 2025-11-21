//
//  ConversationListView.swift
//  KaapehCopiloto2
//
//  Vista para mostrar el historial de conversaciones
//

import SwiftUI

struct ConversationListView: View {
    @ObservedObject var viewModel: VoiceChatViewModel
    @Binding var isPresented: Bool
    @State private var conversations: [Conversation] = []
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(conversations) { conversation in
                Button(action: {
                    viewModel.loadConversation(conversation)
                    isPresented = false
                }) {
                    VStack(alignment: .leading) {
                        Text(conversation.title)
                            .font(.headline)
                        Text(conversation.formattedDate)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                }
                .onDelete(perform: deleteConversations)
            }
            .navigationTitle("Historial de Conversaciones")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button("Nueva") {
                        viewModel.createNewConversation()
                        isPresented = false
                    }
                }
            }
            .onAppear {
                loadConversations()
            }
        }
    }
    
    private func loadConversations() {
        conversations = ConversationService.shared.fetchAllConversations()
    }
    
    private func deleteConversations(at offsets: IndexSet) {
        for index in offsets {
            let conversation = conversations[index]
            ConversationService.shared.delete(conversation)
        }
        conversations.remove(atOffsets: offsets)
    }
}
