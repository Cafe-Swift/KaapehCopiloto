//
//  MainView.swift
//  KaapehCopiloto2
//
//  Created by Cafe Swift Team on 05/11/25.
//

import SwiftUI
import SwiftData

/// Main view that routes to appropriate screen based on user role
struct MainView: View {
    let user: UserProfile
    @Environment(\.modelContext) private var modelContext
    @Environment(AppViewModel.self) private var appViewModel
    
    var body: some View {
        Group {
            if user.role == "Técnico" {
                TechnicianTabBarView(authViewModel: Binding(
                    get: { appViewModel.authViewModel },
                    set: { _ in }
                ))
            } else {
                ProducerTabBarView(user: user)
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: UserProfile.self, AccessibilityConfig.self, DiagnosisRecord.self, ActionItem.self,
        configurations: config
    )
    
    let user = UserProfile(userName: "testuser", role: "Productor")
    
    MainView(user: user)
        .modelContainer(container)
}
