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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
        setupUI()
    }
    
    private func setupCamera() {
        captureSession = AVCaptureSession()
        guard let captureSession = captureSession else { return }
        
        captureSession.sessionPreset = .photo
        
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: camera) else {
            return
        }
        
        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        }
        
        photoOutput = AVCapturePhotoOutput()
        if let photoOutput = photoOutput, captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer?.videoGravity = .resizeAspectFill
        previewLayer?.frame = view.bounds
        
        if let previewLayer = previewLayer {
            view.layer.addSublayer(previewLayer)
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            captureSession.startRunning()
        }
    }
    
    private func setupUI() {
        // Botón de captura
        let captureButton = UIButton(frame: CGRect(x: 0, y: 0, width: 70, height: 70))
        captureButton.center = CGPoint(x: view.bounds.midX, y: view.bounds.maxY - 100)
        captureButton.layer.cornerRadius = 35
        captureButton.backgroundColor = .white
        captureButton.layer.borderWidth = 4
        captureButton.layer.borderColor = UIColor.systemGreen.cgColor
        captureButton.addTarget(self, action: #selector(capturePhoto), for: .touchUpInside)
        view.addSubview(captureButton)
        
        // Botón de cancelar
        let cancelButton = UIButton(frame: CGRect(x: 20, y: 50, width: 40, height: 40))
        cancelButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        cancelButton.tintColor = .white
        cancelButton.addTarget(self, action: #selector(cancel), for: .touchUpInside)
        view.addSubview(cancelButton)
        
        // Guías visuales
        let guidesView = UIView(frame: CGRect(x: 50, y: 200, width: view.bounds.width - 100, height: view.bounds.width - 100))
        guidesView.layer.borderWidth = 2
        guidesView.layer.borderColor = UIColor.white.withAlphaComponent(0.7).cgColor
        guidesView.layer.cornerRadius = 20
        guidesView.isUserInteractionEnabled = false
        view.addSubview(guidesView)
        
        let label = UILabel(frame: CGRect(x: 0, y: guidesView.frame.maxY + 20, width: view.bounds.width, height: 40))
        label.text = "Centra la hoja en el marco"
        label.textColor = .white
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 18, weight: .medium)
        view.addSubview(label)
    }
    
    @objc private func capturePhoto() {
        guard let photoOutput = photoOutput else { return }
        
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    @objc private func cancel() {
        captureSession?.stopRunning()
        completion?(nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        captureSession?.stopRunning()
    }
}

extension CameraViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            completion?(nil)
            return
        }
        
        captureSession?.stopRunning()
        completion?(image)
    }
}
