//
//  ActivityMapView.swift
//  KaapehCopiloto2
//
//  Mapa de actividad para técnicos mostrando diagnósticos por ubicación
//

import SwiftUI
import SwiftData
import MapKit

struct ActivityMapView: View {
    let user: UserProfile
    @State private var viewModel: ActivityMapViewModel
    @Environment(AccessibilityManager.self) private var accessibilityManager
    
    init(user: UserProfile) {
        self.user = user
        self._viewModel = State(initialValue: ActivityMapViewModel(user: user))
    }
    
    var body: some View {
        ZStack {
            // Fondo crema
            Color(red: 0.98, green: 0.96, blue: 0.93)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header con título y filtros
                headerView
                
                // Mapa principal
                mapView
                
                // Stats bar en la parte inferior
                statsBarView
            }
        }
        .onAppear {
            viewModel.loadDiagnoses()
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Mapa de Actividad")
                        .font(.system(size: accessibilityManager.titleFontSize, weight: .bold))
                        .foregroundStyle(accessibilityManager.primaryTextColor)
                    
                    Text("\(viewModel.totalDiagnoses) diagnósticos registrados")
                        .font(.system(size: accessibilityManager.captionFontSize))
                        .foregroundStyle(accessibilityManager.secondaryTextColor)
                }
                
                Spacer()
                
