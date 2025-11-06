//
//  DiagnosisCameraView.swift
//  KaapehCopiloto2
//
//  Created by Cafe Swift Team on 05/11/25.
//

import SwiftUI
import PhotosUI

struct DiagnosisCameraView: View {
    let user: UserProfile
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: DiagnosisViewModel
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    
    init(user: UserProfile) {
        self.user = user
        _viewModel = State(initialValue: DiagnosisViewModel(user: user))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Fondo crema limpio (consistente con toda la app)
                Color(red: 0.98, green: 0.96, blue: 0.93)
                    .ignoresSafeArea()
                
                if let diagnosis = viewModel.currentDiagnosis {
                    DiagnosisResultView(
                        diagnosis: diagnosis,
                        onFeedback: { isCorrect in
                            Task {
                                await viewModel.submitFeedback(isCorrect: isCorrect)
                            }
                        }
                    )
                } else {
                    captureOptionsView
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color(red: 0.4, green: 0.26, blue: 0.13), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.white)
                            .font(.title2)
                    }
                    .accessibilityLabel("Cerrar")
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $viewModel.selectedImage) { image in
                    if let image = image {
                        Task {
                            await viewModel.processImage(image)
                        }
                    }
                }
            }
            .fullScreenCover(isPresented: $showingCamera) {
                CameraView { image in
                    if let image = image {
                        Task {
                            await viewModel.processImage(image)
                        }
                    }
                    showingCamera = false
                }
            }
        }
    }
    
    // MARK: - View Components
    
    private var captureOptionsView: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Instrucciones
            VStack(spacing: 20) {
                Image(systemName: "camera.metering.center.weighted")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundStyle(Color(red: 0.4, green: 0.26, blue: 0.13))
                
                Text("Captura tu planta")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 0.2, green: 0.13, blue: 0.07))
                
                Text("Toma una foto clara de la hoja para obtener un diagnóstico preciso")
                    .font(.body)
                    .foregroundStyle(Color(red: 0.4, green: 0.26, blue: 0.13))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .padding()
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: .black.opacity(0.1), radius: 12, y: 6)
            .padding(.horizontal, 24)
            
            Spacer()
            
            // Botones de captura
            VStack(spacing: 16) {
                Button {
                    showingCamera = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "camera.fill")
                            .font(.title2)
                        Text("Tomar Foto")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        LinearGradient(
                            colors: [Color(red: 0.2, green: 0.5, blue: 0.3), Color(red: 0.15, green: 0.4, blue: 0.25)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: Color(red: 0.2, green: 0.5, blue: 0.3).opacity(0.3), radius: 8, y: 4)
                }
                .accessibilityLabel("Tomar foto con cámara")
                
                Button {
                    showingImagePicker = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.title2)
                        Text("Elegir de Galería")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .foregroundStyle(Color(red: 0.4, green: 0.26, blue: 0.13))
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(red: 0.4, green: 0.26, blue: 0.13), lineWidth: 2)
                    )
                    .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
                }
                .accessibilityLabel("Elegir foto de galería")
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Supporting Views

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    let completion: (UIImage?) -> Void
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            guard let provider = results.first?.itemProvider else {
                parent.completion(nil)
                return
            }
            
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, error in
                    DispatchQueue.main.async {
                        self.parent.image = image as? UIImage
                        self.parent.completion(image as? UIImage)
                    }
                }
            }
        }
    }
}

#Preview {
    DiagnosisCameraView(user: UserProfile(userName: "productor_demo", role: "Productor"))
}
