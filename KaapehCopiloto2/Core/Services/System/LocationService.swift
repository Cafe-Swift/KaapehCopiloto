//
//  LocationService.swift
//  KaapehCopiloto2
//
//  Implementa CLLocationUpdate (AsyncSequence) y MKReverseGeocodingRequest
//

import Foundation
import CoreLocation
import MapKit
import Combine

/// Servicio avanzado de geolocalización para iOS 26+
/// Utiliza las API modernas de Swift Concurrency y MapKit
@MainActor
final class LocationService: NSObject, ObservableObject {
    
    // MARK: - Singleton
    static let shared = LocationService()
    
    // MARK: - Published Properties
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var currentLocation: CLLocation?
    @Published var locationError: LocationError?
    @Published var isUpdatingLocation: Bool = false
    @Published var isStationary: Bool = false
    
    // MARK: - Private Properties
    private let locationManager: CLLocationManager
    private var locationTask: Task<Void, Never>?
    private var locationContinuation: CheckedContinuation<CLLocation, Error>?
    
    // MARK: - Initialization
    private override init() {
        self.locationManager = CLLocationManager()
        super.init()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10
        
        authorizationStatus = locationManager.authorizationStatus
    }
    
    // MARK: - Public Methods - Modern iOS 26 APIs
    
    /// Solicita permiso para usar la ubicación
    func requestAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func requestLocation() async throws -> CLLocation {
        // Si ya tenemos una ubicación reciente (< 1 minuto), usarla
        if let current = currentLocation,
           Date().timeIntervalSince(current.timestamp) < 60 {
            return current
        }
        
        // Verificar autorización
        guard authorizationStatus == .authorizedWhenInUse ||
              authorizationStatus == .authorizedAlways else {
            throw LocationError.notAuthorized
        }
        
        isUpdatingLocation = true
        locationError = nil

        do {
            let updates = CLLocationUpdate.liveUpdates()
            
            // Obtener la primera ubicación válida del stream
            for try await update in updates {
                if let location = update.location {
                    currentLocation = location
                    isUpdatingLocation = false
                    
                    isStationary = update.stationary
                    
                    if update.stationary {
                        print("📍 Dispositivo estacionario detectado")
                    }
                    
                    return location
                }
            }
            
            throw LocationError.locationUnavailable
            
        } catch {
            isUpdatingLocation = false
            
            // Convertir errores de Core Location a nuestro tipo
            if let clError = error as? CLError {
                switch clError.code {
                case .denied:
                    throw LocationError.notAuthorized
                case .network:
                    throw LocationError.networkError
                case .locationUnknown:
                    throw LocationError.locationUnavailable
                default:
                    throw LocationError.unknown(error)
                }
            }
            
            throw LocationError.unknown(error)
        }
    }

    func startLiveUpdates() {
        // Cancelar cualquier tarea anterior
        locationTask?.cancel()
        
        guard authorizationStatus == .authorizedWhenInUse ||
              authorizationStatus == .authorizedAlways else {
            locationError = .notAuthorized
            return
        }
        
        isUpdatingLocation = true

        locationTask = Task {
            do {
                // Configuración optimizada para navegación
                let updates = CLLocationUpdate.liveUpdates(.automotiveNavigation)
                
                for try await update in updates {
                    // Verificar si la tarea fue cancelada
                    if Task.isCancelled {
                        break
                    }
                    
                    // Actualizar ubicación
                    if let location = update.location {
                        self.currentLocation = location
                    }
                    
                    self.isStationary = update.stationary
                    
                    if update.stationary {
                        print("📍 Dispositivo estacionario - El sistema optimiza batería automáticamente")
                    }
                }
            } catch {
                print("⚠️ Error en CLLocationUpdate: \(error)")
                self.locationError = .unknown(error)
                self.isUpdatingLocation = false
            }
        }
    }
    
    /// Detiene las actualizaciones continuas
    func stopLiveUpdates() {
        locationTask?.cancel()
        locationTask = nil
        isUpdatingLocation = false
        print("🛑 Live updates detenidas - GPS apagado automáticamente")
    }
    
    // MARK: - Geocoding - Modern iOS 26 APIs
    
    func getPlaceName(for location: CLLocation) async -> String? {
        do {
            guard let request = MKReverseGeocodingRequest(location: location) else {
                return fallbackPlaceName(for: location.coordinate)
            }
            
            // Ejecutar la geocodificación inversa
            let mapItems = try await request.mapItems
            
            guard let mapItem = mapItems.first else {
                print("⚠️ No se encontraron resultados de geocodificación")
                return fallbackPlaceName(for: location.coordinate)
            }
            
            // 1. Intentar usar el nombre común del lugar
            if let name = mapItem.name, !name.isEmpty {
                print("✅ Nombre de lugar obtenido: \(name)")
                return name
            }
            
            // 2. Intentar usar MKAddress (API moderna)
            if let address = mapItem.address {
                // fullAddress es un String no-opcional en iOS 26
                let fullAddress = address.fullAddress
                if !fullAddress.isEmpty {
                    print("✅ Dirección completa obtenida (MKAddress): \(fullAddress)")
                    return fullAddress
                }
            }
            
            // 3. Fallback compatible: Construir desde placemark
            let placemark = mapItem.placemark
            var components: [String] = []
            
            if let thoroughfare = placemark.thoroughfare {
                components.append(thoroughfare)
            }
            
            if let locality = placemark.locality {
                components.append(locality)
            }
            
            if let administrativeArea = placemark.administrativeArea {
                components.append(administrativeArea)
            }
            
            if let country = placemark.country {
                components.append(country)
            }
            
            if !components.isEmpty {
                let address = components.joined(separator: ", ")
                print("✅ Dirección construida (Placemark fallback): \(address)")
                return address
            }
            
            // 3. Fallback final: coordenadas formateadas
            print("⚠️ No se pudo obtener dirección - usando coordenadas")
            return fallbackPlaceName(for: location.coordinate)
            
        } catch {
            print("⚠️ MKReverseGeocodingRequest falló: \(error.localizedDescription)")
            return fallbackPlaceName(for: location.coordinate)
        }
    }
    

