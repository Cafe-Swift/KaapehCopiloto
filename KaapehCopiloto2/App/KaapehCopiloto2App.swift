//
//  KaapehCopiloto2App.swift
//  KaapehCopiloto2
//
//  Created by Marco Antonio Torres Ramirez on 05/11/25.
//

import SwiftUI
import SwiftData

@main
struct KaapehCopiloto2App: App {
   @State private var appViewModel = AppViewModel()
   
   let modelContainer: ModelContainer
   
   init() {
       // Configurar SwiftData con manejo de errores robusto
       do {
           let schema = Schema([
               UserProfile.self,
               AccessibilityConfig.self,
               DiagnosisRecord.self,
               ActionItem.self
           ])
           
           let modelConfiguration = ModelConfiguration(
               schema: schema,
               isStoredInMemoryOnly: false,
               cloudKitDatabase: .none
           )
           
           modelContainer = try ModelContainer(
               for: schema,
               configurations: [modelConfiguration]
           )
           
           // Configurar el servicio compartido con el contenedor
           SwiftDataService.shared.configure(with: modelContainer)
           
       } catch {
           fatalError("No se pudo inicializar SwiftData: \(error.localizedDescription)")
       }
   }
   
   var body: some Scene {
       WindowGroup {
           RootView()
               .environment(appViewModel)
               .environment(appViewModel.accessibilityManager)
               .modelContainer(modelContainer)
               .onAppear {
                   Task {
                       await appViewModel.initializeApp()
                   }
               }
       }
   }
}
