//
//  CameraView.swift
//  KaapehCopiloto2
//
//  Created by Cafe Swift Team on 05/11/25.
//

import SwiftUI
import AVFoundation

struct CameraView: UIViewControllerRepresentable {
    let completion: (UIImage?) -> Void
    
    func makeUIViewController(context: Context) -> CameraViewController {
        let controller = CameraViewController()
        controller.completion = completion
        return controller
    }
    
    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {}
}

class CameraViewController: UIViewController {
    var completion: ((UIImage?) -> Void)?
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var photoOutput: AVCapturePhotoOutput?
    private var isSessionConfigured = false
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        checkPermissionsAndSetup()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Iniciar session solo si ya está configurada
        if isSessionConfigured {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession?.startRunning()
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopSession()
    }
    
    // MARK: - Permissions
    
    private func checkPermissionsAndSetup() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCamera()
            
        case .notDetermined:
            // Solicitar permiso
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    DispatchQueue.main.async {
                        self?.setupCamera()
                    }
                } else {
                    self?.showPermissionDeniedAlert()
                }
            }
            
        case .denied, .restricted:
            // Permiso denegado
            showPermissionDeniedAlert()
            
        @unknown default:
            showPermissionDeniedAlert()
        }
    }
    
    private func showPermissionDeniedAlert() {
        DispatchQueue.main.async { [weak self] in
            let alert = UIAlertController(
                title: "Acceso a Cámara Requerido",
                message: "Por favor permite el acceso a la cámara en Ajustes para poder tomar fotos.",
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "Abrir Ajustes", style: .default) { _ in
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsURL)
                }
            })
            
            alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel) { [weak self] _ in
                self?.cancel()
            })
            
            self?.present(alert, animated: true)
        }
    }
    
    // MARK: - Camera Setup
    
    private func setupCamera() {
        // Crear session en background thread
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.configureCaptureSession()
        }
    }
    
    private func configureCaptureSession() {
        let session = AVCaptureSession()
        
        session.beginConfiguration()
        
        // Configurar preset
        if session.canSetSessionPreset(.photo) {
            session.sessionPreset = .photo
        }
        
        // Obtener dispositivo de cámara
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            print("❌ No se encontró cámara trasera")
            DispatchQueue.main.async { [weak self] in
                self?.showErrorAndClose("No se encontró la cámara")
            }
            return
        }
        
        // Crear input
        let input: AVCaptureDeviceInput
        do {
            input = try AVCaptureDeviceInput(device: camera)
        } catch {
            print("❌ Error creando input: \(error.localizedDescription)")
            DispatchQueue.main.async { [weak self] in
                self?.showErrorAndClose("Error al acceder a la cámara")
            }
            return
        }
        
        // Agregar input
        guard session.canAddInput(input) else {
            print("❌ No se puede agregar input a la session")
            DispatchQueue.main.async { [weak self] in
                self?.showErrorAndClose("Error configurando la cámara")
            }
            return
        }
        session.addInput(input)
        
        // Configurar output
        let output = AVCapturePhotoOutput()
        guard session.canAddOutput(output) else {
            print("❌ No se puede agregar output a la session")
            DispatchQueue.main.async { [weak self] in
                self?.showErrorAndClose("Error configurando la cámara")
            }
            return
        }
        session.addOutput(output)
        
        session.commitConfiguration()
        
        // Guardar referencias
        self.captureSession = session
        self.photoOutput = output
        self.isSessionConfigured = true
        
        print("✅ Cámara configurada exitosamente")
        
        // Configurar preview y UI en main thread
        DispatchQueue.main.async { [weak self] in
            self?.setupPreviewLayer()
            self?.setupUI()
            
            // Iniciar session en background thread
            DispatchQueue.global(qos: .userInitiated).async {
                session.startRunning()
                print("✅ Cámara iniciada")
            }
        }
    }
    
    private func setupPreviewLayer() {
        guard let session = captureSession else { return }
        
        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        preview.frame = view.bounds
        
        view.layer.insertSublayer(preview, at: 0)
        
        self.previewLayer = preview
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        // Botón de captura
        let captureButton = UIButton(frame: CGRect(x: 0, y: 0, width: 70, height: 70))
        captureButton.center = CGPoint(x: view.bounds.midX, y: view.bounds.maxY - 100)
        captureButton.layer.cornerRadius = 35
        captureButton.backgroundColor = .white
        captureButton.layer.borderWidth = 4
        captureButton.layer.borderColor = UIColor.systemGreen.cgColor
        captureButton.addTarget(self, action: #selector(capturePhoto), for: .touchUpInside)
        captureButton.accessibilityLabel = "Capturar foto"
        captureButton.accessibilityHint = "Toca para tomar una foto de la planta"
        view.addSubview(captureButton)
        
        // Botón de cancelar
        let cancelButton = UIButton(frame: CGRect(x: 20, y: 50, width: 40, height: 40))
        cancelButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        cancelButton.tintColor = .white
        cancelButton.addTarget(self, action: #selector(cancel), for: .touchUpInside)
        cancelButton.accessibilityLabel = "Cancelar"
        view.addSubview(cancelButton)
        
        // Guías visuales
        let guideSize = view.bounds.width - 100
        let guidesView = UIView(frame: CGRect(
            x: (view.bounds.width - guideSize) / 2,
            y: 200,
            width: guideSize,
            height: guideSize
        ))
        guidesView.layer.borderWidth = 2
        guidesView.layer.borderColor = UIColor.white.withAlphaComponent(0.7).cgColor
        guidesView.layer.cornerRadius = 20
        guidesView.isUserInteractionEnabled = false
        view.addSubview(guidesView)
        
        // Label de instrucción
        let label = UILabel(frame: CGRect(
            x: 20,
            y: guidesView.frame.maxY + 20,
            width: view.bounds.width - 40,
            height: 60
        ))
        label.text = "Centra la hoja en el marco"
        label.textColor = .white
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 18, weight: .medium)
        label.numberOfLines = 2
        view.addSubview(label)
    }
    
    // MARK: - Actions
    
    @objc private func capturePhoto() {
        guard let photoOutput = photoOutput else {
            print("⚠️ Photo output no disponible")
            return
        }
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        // Configurar settings de captura
        let settings = AVCapturePhotoSettings()
        
        // Configurar flash si está disponible
        if photoOutput.supportedFlashModes.contains(.auto) {
            settings.flashMode = .auto
        }
        
        // Capturar foto
        photoOutput.capturePhoto(with: settings, delegate: self)
        
        print("📸 Capturando foto...")
    }
    
    @objc private func cancel() {
        print("❌ Usuario canceló captura")
        stopSession()
        completion?(nil)
    }
    
    // MARK: - Session Management
    
    private func stopSession() {
        // ✅ CRÍTICO: Detener session en background thread
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let session = self?.captureSession, session.isRunning else { return }
            
            session.stopRunning()
            print("🛑 Cámara detenida")
        }
    }
    
    private func showErrorAndClose(_ message: String) {
        let alert = UIAlertController(
            title: "Error de Cámara",
            message: message,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.cancel()
        })
        
        present(alert, animated: true)
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension CameraViewController: AVCapturePhotoCaptureDelegate {
    
    func photoOutput(_ output: AVCapturePhotoOutput, willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        // Animación de flash visual
        DispatchQueue.main.async { [weak self] in
            let flashView = UIView(frame: self?.view.bounds ?? .zero)
            flashView.backgroundColor = .white
            flashView.alpha = 0
            self?.view.addSubview(flashView)
            
            UIView.animate(withDuration: 0.2, animations: {
                flashView.alpha = 1
            }) { _ in
                UIView.animate(withDuration: 0.2) {
                    flashView.alpha = 0
                } completion: { _ in
                    flashView.removeFromSuperview()
                }
            }
        }
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        // Verificar errores
        if let error = error {
            print("❌ Error capturando foto: \(error.localizedDescription)")
            DispatchQueue.main.async { [weak self] in
                self?.showErrorAndClose("Error al capturar la foto")
            }
            return
        }
        
        // Extraer datos de imagen
        guard let imageData = photo.fileDataRepresentation() else {
            print("❌ No se pudieron obtener datos de la foto")
            DispatchQueue.main.async { [weak self] in
                self?.showErrorAndClose("Error al procesar la foto")
            }
            return
        }
        
        // Crear UIImage
        guard let image = UIImage(data: imageData) else {
            print("❌ No se pudo crear UIImage desde los datos")
            DispatchQueue.main.async { [weak self] in
                self?.showErrorAndClose("Error al procesar la foto")
            }
            return
        }
        
        print("✅ Foto capturada exitosamente: \(image.size)")
        
        // Detener session antes de cerrar
        stopSession()
        
        // Retornar imagen
        DispatchQueue.main.async { [weak self] in
            self?.completion?(image)
        }
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        print("📸 Foto capturada, procesando...")
    }
}
