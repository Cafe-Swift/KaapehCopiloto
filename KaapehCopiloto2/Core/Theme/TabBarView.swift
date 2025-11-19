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
            
            // Tab 3: Chat Copiloto
            CopilotChatView()
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
    }
}

struct TechnicianTabBarView: View {
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
            
            // Tab 2: Mapa (placeholder para Sprint 2)
            VStack {
                Image(systemName: "map.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(Color(red: 0.4, green: 0.26, blue: 0.13).opacity(0.3))
                Text("Mapa de Actividad")
                    .font(.title2.bold())
                    .foregroundStyle(Color(red: 0.2, green: 0.13, blue: 0.07))
                Text("Disponible en Sprint 2")
                    .foregroundStyle(Color(red: 0.4, green: 0.26, blue: 0.13))
            }
            .tabItem {
                Label("Mapa", systemImage: "map.fill")
            }
            .tag(1)
        }
        .tint(accessibilityManager.isHighContrastEnabled ? .black : Color(red: 0.4, green: 0.26, blue: 0.13))
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
