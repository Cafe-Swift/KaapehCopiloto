//
//  ContentView.swift
//  KaapehCopiloto
//
//  Created by Cafe Swift on 27/10/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var appState = AppStateViewModel()
    
    var body: some View {
        Group {
            if appState.isLoading {
                // Pantalla de carga
                LoadingView()
            } else if !appState.isAuthenticated {
                // Pantalla de autenticación
                AuthenticationView()
                    .environmentObject(appState)
            } else if appState.needsOnboarding {
                // Pantalla de onboarding
                OnboardingView()
                    .environmentObject(appState)
            } else {
                // Pantalla principal según el rol
                if appState.currentUser?.role == "Técnico" {
                    TechnicianMainView()
                        .environmentObject(appState)
                } else {
                    ProducerMainView()
                        .environmentObject(appState)
                }
            }
        }
    }
}

//  Loading View
struct LoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "leaf.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
                .accessibilityLabel("Logo de Káapeh Copiloto")
            
            Text("Káapeh Copiloto")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .green))
                .scaleEffect(1.5)
                .padding(.top, 20)
        }
    }
}

//  Technician Main View (Placeholder)
struct TechnicianMainView: View {
    @EnvironmentObject var appState: AppStateViewModel
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Image(systemName: "chart.bar.doc.horizontal")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("Dashboard Técnico")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Próximamente en Sprint 3")
                    .font(.title3)
                    .foregroundColor(.secondary)
                
                Button("Cerrar Sesión") {
                    appState.logout()
                }
                .buttonStyle(.borderedProminent)
            }
            .navigationTitle("Técnico")
        }
    }
}

#Preview {
    ContentView()
}
