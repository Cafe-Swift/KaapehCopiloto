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
    @Environment(AccessibilityManager.self) private var accessibilityManager
    
    init(user: UserProfile) {
        self.user = user
        _viewModel = State(initialValue: DiagnosisViewModel(user: user))
    }
    
    var body: some View {
        ZStack {
            // Fondo moderno degradado suave
            LinearGradient(
                colors: [
                    accessibilityManager.backgroundColor,
                    accessibilityManager.backgroundColor.opacity(0.95)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            if let diagnosis = viewModel.currentDiagnosis {
                DiagnosisResultView(
                    diagnosis: diagnosis,
                    onFeedback: { isCorrect in
                        Task {
                            await viewModel.submitFeedback(isCorrect: isCorrect)
                        }
                    },
                    onDismiss: {
                        viewModel.reset()
                    }
                )
            } else {
                captureOptionsView
            }
        }
        .taskGenerationToast(
            isShowing: $viewModel.showTaskGenerationToast,
            message: viewModel.taskGenerationMessage,
            isGenerating: viewModel.isGeneratingTasks,
            duration: 4.0
        )
        .sheet(isPresented: $showingImagePicker) {
            PhotoLibraryPicker(image: $viewModel.selectedImage) { image in
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
        .onAppear {
            // Solicitar permisos de ubicación al iniciar
            LocationService.shared.requestAuthorization()
        }
    }
    
    // MARK: - View Components
    
    private var captureOptionsView: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Tarjeta de instrucciones con efecto Liquid Glass
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [AppTheme.Colors.coffeeGreen, AppTheme.Colors.coffeeGreen.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                        .shadow(color: AppTheme.Colors.coffeeGreen.opacity(0.3), radius: 12, y: 6)
                    
                    Image(systemName: "camera.metering.center.weighted")
                        .font(.system(size: 48, weight: .semibold))
                        .foregroundStyle(.white)
                }
                
                Text("Captura tu Planta")
                    .font(.system(size: accessibilityManager.titleFontSize, weight: .bold, design: .rounded))
                    .foregroundStyle(accessibilityManager.primaryTextColor)
                
                Text("Toma una foto clara de la hoja para obtener un diagnóstico preciso")
                    .font(.body)
                    .foregroundStyle(accessibilityManager.secondaryTextColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.15), radius: 12, y: 6)
            )
            .padding(.horizontal, 24)
            
            Spacer()
            
            // Botones de captura modernos con Liquid Glass
            HStack(spacing: 24) {
                // Botón de cámara (circular grande)
                VStack(spacing: 12) {
                    Button {
                        showingCamera = true
                    } label: {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [AppTheme.Colors.coffeeGreen, AppTheme.Colors.coffeeGreen.opacity(0.7)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 80, height: 80)
                                .shadow(color: AppTheme.Colors.coffeeGreen.opacity(0.4), radius: 12, y: 6)
                            
                            Image(systemName: "camera.fill")
                                .font(.system(size: 36, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                    }
                    .sensoryFeedback(.impact(weight: .medium), trigger: showingCamera)
                    .accessibilityLabel("Tomar foto con cámara")
                    
                    Text("Cámara")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(accessibilityManager.primaryTextColor)
                }
                
                // Botón de galería (circular grande)
                VStack(spacing: 12) {
                    Button {
                        showingImagePicker = true
                    } label: {
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Circle()
                                        .stroke(AppTheme.Colors.coffeeBrown, lineWidth: 3)
                                )
                                .shadow(color: .black.opacity(0.15), radius: 12, y: 6)
                            
                            Image(systemName: "photo.on.rectangle")
                                .font(.system(size: 36, weight: .semibold))
                                .foregroundStyle(AppTheme.Colors.coffeeBrown)
                        }
                    }
                    .sensoryFeedback(.selection, trigger: showingImagePicker)
                    .accessibilityLabel("Elegir foto de galería")
                    
                    Text("Galería")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(accessibilityManager.primaryTextColor)
                }
            }
            .padding(.bottom, 60)
        }
    }
}

// MARK: - Supporting Views

struct PhotoLibraryPicker: UIViewControllerRepresentable {
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
        let parent: PhotoLibraryPicker
        
        init(_ parent: PhotoLibraryPicker) {
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
