//
//  ProducerMainView.swift
//  KaapehCopiloto
//
//  Created by Cafe Swift on 28/10/25.
//

import SwiftUI

struct ProducerMainView: View {
    @EnvironmentObject var appState: AppStateViewModel
    @State private var showingDiagnosis = false
    @State private var showingSettings = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // fondo
                LinearGradient (
                    gradient: Gradient(colors: [Color.green.opacity(0.1), Color.brown.opacity(0.05)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack (spacing: 30) {
                    // Saludo
                    VStack (spacing: 10) {
                        Text("Hola, Caficultor!")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .accessibilityAddTraits(.isHeader)
                        
                        Text("¿Qué deseas hacer hoy?")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 40)
                    
                    // Botones principales
                    VStack (spacing: 20) {
                        // Nuevo diagnóstico
                        NavigationLink(destination: DiagnosisCameraView()) {
                            MainActionButton(
                                icon: "camera.fill",
                                title: "Nuevo Diagnóstico",
                                subtitle: "Analiza tus plantas de café",
                                color: .green
                            )
                        }
                        .accessibilityLabel("Nuevo diagnóstico")
                        .accessibilityHint("Toca para tomar una foto y diagnosticar tu planta")
                        
                        // Hablar con Copiloto
                        NavigationLink(destination: ChatView()) {
                            MainActionButton (
                                icon: "mic.fill",
                                title: "Hablar con Copiloto",
                                subtitle: "Pregunta sobre tus cultivos",
                                color: .blue
                            )
                        }
                        .accessibilityLabel("Hablar con Copiloto")
                        .accessibilityHint("Toca para hacer preguntas al asistente inteligente")
                        
                        // historial
                        NavigationLink(destination: HistoryView()) {
                            MainActionButton (
                                icon: "clock.fill",
                                title: "Historial",
                                subtitle: "Revisa diagnósticos anteriores",
                                color: .orange
                            )
                        }
                        .accessibilityLabel("Historial")
                        .accessibilityHint("Toca para ver tus diagnósticos anteriores")
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.green)
                    }
                    .accessibilityLabel("Configuración")
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }
}

// main action button component
struct MainActionButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        HStack (spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundStyle(.white)
                .frame(width: 70, height: 70)
                .background(color)
                .clipShape(Circle())
                .accessibilityHidden(true)
            
            VStack (alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundStyle(.gray)
                .accessibilityHidden(true)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(radius: 3)
    }

}

#Preview {
    ProducerMainView()
        .environmentObject(AppStateViewModel())
}
