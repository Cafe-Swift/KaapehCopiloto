//
//  PermissionManager.swift
//  KaapehCopiloto2
//
//  Gestiona permisos de Micrófono y Speech Recognition
//

import AVFoundation
import Speech
import Foundation
import Combine

enum PermissionError: Error {
    case microphoneDenied
    case speechRecognitionDenied
    case permissionsIncomplete
    
    var localizedDescription: String {
        switch self {
        case .microphoneDenied:
            return "Necesitamos acceso al micrófono para transcribir tu voz. Por favor, actívalo en Ajustes."
        case .speechRecognitionDenied:
            return "Necesitamos permiso para reconocer tu voz. Por favor, actívalo en Ajustes."
        case .permissionsIncomplete:
            return "Faltan permisos necesarios para usar la función de voz."
        }
    }
}

@MainActor
class PermissionManager: ObservableObject {
    @Published var microphoneAuthorized: Bool = false
    @Published var speechRecognitionAuthorized: Bool = false
    
    var allPermissionsGranted: Bool {
        microphoneAuthorized && speechRecognitionAuthorized
    }
    
    init() {
        checkCurrentStatus()
    }
    
    /// Verifica el estado actual de los permisos (sin solicitar)
    func checkCurrentStatus() {
        // Micrófono - Usar AVAudioApplication (iOS 17+)
        let micStatus = AVAudioApplication.shared.recordPermission
        microphoneAuthorized = (micStatus == .granted)
        
        // Speech Recognition
        let speechStatus = SFSpeechRecognizer.authorizationStatus()
        speechRecognitionAuthorized = (speechStatus == .authorized)
        
        print("📱 Estado de permisos:")
        print("   - Micrófono: \(microphoneAuthorized ? "✅" : "❌")")
        print("   - Speech: \(speechRecognitionAuthorized ? "✅" : "❌")")
    }
    
    /// Solicita todos los permisos necesarios
    func requestAllPermissions() async throws {
        print("🔐 Solicitando permisos de voz...")
        
        // Solicitar ambos permisos concurrentemente
        async let micResult = requestMicrophonePermission()
        async let speechResult = requestSpeechPermission()
        
        let (hasMic, speechStatus) = await (micResult, speechResult)
        
        // Actualizar estado
        microphoneAuthorized = hasMic
        speechRecognitionAuthorized = (speechStatus == .authorized)
        
        // Validar que ambos fueron otorgados
        guard hasMic else {
            throw PermissionError.microphoneDenied
        }
        
        guard speechStatus == .authorized else {
            throw PermissionError.speechRecognitionDenied
        }
        
        print("✅ Todos los permisos otorgados")
    }
    
    // MARK: - Private Methods
    
    /// Solicita permiso de micrófono
    private func requestMicrophonePermission() async -> Bool {
        let granted = await AVAudioApplication.requestRecordPermission()
        
        if granted {
            print("✅ Permiso de micrófono otorgado")
        } else {
            print("❌ Permiso de micrófono denegado")
        }
        
        return granted
    }
    
    /// Solicita permiso de Speech Recognition
    private func requestSpeechPermission() async -> SFSpeechRecognizerAuthorizationStatus {
        return await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                switch status {
                case .authorized:
                    print("✅ Permiso de Speech Recognition otorgado")
                case .denied:
                    print("❌ Permiso de Speech Recognition denegado")
                case .restricted:
                    print("⚠️ Speech Recognition restringido en este dispositivo")
                case .notDetermined:
                    print("❓ Speech Recognition aún no determinado")
                @unknown default:
                    print("❓ Estado desconocido de Speech Recognition")
                }
                continuation.resume(returning: status)
            }
        }
    }
}
