//
//  ContentView.swift
//  KaapehCopiloto2
//
//  Created by Cafe Swift on 05/11/2025.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppViewModel.self) private var appViewModel
    
    var body: some View {
        Group {
            if appViewModel.isCheckingAuth {
                // Loading state
                ProgressView("Cargando...")
                    .progressViewStyle(.circular)
                    .scaleEffect(1.5)
            } else {
                // Main content based on authentication state
                if appViewModel.authViewModel.isAuthenticated {
                    if let user = appViewModel.authViewModel.currentUser {
                        MainView(user: user)
                    }
                } else {
                    LoginView(viewModel: appViewModel.authViewModel)
                }
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: UserProfile.self, DiagnosisRecord.self, AccessibilityConfig.self, ActionItem.self,
        configurations: config
    )
    
    ContentView()
        .environment(AppViewModel())
        .modelContainer(container)
}