                // Botón de filtros
                Button(action: {
                    viewModel.showFilters.toggle()
                }) {
                    Image(systemName: viewModel.showFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                        .font(.title2)
                        .foregroundStyle(Color(red: 0.4, green: 0.26, blue: 0.13))
                }
                .sensoryFeedback(.selection, trigger: viewModel.showFilters)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            
            // Panel de filtros
            if viewModel.showFilters {
                filterPanel
            }
        }
        .background(Color.white)
        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
    }
    
    private var filterPanel: some View {
        VStack(spacing: 12) {
            // Filtro por tipo de problema
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(
                        title: "Todos",
                        isSelected: viewModel.selectedFilter == nil,
                        icon: "list.bullet",
                        onTap: {
                            viewModel.selectedFilter = nil
                            viewModel.applyFilter()
                        }
                    )
                    
                    ForEach(viewModel.availableIssues, id: \.self) { issue in
                        FilterChip(
                            title: issue,
                            isSelected: viewModel.selectedFilter == issue,
                            icon: iconForIssue(issue),
                            onTap: {
                                viewModel.selectedFilter = issue
                                viewModel.applyFilter()
                            }
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
            
            // Filtro por fecha
            HStack {
                Text("Últimos:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Picker("Período", selection: $viewModel.selectedPeriod) {
                    Text("7 días").tag(7)
                    Text("30 días").tag(30)
                    Text("Todo").tag(365)
                }
                .pickerStyle(.segmented)
                .onChange(of: viewModel.selectedPeriod) { _, _ in
                    viewModel.applyFilter()
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 12)
        .background(Color(red: 0.98, green: 0.96, blue: 0.93))
    }
    
    // MARK: - Map
    
    private var mapView: some View {
        GeometryReader { geometry in
            Map(position: $viewModel.cameraPosition) {
                // Anotaciones de diagnósticos
                ForEach(viewModel.filteredLocations) { location in
                    Annotation(
                        location.issueName,
                        coordinate: location.coordinate
                    ) {
                        MapAnnotationView(
                            location: location,
                            isSelected: viewModel.selectedLocation?.id == location.id,
                            onTap: {
                                viewModel.selectLocation(location)
                            }
                        )
                    }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .mapStyle(.standard(elevation: .realistic))
            .mapControls {
                MapUserLocationButton()
                MapCompass()
                MapScaleView()
            }
            .sheet(item: $viewModel.selectedLocation) { location in
                LocationDetailSheet(location: location)
                    .presentationDetents([.height(300), .medium])
                    .presentationDragIndicator(.visible)
            }
            .opacity(geometry.size.width > 0 && geometry.size.height > 0 ? 1 : 0)
        }
    }
    
    // MARK: - Stats Bar
    
    private var statsBarView: some View {
        HStack(spacing: 0) {
            StatItem(
                icon: "map.circle.fill",
                value: "\(viewModel.filteredLocations.count)",
                label: "Ubicaciones",
                color: .blue
            )
            
            Divider()
                .frame(height: 40)
            
            StatItem(
                icon: "exclamationmark.triangle.fill",
                value: "\(viewModel.totalIssues)",
                label: "Problemas",
                color: .orange
            )
            
            Divider()
                .frame(height: 40)
            
            StatItem(
                icon: "checkmark.circle.fill",
                value: "\(viewModel.resolvedPercentage)%",
                label: "Resueltos",
                color: Color(red: 0.2, green: 0.5, blue: 0.3)
            )
        }
        .padding(.vertical, 16)
        .background(Color.white)
        .shadow(color: .black.opacity(0.1), radius: 4, y: -2)
    }
    
    // MARK: - Helper Functions
    
    private func iconForIssue(_ issue: String) -> String {
        switch issue.lowercased() {
        case let x where x.contains("roya"):
            return "exclamationmark.triangle.fill"
        case let x where x.contains("sano") || x.contains("sana"):
            return "checkmark.seal.fill"
        case let x where x.contains("nitrógeno") || x.contains("nitrogen"):
            return "leaf.fill"
        default:
            return "questionmark.circle.fill"
        }
    }
}

// MARK: - Supporting Views

struct MapAnnotationView: View {
    let location: DiagnosisLocation
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                // Pin superior con número
                ZStack {
                    Circle()
                        .fill(colorForIssue(location.issueName))
                        .frame(width: isSelected ? 50 : 40, height: isSelected ? 50 : 40)
                        .shadow(color: colorForIssue(location.issueName).opacity(0.4), radius: 4, y: 2)
                    
                    VStack(spacing: 2) {
                        Image(systemName: iconForIssue(location.issueName))
                            .font(.system(size: isSelected ? 18 : 14, weight: .bold))
                            .foregroundStyle(.white)
                        
                        if location.count > 1 {
                            Text("\(location.count)")
                                .font(.system(size: isSelected ? 12 : 10, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                }
                
                // Punta del pin
                Circle()
                    .fill(colorForIssue(location.issueName))
                    .frame(width: 8, height: 8)
                    .offset(y: -4)
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.spring(response: 0.3), value: isSelected)
    }
    
    private func iconForIssue(_ issue: String) -> String {
        switch issue.lowercased() {
        case let x where x.contains("roya"):
            return "exclamationmark.triangle.fill"
        case let x where x.contains("sano"):
            return "checkmark.seal.fill"
        case let x where x.contains("nitrógeno"):
            return "leaf.fill"
        default:
            return "questionmark.circle.fill"
        }
    }
    
    private func colorForIssue(_ issue: String) -> Color {
        switch issue.lowercased() {
        case let x where x.contains("roya"):
            return .orange
        case let x where x.contains("sano"):
            return Color(red: 0.2, green: 0.5, blue: 0.3)
        case let x where x.contains("nitrógeno"):
            return .yellow.opacity(0.8)
        default:
            return .blue
        }
    }
}

struct StatItem: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Color(red: 0.2, green: 0.13, blue: 0.07))
            
            Text(label)
                .font(.caption2)
                .foregroundStyle(Color(red: 0.4, green: 0.26, blue: 0.13))
        }
        .frame(maxWidth: .infinity)
    }
}

struct LocationDetailSheet: View {
    let location: DiagnosisLocation
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            // Handle
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 5)
                .padding(.top, 8)
            
            // Contenido
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: iconForIssue(location.issueName))
                        .font(.system(size: 40))
                        .foregroundStyle(.white)
                        .frame(width: 70, height: 70)
                        .background(colorForIssue(location.issueName))
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(location.issueName)
                            .font(.title3.bold())
                            .foregroundStyle(Color(red: 0.2, green: 0.13, blue: 0.07))
                        
                        Text("\(location.count) diagnóstico(s)")
                            .font(.subheadline)
                            .foregroundStyle(Color(red: 0.4, green: 0.26, blue: 0.13))
                    }
                    
                    Spacer()
                }
                
                Divider()
                
                VStack(spacing: 12) {
                    HStack {
                        Label("Ubicación", systemImage: "mappin.circle.fill")
                            .font(.subheadline.weight(.medium))
                        Spacer()
                    }
                    
                    Text("Lat: \(String(format: "%.4f", location.coordinate.latitude))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text("Lon: \(String(format: "%.4f", location.coordinate.longitude))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                if let lastDate = location.lastDiagnosis {
                    HStack {
                        Label("Último diagnóstico", systemImage: "clock.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(lastDate.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
        .background(Color(red: 0.98, green: 0.96, blue: 0.93))
    }
    
    private func iconForIssue(_ issue: String) -> String {
        switch issue.lowercased() {
        case let x where x.contains("roya"):
            return "exclamationmark.triangle.fill"
        case let x where x.contains("sano"):
            return "checkmark.seal.fill"
        case let x where x.contains("nitrógeno"):
            return "leaf.fill"
        default:
            return "questionmark.circle.fill"
        }
    }
    
    private func colorForIssue(_ issue: String) -> Color {
        switch issue.lowercased() {
        case let x where x.contains("roya"):
            return .orange
        case let x where x.contains("sano"):
            return Color(red: 0.2, green: 0.5, blue: 0.3)
        case let x where x.contains("nitrógeno"):
            return .yellow.opacity(0.8)
        default:
            return .blue
        }
    }
}

// MARK: - Data Models

struct DiagnosisLocation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let issueName: String
    let count: Int
    let lastDiagnosis: Date?
    let locationName: String? // Nombre del lugar opcional
}

// MARK: - ViewModel

@MainActor
@Observable
final class ActivityMapViewModel {
    let user: UserProfile
    var cameraPosition: MapCameraPosition
    var allLocations: [DiagnosisLocation] = []
    var filteredLocations: [DiagnosisLocation] = []
    var selectedLocation: DiagnosisLocation?
    var showFilters: Bool = false
    var selectedFilter: String?
    var selectedPeriod: Int = 30
    var availableIssues: [String] = []
    
    private let dataService = SwiftDataService.shared
    
    var totalDiagnoses: Int {
        allLocations.reduce(0) { $0 + $1.count }
    }
    
    var totalIssues: Int {
        allLocations.filter { !$0.issueName.lowercased().contains("sano") }.reduce(0) { $0 + $1.count }
    }
    
    var resolvedPercentage: Int {
        let resolved = allLocations.filter { $0.issueName.lowercased().contains("sano") }.reduce(0) { $0 + $1.count }
        return totalDiagnoses > 0 ? Int((Double(resolved) / Double(totalDiagnoses)) * 100) : 0
    }
    
    init(user: UserProfile) {
        self.user = user
        // Centro en Chiapas, México (región cafetalera)
        self.cameraPosition = .region(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 16.7569, longitude: -93.1292),
            span: MKCoordinateSpan(latitudeDelta: 1.0, longitudeDelta: 1.0)
        ))
    }
    
    func loadDiagnoses() {
        // Cargar todos los diagnósticos
        do {
            let diagnoses = try dataService.fetchAllDiagnoses(limit: 500)
            
            // Generar ubicaciones simuladas (en producción vendrían de los diagnósticos)
            generateRealLocations(from: diagnoses)
            
            // Obtener tipos de problemas únicos
            availableIssues = Array(Set(allLocations.map { $0.issueName })).sorted()
            
            // Aplicar filtro inicial
            applyFilter()
            
            // Ajustar cámara para mostrar todos los puntos
            adjustCameraToFitLocations()
            
        } catch {
            print("Error loading diagnoses: \(error)")
        }
    }
    
    func selectLocation(_ location: DiagnosisLocation) {
        selectedLocation = location
    }
    
    func applyFilter() {
        var filtered = allLocations
        
        // Filtrar por tipo
        if let filter = selectedFilter {
            filtered = filtered.filter { $0.issueName == filter }
        }
        
        // Filtrar por fecha
        if selectedPeriod < 365 {
            let cutoffDate = Calendar.current.date(byAdding: .day, value: -selectedPeriod, to: Date())!
            filtered = filtered.filter { location in
                guard let lastDate = location.lastDiagnosis else { return false }
                return lastDate >= cutoffDate
            }
        }
        
        filteredLocations = filtered
    }
    
    private func generateRealLocations(from diagnoses: [DiagnosisRecord]) {
        // Filtrar solo diagnósticos con ubicación válida
        let diagnosesWithLocation = diagnoses.filter { $0.hasLocation }
        
        // Si no hay diagnósticos con ubicación, generar algunos simulados para demo
        if diagnosesWithLocation.isEmpty {
            generateFallbackSimulatedLocations(from: diagnoses)
            return
        }
        
        // Agrupar diagnósticos por ubicación cercana (mismo lugar ≈ 100m de radio)
        var locationGroups: [[DiagnosisRecord]] = []
        
        for diagnosis in diagnosesWithLocation {
            guard let coords = diagnosis.coordinates else { continue }
            let diagnosisLocation = CLLocation(latitude: coords.latitude, longitude: coords.longitude)
            
            // Buscar un grupo existente cercano
            var addedToGroup = false
            for (index, group) in locationGroups.enumerated() {
                if let firstInGroup = group.first,
                   let firstCoords = firstInGroup.coordinates {
                    let firstLocation = CLLocation(latitude: firstCoords.latitude, longitude: firstCoords.longitude)
                    
                    // Si están a menos de 100 metros, agrupar
                    if diagnosisLocation.distance(from: firstLocation) < 100 {
                        locationGroups[index].append(diagnosis)
                        addedToGroup = true
                        break
                    }
                }
            }
            
            // Si no se agregó a ningún grupo, crear uno nuevo
            if !addedToGroup {
                locationGroups.append([diagnosis])
            }
        }
        
        // Crear DiagnosisLocation para cada grupo
        allLocations = locationGroups.flatMap { group -> [DiagnosisLocation] in
            guard let first = group.first,
                  let coords = first.coordinates else { return [] }
            
            // Agrupar por tipo de problema dentro del mismo lugar
            let issueGroups = Dictionary(grouping: group) { $0.detectedIssue }
            
            // Crear una ubicación por cada tipo de problema en este lugar
            return issueGroups.map { issue, records in
                DiagnosisLocation(
                    coordinate: CLLocationCoordinate2D(latitude: coords.latitude, longitude: coords.longitude),
                    issueName: issue,
                    count: records.count,
                    lastDiagnosis: records.map { $0.timestamp }.max(),
                    locationName: records.first?.locationName
                )
            }
        }
    }
    
    /// Genera ubicaciones simuladas como fallback si no hay datos reales
    private func generateFallbackSimulatedLocations(from diagnoses: [DiagnosisRecord]) {
        print("⚠️ No hay diagnósticos con ubicación. Generando datos simulados para demo.")
        
        // Agrupar diagnósticos por tipo
        let grouped = Dictionary(grouping: diagnoses) { $0.detectedIssue }
        
        // Región de Chiapas (zona cafetalera)
        let baseLatitude = 16.7569
        let baseLongitude = -93.1292
        
        allLocations = grouped.map { issue, records in
            // Generar coordenadas aleatorias cerca del centro
            let randomLat = baseLatitude + Double.random(in: -0.5...0.5)
            let randomLon = baseLongitude + Double.random(in: -0.5...0.5)
            
            return DiagnosisLocation(
                coordinate: CLLocationCoordinate2D(latitude: randomLat, longitude: randomLon),
                issueName: issue,
                count: records.count,
                lastDiagnosis: records.map { $0.timestamp }.max(),
                locationName: "Demo - \(issue)"
            )
        }
    }
    
    private func adjustCameraToFitLocations() {
        guard !filteredLocations.isEmpty else { return }
        
        let coordinates = filteredLocations.map { $0.coordinate }
        let minLat = coordinates.map { $0.latitude }.min() ?? 0
        let maxLat = coordinates.map { $0.latitude }.max() ?? 0
        let minLon = coordinates.map { $0.longitude }.min() ?? 0
        let maxLon = coordinates.map { $0.longitude }.max() ?? 0
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        
        let span = MKCoordinateSpan(
            latitudeDelta: max(maxLat - minLat, 0.1) * 1.3,
            longitudeDelta: max(maxLon - minLon, 0.1) * 1.3
        )
        
        cameraPosition = .region(MKCoordinateRegion(center: center, span: span))
    }
}

// MARK: - Extension para fetchAllDiagnoses

extension SwiftDataService {
    func fetchAllDiagnoses(limit: Int = 500) throws -> [DiagnosisRecord] {
        guard let context = modelContext else {
            throw NSError(domain: "SwiftDataService", code: 1, userInfo: [NSLocalizedDescriptionKey: "ModelContext is not configured"])
        }
        
        var descriptor = FetchDescriptor<DiagnosisRecord>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return try context.fetch(descriptor)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: UserProfile.self, DiagnosisRecord.self, AccessibilityConfig.self,
        configurations: config
    )
    
    let user = UserProfile(userName: "tecnico", role: "Técnico", preferredLanguage: "es")
    
    ActivityMapView(user: user)
        .modelContainer(container)
        .environment(AccessibilityManager.shared)
}
