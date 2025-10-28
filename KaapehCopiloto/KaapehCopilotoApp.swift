//
//  KaapehCopilotoApp.swift
//  KaapehCopiloto
//
//  Created by Marco Antonio Torres Ramirez on 27/10/25.
//

import SwiftUI
import SwiftData

@main
struct KaapehCopilotoApp: App {
    
    init() {
        // Inicializar SwiftData al arranque
        _ = SwiftDataService.shared
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(SwiftDataService.shared.modelContainer!)
    }
}