    func searchPlace(named name: String, near coordinate: CLLocationCoordinate2D) async throws -> MKMapItem? {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = name
        request.resultTypes = [.pointOfInterest, .address]
        
        // Búsqueda localizada en un radio de 10km
        request.region = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: 10000,
            longitudinalMeters: 10000
        )
        
        let search = MKLocalSearch(request: request)
        let response = try await search.start()
        
        print("🔍 Búsqueda '\(name)': \(response.mapItems.count) resultados encontrados")
        
        return response.mapItems.first
    }
    
    func getFullAddress(for location: CLLocation) async -> String? {
        guard let placeName = await getPlaceName(for: location) else {
            return nil
        }
        
        // Agregar coordenadas para precisión adicional
        let coords = String(format: "(%.4f, %.4f)", location.coordinate.latitude, location.coordinate.longitude)
        
        return "\(placeName)\n\(coords)"
    }
    
    /// Genera un nombre de lugar básico usando coordenadas (fallback)
    private func fallbackPlaceName(for coordinate: CLLocationCoordinate2D) -> String {
        return String(format: "Lat: %.4f, Lon: %.4f", coordinate.latitude, coordinate.longitude)
    }
    
    // MARK: - Legacy Support (Compatibilidad hacia atrás)
    
    /// Método legacy usando delegate (solo para compatibilidad)
    /// Preferir usar requestLocation() con CLLocationUpdate
    @available(*, deprecated, message: "Usar requestLocation() con CLLocationUpdate en iOS 26+")
    func requestLocationLegacy() async throws -> CLLocation {
        guard authorizationStatus == .authorizedWhenInUse ||
              authorizationStatus == .authorizedAlways else {
            throw LocationError.notAuthorized
        }
        
        isUpdatingLocation = true
        locationError = nil
        
        return try await withCheckedThrowingContinuation { continuation in
            self.locationContinuation = continuation
            locationManager.requestLocation()
        }
    }
    
    /// Método legacy de actualizaciones continuas
    @available(*, deprecated, message: "Usar startLiveUpdates() con CLLocationUpdate en iOS 26+")
    func startUpdatingLocation() {
        guard authorizationStatus == .authorizedWhenInUse ||
              authorizationStatus == .authorizedAlways else {
            locationError = .notAuthorized
            return
        }
        
        isUpdatingLocation = true
        locationManager.startUpdatingLocation()
    }
    
    /// Método legacy de detener actualizaciones
    @available(*, deprecated, message: "Usar stopLiveUpdates() en iOS 26+")
    func stopUpdatingLocation() {
        isUpdatingLocation = false
        locationManager.stopUpdatingLocation()
    }
}

// MARK: - CLLocationManagerDelegate (Legacy Support)

extension LocationService: CLLocationManagerDelegate {
    
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            authorizationStatus = manager.authorizationStatus
            
            if authorizationStatus == .denied || authorizationStatus == .restricted {
                locationError = .notAuthorized
            }
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            guard let location = locations.last else { return }
            
            currentLocation = location
            isUpdatingLocation = false
            locationError = nil
            
            // Resolver continuación si existe (para método legacy)
            if let continuation = locationContinuation {
                continuation.resume(returning: location)
                locationContinuation = nil
            }
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            isUpdatingLocation = false
            
            let locationError: LocationError
            
            if let clError = error as? CLError {
                switch clError.code {
                case .denied:
                    locationError = .notAuthorized
                case .network:
                    locationError = .networkError
                case .locationUnknown:
                    locationError = .locationUnavailable
                default:
                    locationError = .unknown(error)
                }
            } else {
                locationError = .unknown(error)
            }
            
            self.locationError = locationError
            
            // Resolver continuación si existe (para método legacy)
            if let continuation = locationContinuation {
                continuation.resume(throwing: locationError)
                locationContinuation = nil
            }
        }
    }
}

// MARK: - Location Error

enum LocationError: LocalizedError {
    case notAuthorized
    case locationUnavailable
    case networkError
    case timeout
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Permiso de ubicación no autorizado. Ve a Ajustes para habilitarlo."
        case .locationUnavailable:
            return "No se pudo obtener la ubicación. Intenta de nuevo."
        case .networkError:
            return "Error de red al obtener la ubicación."
        case .timeout:
            return "Se agotó el tiempo de espera para obtener la ubicación."
        case .unknown(let error):
            return "Error desconocido: \(error.localizedDescription)"
        }
    }
}

// MARK: - Helper Extensions

extension CLAuthorizationStatus {
    var isAuthorized: Bool {
        self == .authorizedWhenInUse || self == .authorizedAlways
    }
}
