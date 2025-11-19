//
//  CameraService.swift
//  KaapehCopiloto2
//
//  Servicio para captura y selección de imágenes
//

import SwiftUI
import PhotosUI
import AVFoundation
import Combine

/// Fuente de origen de la imagen
enum ImageSource {
    case camera
    case photoLibrary
}

/// Error de cámara
enum CameraError: LocalizedError {
    case cameraNotAvailable
    case photoLibraryNotAvailable
    case permissionDenied
    case captureError
    
    var errorDescription: String? {
        switch self {
        case .cameraNotAvailable:
            return "La cámara no está disponible en este dispositivo"
        case .photoLibraryNotAvailable:
            return "La biblioteca de fotos no está disponible"
        case .permissionDenied:
            return "Necesitamos permiso para acceder a la cámara o fotos"
        case .captureError:
            return "Error al capturar la imagen"
        }
    }
}

/// Servicio para gestión de imágenes
@MainActor
class CameraService: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Indica si la cámara está disponible
    @Published var isCameraAvailable: Bool = false
    
    /// Indica si la biblioteca de fotos está disponible
    @Published var isPhotoLibraryAvailable: Bool = true
    
    /// Estado de permisos de cámara
    @Published var cameraPermissionStatus: AVAuthorizationStatus = .notDetermined
    
    /// Muestra el image picker
    @Published var showingImagePicker: Bool = false
    
    /// Muestra el action sheet para seleccionar fuente
    @Published var showingSourceSelection: Bool = false
    
    /// Fuente seleccionada
    @Published var selectedSource: ImageSource = .camera
    
    // MARK: - Callbacks
    
    /// Se llama cuando se selecciona/captura una imagen
    var onImageCaptured: ((UIImage) -> Void)?
    
    /// Se llama si hay un error
    var onError: ((Error) -> Void)?
    
    // MARK: - Initialization
    
    init() {
        checkAvailability()
    }
    
    // MARK: - Availability
    
    /// Verifica disponibilidad de hardware
    private func checkAvailability() {
        isCameraAvailable = UIImagePickerController.isSourceTypeAvailable(.camera)
        isPhotoLibraryAvailable = UIImagePickerController.isSourceTypeAvailable(.photoLibrary)
        cameraPermissionStatus = AVCaptureDevice.authorizationStatus(for: .video)
        
        print("📷 Camera Service:")
        print("   - Camera: \(isCameraAvailable ? "✅" : "❌")")
        print("   - Photo Library: \(isPhotoLibraryAvailable ? "✅" : "❌")")
        print("   - Camera Permission: \(cameraPermissionStatus.rawValue)")
    }
    
    // MARK: - Permissions
    
    /// Solicita permiso de cámara
    func requestCameraPermission() async -> Bool {
        let status = await AVCaptureDevice.requestAccess(for: .video)
        await MainActor.run {
            cameraPermissionStatus = AVCaptureDevice.authorizationStatus(for: .video)
        }
        
        if status {
            print("✅ Permiso de cámara otorgado")
        } else {
            print("❌ Permiso de cámara denegado")
        }
        
        return status
    }
    
    /// Verifica si tenemos todos los permisos necesarios
    var hasNecessaryPermissions: Bool {
        if selectedSource == .camera {
            return cameraPermissionStatus == .authorized
        }
        return true // Photo Library no requiere permiso explícito desde iOS 14+
    }
    
    // MARK: - Image Capture
    
    /// Muestra el selector de fuente (cámara o galería)
    func showSourceSelection() {
        showingSourceSelection = true
    }
    
    /// Inicia la captura desde la fuente especificada
    func captureImage(from source: ImageSource) async {
        selectedSource = source
        
        // Verificar disponibilidad
        if source == .camera && !isCameraAvailable {
            onError?(CameraError.cameraNotAvailable)
            return
        }
        
        // Solicitar permiso si es cámara
        if source == .camera {
            let hasPermission = await requestCameraPermission()
            guard hasPermission else {
                onError?(CameraError.permissionDenied)
                return
            }
        }
        
        // Mostrar image picker
        showingImagePicker = true
    }
    
    /// Maneja la imagen capturada
    func handleCapturedImage(_ image: UIImage) {
        print("📸 Imagen capturada/seleccionada")
        onImageCaptured?(image)
        showingImagePicker = false
    }
    
    /// Maneja cancelación
    func handleCancellation() {
        print("🚫 Captura cancelada")
        showingImagePicker = false
    }
}

// MARK: - SwiftUI Image Picker

/// Wrapper de UIImagePickerController para SwiftUI
struct ImagePicker: UIViewControllerRepresentable {
    
    @Environment(\.presentationMode) var presentationMode
    
    let sourceType: UIImagePickerController.SourceType
    let onImagePicked: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        picker.allowsEditing = true // Permitir edición/recorte
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        // No necesita actualización
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
        ) {
            // Preferir imagen editada, sino usar la original
            if let image = info[.editedImage] as? UIImage {
                parent.onImagePicked(image)
            } else if let image = info[.originalImage] as? UIImage {
                parent.onImagePicked(image)
            }
            
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - SwiftUI View Modifiers

extension View {
    /// Muestra el image picker cuando showingImagePicker es true
    func imagePicker(
        isPresented: Binding<Bool>,
        sourceType: UIImagePickerController.SourceType,
        onImagePicked: @escaping (UIImage) -> Void
    ) -> some View {
        sheet(isPresented: isPresented) {
            ImagePicker(
                sourceType: sourceType,
                onImagePicked: onImagePicked
            )
        }
    }
    
    /// Muestra action sheet para seleccionar fuente de imagen
    func imageSourcePicker(
        isPresented: Binding<Bool>,
        cameraAvailable: Bool,
        onSourceSelected: @escaping (ImageSource) -> Void
    ) -> some View {
        actionSheet(isPresented: isPresented) {
            ActionSheet(
                title: Text("Seleccionar fuente"),
                message: Text("¿Desde dónde quieres obtener la imagen?"),
                buttons: [
                    cameraAvailable ? .default(Text("📷 Tomar Foto")) {
                        onSourceSelected(.camera)
                    } : nil,
                    .default(Text("🖼️ Biblioteca de Fotos")) {
                        onSourceSelected(.photoLibrary)
                    },
                    .cancel(Text("Cancelar"))
                ].compactMap { $0 }
            )
        }
    }
}
