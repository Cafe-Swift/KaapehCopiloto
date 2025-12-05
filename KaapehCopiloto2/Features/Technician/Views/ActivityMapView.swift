//
//  ActivityMapView.swift
//  KaapehCopiloto2
//
//  Mapa de actividad mejorado
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
            mapView
            
            // Controles flotantes con Liquid Glass
            VStack {
                // Header flotante superior
                headerFloatingCard
                
                Spacer()
                
                // Stats flotantes inferior
                statsFloatingCard
            }
        }
        .preferredColorScheme(.light)
        .onAppear {
            viewModel.loadDiagnoses()
        }
    }
    
    // MARK: - Header Flotante (Liquid Glass)
    
    private var headerFloatingCard: some View {
        VStack(spacing: 16) {
            // Título y botón de filtros
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Mapa de Actividad")
                        .font(.system(size: accessibilityManager.titleFontSize, weight: .bold))
                        .foregroundStyle(accessibilityManager.primaryTextColor)
                    
                    HStack(spacing: 6) {
                        Image(systemName: "map.fill")
                            .font(.system(size: accessibilityManager.captionFontSize - 2))
                        Text("\(viewModel.totalDiagnoses) diagnósticos")
                            .font(.system(size: accessibilityManager.captionFontSize))
                    }
                    .foregroundStyle(accessibilityManager.secondaryTextColor)
                }
                
                Spacer()
                
                // Botón de filtros con haptic
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        viewModel.showFilters.toggle()
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(viewModel.showFilters ? accessibilityManager.secondaryTextColor : Color.white)
                            .frame(width: 44, height: 44)
                            .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
                        
                        Image(systemName: viewModel.showFilters ? "xmark" : "line.3.horizontal.decrease.circle.fill")
                            .font(.title3)
                            .foregroundStyle(viewModel.showFilters ? .white : accessibilityManager.secondaryTextColor)
                    }
                }
                .sensoryFeedback(.selection, trigger: viewModel.showFilters)
            }
            
            // Panel de filtros expandible
            if viewModel.showFilters {
                filtersExpandedPanel
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.15), radius: 12, y: 6)
        )
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
    
    private var filtersExpandedPanel: some View {
        VStack(spacing: 16) {
            Divider()
            
            // Filtros por tipo de problema
            VStack(alignment: .leading, spacing: 10) {
                Text("Tipo de Problema")
                    .font(.system(size: accessibilityManager.captionFontSize, weight: .semibold))
                    .foregroundStyle(accessibilityManager.primaryTextColor)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ModernFilterChip(
                            title: "Todos",
                            isSelected: viewModel.selectedFilter == nil,
                            icon: "list.bullet",
                            accessibilityManager: accessibilityManager,
                            onTap: {
                                viewModel.selectedFilter = nil
                                viewModel.applyFilter()
                            }
                        )
                        
                        ForEach(viewModel.availableIssues, id: \.self) { issue in
                            ModernFilterChip(
                                title: issue,
                                isSelected: viewModel.selectedFilter == issue,
                                icon: iconForIssue(issue),
                                accessibilityManager: accessibilityManager,
                                onTap: {
                                    viewModel.selectedFilter = issue
                                    viewModel.applyFilter()
                                }
                            )
                        }
                    }
                }
            }
            
            Divider()
            
            // Filtro por período
            VStack(alignment: .leading, spacing: 10) {
                Text("Período de Tiempo")
                    .font(.system(size: accessibilityManager.captionFontSize, weight: .semibold))
                    .foregroundStyle(accessibilityManager.primaryTextColor)
                
                Picker("Período", selection: $viewModel.selectedPeriod) {
                    Text("7 días").tag(7)
                    Text("30 días").tag(30)
                    Text("Todo").tag(365)
                }
                .pickerStyle(.segmented)
                .onChange(of: viewModel.selectedPeriod) { _, _ in
                    viewModel.applyFilter()
                }
                .sensoryFeedback(.selection, trigger: viewModel.selectedPeriod)
            }
        }
        .padding(.top, 8)
    }
    
    // MARK: - Map Principal
    
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
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    viewModel.selectLocation(location)
                                }
                            }
                        )
                    }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .mapStyle(.standard(elevation: .realistic))
            .mapControls {
                MapCompass()
                MapScaleView()
            }
            .overlay(alignment: .topTrailing) {
                // Botón de ubicación personalizado en overlay
                VStack(spacing: 12) {
                    Spacer()
                        .frame(height: viewModel.showFilters ? 320 : 180)
                    
                    Button(action: {
                        // Centrar en ubicación del usuario
                        viewModel.centerOnUserLocation()
                    }) {
                        ZStack {
                            Circle()
                                .fill(.white)
                                .frame(width: 44, height: 44)
                                .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                            
                            Image(systemName: "location.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(accessibilityManager.secondaryTextColor)
                        }
                    }
                    .sensoryFeedback(.impact(weight: .medium), trigger: viewModel.cameraPosition)
                    
                    Spacer()
                }
                .padding(.trailing, 16)
            }
            .sheet(item: $viewModel.selectedLocation) { location in
                LocationDetailSheet(location: location, accessibilityManager: accessibilityManager)
                    .presentationDetents([.height(350), .medium])
                    .presentationDragIndicator(.visible)
            }
            .opacity(geometry.size.width > 0 && geometry.size.height > 0 ? 1 : 0)
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Stats Flotantes (Liquid Glass)
    
    private var statsFloatingCard: some View {
        HStack(spacing: 0) {
            ModernStatItem(
                icon: "map.circle.fill",
                value: "\(viewModel.filteredLocations.count)",
                label: "Ubicaciones",
                color: .blue,
                accessibilityManager: accessibilityManager
            )
            
            Rectangle()
                .fill(Color.white.opacity(0.3))
                .frame(width: 1, height: 50)
            
            ModernStatItem(
                icon: "exclamationmark.triangle.fill",
                value: "\(viewModel.totalIssues)",
                label: "Problemas",
                color: .orange,
                accessibilityManager: accessibilityManager
            )
            
            Rectangle()
                .fill(Color.white.opacity(0.3))
                .frame(width: 1, height: 50)
            
            ModernStatItem(
                icon: "checkmark.circle.fill",
                value: "\(viewModel.resolvedPercentage)%",
                label: "Resueltos",
                color: Color(red: 0.2, green: 0.5, blue: 0.3),
                accessibilityManager: accessibilityManager
            )
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.15), radius: 12, y: -6)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 20) 
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

