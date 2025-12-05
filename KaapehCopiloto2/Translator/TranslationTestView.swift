//
//  TranslationTestView.swift
//  KaapehCopiloto2
//
//  Vista de prueba para verificar el sistema de traducción
//  Created by Cafe Swift Team on 05/12/25.
//

import SwiftUI

struct TranslationTestView: View {
    @ObservedObject private var translator = KaapehTranslator.shared
    @State private var testPhrase = "Ajustes"
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Estado actual
                    statusCard
                    
                    // Control manual
                    controlCard
                    
                    // Prueba de frases
                    testPhrasesCard
                    
                    // Prueba personalizada
                    customTestCard
                    
                    // Estadísticas
                    statsCard
                }
                .padding()
            }
            .navigationTitle("Test de Traducción")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // MARK: - Status Card
    
    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Estado del Sistema", systemImage: "info.circle.fill")
                .font(.headline)
                .foregroundStyle(.blue)
            
            HStack {
                Text("Idioma actual:")
                    .foregroundStyle(.secondary)
                Spacer()
                Text(translator.isTzotzilActive ? "Tsotsil 🏔️" : "Español 🇲🇽")
                    .bold()
                    .foregroundStyle(translator.isTzotzilActive ? .green : .blue)
            }
            
            HStack {
                Text("Traducciones cargadas:")
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(translator.dictionary.count)")
                    .bold()
                    .foregroundStyle(.primary)
            }
            
            HStack {
                Text("Estado:")
                    .foregroundStyle(.secondary)
                Spacer()
                if translator.dictionary.count > 0 {
                    Label("Activo", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else {
                    Label("Sin vocabulario", systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
    }
    
    // MARK: - Control Card
    
    private var controlCard: some View {
        VStack(spacing: 16) {
            Label("Control Manual", systemImage: "slider.horizontal.3")
                .font(.headline)
                .foregroundStyle(.purple)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    translator.toggleLanguage()
                }
            } label: {
                HStack {
                    Image(systemName: "arrow.left.arrow.right.circle.fill")
                        .font(.title2)
                    
                    Text("Cambiar Idioma")
                        .font(.headline)
                    
                    Spacer()
                    
                    Text(translator.isTzotzilActive ? "→ Español" : "→ Tsotsil")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color.purple.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            
            HStack(spacing: 12) {
                Button {
                    translator.setLanguage("es")
                } label: {
                    VStack {
                        Text("🇲🇽")
                            .font(.largeTitle)
                        Text("Español")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(translator.isTzotzilActive ? Color(.systemGray6) : Color.blue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                
                Button {
                    translator.setLanguage("tsz")
                } label: {
                    VStack {
                        Text("🏔️")
                            .font(.largeTitle)
                        Text("Tsotsil")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(translator.isTzotzilActive ? Color.green.opacity(0.1) : Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
    }
    
    // MARK: - Test Phrases Card
    
    private var testPhrasesCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Frases de Prueba", systemImage: "text.bubble.fill")
                .font(.headline)
                .foregroundStyle(.orange)
            
            let testPhrases = [
                "Ajustes",
                "Accesibilidad",
                "Texto Grande",
                "Alto Contraste",
                "Idioma",
                "Cuenta",
                "Cerrar Sesión",
                "Diagnóstico",
                "Copiloto"
            ]
            
            ForEach(testPhrases, id: \.self) { phrase in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Original:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(phrase)
                            .font(.body)
                            .foregroundStyle(.primary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "arrow.right")
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(translator.isTzotzilActive ? "Tsotsil:" : "Español:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(translator.t(phrase))
                            .font(.body)
                            .bold()
                            .foregroundStyle(translator.hasTranslation(for: phrase) ? .green : .red)
                    }
                }
                .padding(12)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
    }
    
    // MARK: - Custom Test Card
    
    private var customTestCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Prueba Personalizada", systemImage: "text.cursor")
                .font(.headline)
                .foregroundStyle(.cyan)
            
            TextField("Escribe una frase...", text: $testPhrase)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)
            
            VStack(spacing: 8) {
                HStack {
                    Text("Traducción:")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(translator.t(testPhrase))
                        .bold()
                        .foregroundStyle(translator.hasTranslation(for: testPhrase) ? .green : .orange)
                }
                
                HStack {
                    Text("¿Existe?")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Image(systemName: translator.hasTranslation(for: testPhrase) ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(translator.hasTranslation(for: testPhrase) ? .green : .red)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
    }
    
    // MARK: - Stats Card
    
    private var statsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Estadísticas", systemImage: "chart.bar.fill")
                .font(.headline)
                .foregroundStyle(.indigo)
            
            Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 12) {
                GridRow {
                    Text("Vocabulario total:")
                        .foregroundStyle(.secondary)
                    Text("\(translator.dictionary.count) pares")
                        .bold()
                }
                
                GridRow {
                    Text("Modo actual:")
                        .foregroundStyle(.secondary)
                    Text(translator.isTzotzilActive ? "Traducción activa" : "Español (sin traducir)")
                        .bold()
                }
                
                GridRow {
                    Text("Búsqueda flexible:")
                        .foregroundStyle(.secondary)
                    Label("Habilitada", systemImage: "checkmark.circle")
                        .foregroundStyle(.green)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
    }
}

// MARK: - Preview

#Preview {
    TranslationTestView()
}
