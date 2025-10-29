//
//  ChatView.swift
//  KaapehCopiloto
//
//  Created by Cafe Swift on 28/10/25.
//

import SwiftUI

struct ChatView: View {
    @Environment(\.dismiss) var dismiss
    @State private var messages: [ChatMessage] = []
    @State private var inputText: String = ""
    @State private var isRecording: Bool = false
    
    let initialContext: String?
    
    init(initialContext: String? = nil) {
        self.initialContext = initialContext
    }
    
    var body: some View {
        VStack (spacing: 0) {
            // chat messages
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 15) {
                        ForEach(messages) { message in
                            ChatMessageView(message: message)
                                .id(message.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: messages.count) { _, _ in
                    if let lastMessage = messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            // input area
            VStack(spacing: 10) {
                Divider()
                
                HStack (spacing: 12) {
                    // voice button
                    Button(action: toggleRecording) {
                        Image(systemName: isRecording ? "mic.fill" : "mic")
                            .font(.title2)
                            .foregroundStyle(isRecording ? .red : .green)
                            .frame(width: 44, height: 44)
                            .background(isRecording ? Color.red.opacity(0.1) : Color.green.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .accessibilityLabel(isRecording ? "Detener grabación" : "Iniciar grabación")
                    
                    // text field
                    TextField("Escribe tu pregunta...", text: $inputText)
                        .textFieldStyle(.roundedBorder)
                        .accessibilityLabel("Campo de texto para preguntas")
                    
                    // send button
                    Button(action: sendMessage) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundStyle(inputText.isEmpty ? .gray : .green)
                    }
                    .disabled(inputText.isEmpty)
                    .accessibilityLabel("Enviar mensaje")
                }
                .padding(.horizontal)
                .padding(.bottom, 10)
            }
        }
        .navigationTitle("Copiloto IA")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let context = initialContext {
                loadInitialContext(context)
            } else {
                loadWelcomeMessage()
            }
        }
    }
    
    private func loadWelcomeMessage() {
        let welcomeMessage = ChatMessage(
            text: "¡Hola! Soy tu Copiloto Káapeh. Puedo ayudarte a entender problemas en tus plantas y darte recomendaciones. ¿En qué puedo asistirte hoy?",
            isFromUser: false
        )
        messages.append(welcomeMessage)
    }
    
    private func loadInitialContext(_ context: String) {
        let contextMessage = ChatMessage(
            text: "He detectado: \(context). Dejame exolicarte más sobre esto...",
            isFromUser: false
        )
        messages.append(contextMessage)
        
        // paso posterior integrar mlx aqui para generar explicacion
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            let explanation = getExplanationForIssue(context)
            let explanationMessage = ChatMessage(text: explanation, isFromUser: false)
            messages.append(explanationMessage)
        }
    }
    
    private func sendMessage() {
        guard !inputText.isEmpty else { return }
        
        // agregar mensaje del usuario
        let userMessage = ChatMessage(text: inputText, isFromUser: true)
        messages.append(userMessage)
        
        let query = inputText
        inputText = ""
        
        // integrar mlx para generar respuesta
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            let response = generateResponse(for: query)
            let aiMessage = ChatMessage(text: response, isFromUser: false)
            messages.append(aiMessage)
        }
    }
    
    private func toggleRecording() {
        isRecording.toggle()
        
        if isRecording {
            // implementar speechRecognition aqui
            print("Iniciando grabación...")
        } else {
            print("Deteniendo grabación...")
            // simular texto reconocido
            inputText = "¿Qué es la roya del café?"
        }
    }
    
    private func getExplanationForIssue(_ issue: String) -> String {
        switch issue {
        case "Roya del Café":
            return """
            La roya del café es causada por el hongo Hemileia vastatrix. Se caracteriza por manchas amarillo-anaranjadas en las hojas.
            
            **Plan de acción recomendado:**
            
            1. Podar las ramas más afectadas
            2. Mejorar la ventilación entre plantas
            3. Aplicar caldo bordelés (fungicida orgánico)
            4. Monitorear semanalmente
            
            ¿Necesitas más detalles sobre algún paso?
            """
        case "Deficiencia de Nitrógeno":
            return """
            Las hojas amarillentas indican falta de nitrógeno, esencial para el crecimiento.
            
            **Plan de acción recomendado:**
            
            1. Aplicar composta rica en nitrógeno
            2. Usar abono verde (leguminosas)
            3. Mantener el suelo con buen drenaje
            4. Revisar el pH del suelo
            
            ¿Quieres saber cómo preparar composta?
            """
        default:
            return "¿Qué te gustaría saber específicamente sobre \(issue)?"
        }
    }
    
    private func generateResponse(for query: String) -> String {
        // Respuestas simuladas
        let lowercaseQuery = query.lowercased()
        
        if lowercaseQuery.contains("roya") {
            return "La roya es uno de los problemas más comunes. Se combate mejor con prevención: mantén buena ventilación, poda regularmente y aplica fungicidas orgánicos como el caldo bordelés cada 15 días."
        } else if lowercaseQuery.contains("fertiliz") || lowercaseQuery.contains("abono") {
            return "Te recomiendo usar composta orgánica rica en nitrógeno. Puedes prepararla con residuos de café, estiércol y restos vegetales. Aplícala cada 3 meses alrededor de la base de la planta."
        } else if lowercaseQuery.contains("agua") || lowercaseQuery.contains("riego") {
            return "El café necesita riego regular pero sin encharcamiento. En época seca, riega 2-3 veces por semana. El suelo debe estar húmedo pero no saturado."
        } else {
            return "Esa es una buena pregunta. Basándome en las mejores prácticas agroecológicas para el café, te recomendaría consultar con un técnico especializado o revisar el historial de tus plantas para un diagnóstico más preciso."
        }
    }
}
    
// chat message model
struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isFromUser: Bool
    let timestamp = Date()
}

// chat message view
struct ChatMessageView: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isFromUser {
                Spacer()
                
            }
            
            VStack(alignment: message.isFromUser ? .trailing : .leading, spacing: 5) {
                Text(message.text)
                    .padding(12)
                    .background(message.isFromUser ? Color.green : Color(.systemGray5))
                    .foregroundStyle(message.isFromUser ? .white : .primary)
                    .cornerRadius(15)
                
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: 280, alignment: message.isFromUser ? .trailing : .leading)
            
            if !message.isFromUser {
                Spacer()
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(message.isFromUser ? "Tú" : "Copiloto"): \(message.text)")
    }
}


#Preview {
    NavigationStack {
        ChatView()
    }
}