// MARK: - Componentes Modernos

struct ModernFilterChip: View {
    let title: String
    let isSelected: Bool
    let icon: String
    let accessibilityManager: AccessibilityManager
    let onTap: () -> Void
    
    var body: some View {
        Button(action: {
            onTap()
        }) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: accessibilityManager.captionFontSize))
                Text(title)
                    .font(.system(size: accessibilityManager.captionFontSize, weight: .medium))
                    .lineLimit(1)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? accessibilityManager.secondaryTextColor : Color.white)
            )
            .foregroundStyle(isSelected ? .white : accessibilityManager.primaryTextColor)
            .shadow(color: isSelected ? accessibilityManager.secondaryTextColor.opacity(0.3) : .black.opacity(0.1), radius: 4, y: 2)
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isSelected)
    }
}

struct ModernStatItem: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    let accessibilityManager: AccessibilityManager
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: accessibilityManager.bodyFontSize + 2))
                .foregroundStyle(color)
            
            Text(value)
                .font(.system(size: accessibilityManager.titleFontSize - 4, weight: .bold))
                .foregroundStyle(accessibilityManager.primaryTextColor)
            
            Text(label)
                .font(.system(size: accessibilityManager.captionFontSize - 2))
                .foregroundStyle(accessibilityManager.secondaryTextColor)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Supporting Views (Anotaciones Mejoradas)

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
                        .frame(width: isSelected ? 56 : 44, height: isSelected ? 56 : 44)
                        .shadow(color: colorForIssue(location.issueName).opacity(0.5), radius: 8, y: 4)
                    
                    // Borde blanco para mejor visibilidad
                    Circle()
                        .stroke(Color.white, lineWidth: isSelected ? 3 : 2)
                        .frame(width: isSelected ? 56 : 44, height: isSelected ? 56 : 44)
                    
                    VStack(spacing: 3) {
                        Image(systemName: iconForIssue(location.issueName))
                            .font(.system(size: isSelected ? 20 : 16, weight: .bold))
                            .foregroundStyle(.white)
                        
                        if location.count > 1 {
                            Text("\(location.count)")
                                .font(.system(size: isSelected ? 13 : 11, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(Color.black.opacity(0.3))
                                )
                        }
                    }
                }
                
                // Punta del pin mejorada
                Circle()
                    .fill(colorForIssue(location.issueName))
                    .frame(width: 10, height: 10)
                    .offset(y: -5)
                    .shadow(color: .black.opacity(0.2), radius: 2, y: 2)
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.15 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        .sensoryFeedback(.impact(weight: .light), trigger: isSelected)
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
            return Color(red: 0.9, green: 0.75, blue: 0.2)
        default:
            return .blue
        }
    }
}

