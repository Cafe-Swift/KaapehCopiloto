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
    @ObservedObject private var translator = KaapehTranslator.shared
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: Home
            ProducerHomeView(user: user, selectedTab: $selectedTab, swiftDataService: SwiftDataService.shared)
                .tabItem {
                    Label(translator.t("Inicio"), systemImage: "house.fill")
                }
                .tag(0)
            
            // Tab 2: Nuevo Diagnóstico
            DiagnosisCameraView(user: user)
                .tabItem {
                    Label(translator.t("Diagnóstico"), systemImage: "camera.fill")
                }
                .tag(1)
            
            // Tab 3: Chat Multimodal (Texto + Voz)
            MultimodalChatView()
                .tabItem {
                    Label(translator.t("Copiloto"), systemImage: "message.fill")
                }
                .tag(2)
            
            // Tab 4: Historial
            NavigationStack {
                HistoryListView(user: user)
                    .navigationBarHidden(true)
            }
            .tabItem {
                Label(translator.t("Historial"), systemImage: "clock.fill")
            }
            .tag(3)
            
            // Tab 5: Configuración
            SettingsView(user: user)
                .tabItem {
                    Label(translator.t("Ajustes"), systemImage: "gearshape.fill")
                }
                .tag(4)
        }
        .tint(accessibilityManager.isHighContrastEnabled ? .black : Color(red: 0.4, green: 0.26, blue: 0.13))
        .sensoryFeedback(.selection, trigger: selectedTab)
    }
}

struct TechnicianTabBarView: View {
    let user: UserProfile
    @State private var selectedTab = 0
    @Binding var authViewModel: AuthenticationViewModel
    @Environment(AccessibilityManager.self) private var accessibilityManager
    @ObservedObject private var translator = KaapehTranslator.shared
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: Dashboard
            TechnicianDashboardView(
                swiftDataService: SwiftDataService.shared,
                authToken: nil,
                authViewModel: authViewModel
            )
            .tabItem {
                Label(translator.t("Dashboard"), systemImage: "chart.bar.fill")
            }
            .tag(0)
            
            // Tab 2: Mapa de Actividad
            ActivityMapView(user: user)
                .tabItem {
                    Label(translator.t("Mapa"), systemImage: "map.fill")
                }
                .tag(1)
            
            // Tab 3: Ajustes
            SettingsView(user: user)
                .tabItem {
                    Label(translator.t("Ajustes"), systemImage: "gearshape.fill")
                }
                .tag(2)
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
