//
//  DiagnosisCameraView.swift
//  KaapehCopiloto
//
//  Created by Cafe Swift on 28/10/25.
//

import SwiftUI
import PhotosUI

struct DiagnosisCameraView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppStateViewModel
    @State private var selectedImage: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var showingResult = false
    @State private var diagnosisResult: DiagnosisResult?
    @State private var isAnalyzing: Bool = false
    
    var body: some View {
        VStack (spacing:30) {
            // instrucciones
            VStack (spacing: 15) {
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 80))
                    .foregroundStyle(.green)
                    .accessibilityHidden(true)
                
                Text("Captura una imagen")
                    .font(.title2)
                    .fontWeight(.bold)
                    .accessibilityAddTraits(.isHeader)
                
                Text("Enfoca una hoja de tu planta de café para obtener un diagnóstico.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            .padding(.top, 40)
            
            // preview de la imagen seleccionada
            if let imageData = selectedImageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 300)
                    .cornerRadius(15)
                    .shadow(radius: 5)
                    .padding(.horizontal)
                    .accessibilityLabel("Imagen capturada de la planta")
            } else {
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 300)
                    .overlay(
                        VStack {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 50))
                                .foregroundStyle(.gray)
                            Text("Sin imagen")
                                .foregroundStyle(.gray)
                        }
                    )
                    .padding(.horizontal)
                    .accessibilityLabel("Vista previa vacía")
            }
            Spacer()
            
            // Botones de acción
            VStack (spacing: 15) {
                // Selector de foto
                PhotosPicker(selection: $selectedImage, matching: .images) {
                    Label("Seleccionar Foto", systemImage: "photo.on.rectangle")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .onChange(of: selectedImage) { _, newValue in
                    Task {
                        if let data = try? await newValue?.loadTransferable(type: Data.self) {
                            selectedImageData = data
                        }
                    }
                }
                .accessibilityLabel("Seleccionar foto de galeria")
                
                // boton analizar
                Button(action: analyzePlant) {
                    if isAnalyzing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        Label("Analizar Planta", systemImage: "wand.and.stars")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                }
                .background(selectedImageData != nil && !isAnalyzing ? Color.green : Color.gray)
                .cornerRadius(10)
                .disabled(selectedImageData == nil || isAnalyzing)
                .accessibilityLabel("Analizar planta")
                .accessibilityHint(selectedImageData != nil && !isAnalyzing ? "Toca para analizar la imagen capturada" : "Selecciona una imagen primero")
            }
            .padding(.horizontal)
            .padding(.bottom, 30)
        }
        .navigationTitle("Diagnóstico")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingResult) {
            if let result = diagnosisResult {
                DiagnosisResultView(result: result)
            }
        }
    }
    
    private func analyzePlant() {
        isAnalyzing = true
        
        // integrar coreML
        // simulacion de analisis con datos de prueba
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            // simulacion de resultado
            let mockResults = [
                DiagnosisResult(detectedIssue: "Roya del Café", confidence: 0.92, imagePath: nil),
                DiagnosisResult(detectedIssue: "Planta Sana", confidence: 0.87, imagePath: nil),
                DiagnosisResult(detectedIssue: "Deficiencia de Nitrogeno", confidence: 0.85, imagePath: nil)
            ]
            
            diagnosisResult = mockResults.randomElement()
            
            // guardar en db
            if let user = appState.currentUser, let result = diagnosisResult {
                do {
                    _ = try SwiftDataService.shared.saveDiagnosis(
                        detectedIssue: result.detectedIssue,
                        confidence: result.confidence,
                        imagePath: result.imagePath,
                        user: user
                    )
                } catch {
                    print("Error al guardar el diagnóstico: \(error)")
                }
            }
            
            isAnalyzing = false
            showingResult = true
        }
    }
}

// diagnosis result model
struct DiagnosisResult: Identifiable {
    let id = UUID()
    let detectedIssue: String
    let confidence: Double
    let imagePath: String?
}

#Preview {
    NavigationStack {
        DiagnosisCameraView()
            .environmentObject(AppStateViewModel())
    }
}