// MARK: - Sheet de Detalle Mejorado

struct LocationDetailSheet: View {
    let location: DiagnosisLocation
    let accessibilityManager: AccessibilityManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Fondo crema
            Color(red: 0.98, green: 0.96, blue: 0.93)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Handle
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 5)
                    .padding(.top, 12)
                
                // Header con icono grande
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(colorForIssue(location.issueName))
                            .frame(width: 80, height: 80)
                            .shadow(color: colorForIssue(location.issueName).opacity(0.3), radius: 8, y: 4)
                        
                        Image(systemName: iconForIssue(location.issueName))
                            .font(.system(size: 36, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text(location.issueName)
                            .font(.system(size: accessibilityManager.titleFontSize, weight: .bold))
                            .foregroundStyle(accessibilityManager.primaryTextColor)
                        
                        HStack(spacing: 6) {
                            Image(systemName: "chart.bar.fill")
                            Text("\(location.count) diagnóstico\(location.count > 1 ? "s" : "")")
                        }
                        .font(.system(size: accessibilityManager.bodyFontSize))
                        .foregroundStyle(accessibilityManager.secondaryTextColor)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                
                // Información detallada en tarjetas
                VStack(spacing: 16) {
                    // Ubicación
                    InfoCard(
                        icon: "mappin.circle.fill",
                        title: "Ubicación",
                        items: [
                            "Lat: \(String(format: "%.6f", location.coordinate.latitude))",
                            "Lon: \(String(format: "%.6f", location.coordinate.longitude))"
                        ],
                        accessibilityManager: accessibilityManager
                    )
                    
                    // Fecha del último diagnóstico
                    if let lastDate = location.lastDiagnosis {
                        InfoCard(
                            icon: "clock.fill",
                            title: "Último Diagnóstico",
                            items: [lastDate.formatted(date: .long, time: .shortened)],
                            accessibilityManager: accessibilityManager
                        )
                    }
                    
                    // Nombre del lugar si existe
                    if let placeName = location.locationName {
                        InfoCard(
                            icon: "location.fill",
                            title: "Lugar",
                            items: [placeName],
                            accessibilityManager: accessibilityManager
                        )
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer()
            }
        }
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
            return Color(red: 0.9, green: 0.75, blue: 0.2)
        default:
            return .blue
        }
    }
}

