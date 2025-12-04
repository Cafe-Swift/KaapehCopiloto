//
//  TabBarView.swift
//  KaapehCopiloto2
//
//  Created by Cafe Swift Team on 11/11/25.
//

import SwiftUI

struct ProducerTabBarView: View {
    let user: UserProfile
    @State private var selectedTab = 0
    @Environment(AccessibilityManager.self) private var accessibilityManager
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: Home
            ProducerHomeView(user: user, selectedTab: $selectedTab, swiftDataService: SwiftDataService.shared)
                .tabItem {
                    Label("Inicio", systemImage: "house.fill")
                }
                .tag(0)
            
            // Tab 2: Nuevo Diagnóstico
            DiagnosisCameraView(user: user)
                .tabItem {
                    Label("Diagnóstico", systemImage: "camera.fill")
                }
                .tag(1)
            
            // Tab 3: Chat Multimodal (Texto + Voz)
            MultimodalChatView()
                .tabItem {
                    Label("Copiloto", systemImage: "message.fill")
                }
                .tag(2)
            
            // Tab 4: Historial
            HistoryListView(user: user)
                .tabItem {
                    Label("Historial", systemImage: "clock.fill")
                }
                .tag(3)
            
            // Tab 5: Configuración
            SettingsView(user: user)
                .tabItem {
                    Label("Ajustes", systemImage: "gearshape.fill")
                }
                .tag(4)
        }
        .tint(accessibilityManager.isHighContrastEnabled ? .black : Color(red: 0.4, green: 0.26, blue: 0.13))
        .sensoryFeedback(.selection, trigger: selectedTab)
    }
}

struct TechnicianTabBarView: View {
    let user: UserProfile // Agregar user
    @State private var selectedTab = 0
    @Binding var authViewModel: AuthenticationViewModel
    @Environment(AccessibilityManager.self) private var accessibilityManager
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: Dashboard
            TechnicianDashboardView(
                swiftDataService: SwiftDataService.shared,
                authToken: nil,
                authViewModel: authViewModel
            )
            .tabItem {
                Label("Dashboard", systemImage: "chart.bar.fill")
            }
            .tag(0)
            
            // Tab 2: Mapa de Actividad
            ActivityMapView(user: user)
                .tabItem {
                    Label("Mapa", systemImage: "map.fill")
                }
                .tag(1)
        }
        .tint(accessibilityManager.isHighContrastEnabled ? .black : Color(red: 0.4, green: 0.26, blue: 0.13))
        .sensoryFeedback(.selection, trigger: selectedTab)
    }
}

#Preview("Productor Tab Bar") {
    ProducerTabBarView(user: UserProfile(
        userName: "preview_user",
        role: "Productor",
        preferredLanguage: "es"
    ))
    .environment(AccessibilityManager.shared)
}