struct InfoCard: View {
    let icon: String
    let title: String
    let items: [String]
    let accessibilityManager: AccessibilityManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: accessibilityManager.bodyFontSize))
                    .foregroundStyle(accessibilityManager.secondaryTextColor)
                
                Text(title)
                    .font(.system(size: accessibilityManager.bodyFontSize, weight: .semibold))
                    .foregroundStyle(accessibilityManager.primaryTextColor)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                ForEach(items, id: \.self) { item in
                    Text(item)
                        .font(.system(size: accessibilityManager.captionFontSize))
                        .foregroundStyle(accessibilityManager.secondaryTextColor)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
        )
    }
}

// MARK: - Data Models

struct DiagnosisLocation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let issueName: String
    let count: Int
    let lastDiagnosis: Date?
    let locationName: String?
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
        self.cameraPosition = .region(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 16.7569, longitude: -93.1292),
            span: MKCoordinateSpan(latitudeDelta: 1.0, longitudeDelta: 1.0)
        ))
    }
    
    func loadDiagnoses() {
        do {
            let diagnoses = try dataService.fetchAllDiagnoses(limit: 500)
            generateRealLocations(from: diagnoses)
            availableIssues = Array(Set(allLocations.map { $0.issueName })).sorted()
            applyFilter()
            adjustCameraToFitLocations()
        } catch {
            print("❌ Error loading diagnoses: \(error)")
        }
    }
    
    func selectLocation(_ location: DiagnosisLocation) {
        selectedLocation = location
    }
    
    func applyFilter() {
        var filtered = allLocations
        
        if let filter = selectedFilter {
            filtered = filtered.filter { $0.issueName == filter }
        }
        
        if selectedPeriod < 365 {
            let cutoffDate = Calendar.current.date(byAdding: .day, value: -selectedPeriod, to: Date())!
            filtered = filtered.filter { location in
                guard let lastDate = location.lastDiagnosis else { return false }
                return lastDate >= cutoffDate
            }
        }
        
        filteredLocations = filtered
    }
    
    func centerOnUserLocation() {
        // Centrar en la ubicación del usuario con animación
        cameraPosition = .userLocation(fallback: .automatic)
    }
    
    private func generateRealLocations(from diagnoses: [DiagnosisRecord]) {
        let diagnosesWithLocation = diagnoses.filter { $0.hasLocation }
        
        if diagnosesWithLocation.isEmpty {
            generateFallbackSimulatedLocations(from: diagnoses)
            return
        }
        
        var locationGroups: [[DiagnosisRecord]] = []
        
        for diagnosis in diagnosesWithLocation {
            guard let coords = diagnosis.coordinates else { continue }
            let diagnosisLocation = CLLocation(latitude: coords.latitude, longitude: coords.longitude)
            
            var addedToGroup = false
            for (index, group) in locationGroups.enumerated() {
                if let firstInGroup = group.first,
                   let firstCoords = firstInGroup.coordinates {
                    let firstLocation = CLLocation(latitude: firstCoords.latitude, longitude: firstCoords.longitude)
                    
                    if diagnosisLocation.distance(from: firstLocation) < 100 {
                        locationGroups[index].append(diagnosis)
                        addedToGroup = true
                        break
                    }
                }
            }
            
            if !addedToGroup {
                locationGroups.append([diagnosis])
            }
        }
        
        allLocations = locationGroups.flatMap { group -> [DiagnosisLocation] in
            guard let first = group.first,
                  let coords = first.coordinates else { return [] }
            
            let issueGroups = Dictionary(grouping: group) { $0.detectedIssue }
            
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
    
    private func generateFallbackSimulatedLocations(from diagnoses: [DiagnosisRecord]) {
        print("⚠️ No hay diagnósticos con ubicación. Generando datos simulados para demo.")
        
        let grouped = Dictionary(grouping: diagnoses) { $0.detectedIssue }
        let baseLatitude = 16.7569
        let baseLongitude = -93.1292
        
        allLocations = grouped.map { issue, records in
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

// MARK: - Preview

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
