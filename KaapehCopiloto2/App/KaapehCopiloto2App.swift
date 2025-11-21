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
       // Configurar SwiftData con manejo de errores y migración automática
       do {
           let schema = Schema([
               UserProfile.self,
               AccessibilityConfig.self,
               DiagnosisRecord.self,
               ActionItem.self,
               Conversation.self 
           ])
           
           let modelConfiguration = ModelConfiguration(
               schema: schema,
               isStoredInMemoryOnly: false,
               cloudKitDatabase: .none
           )
           
           do {
               modelContainer = try ModelContainer(
                   for: schema,
                   configurations: [modelConfiguration]
               )
               
               print("✅ SwiftData inicializado correctamente")
               
           } catch {
               // Si falla la migración, borrar la BD antigua y crear una nueva
               print("⚠️ Error al inicializar SwiftData: \(error)")
               print("🗑️ Borrando base de datos antigua...")
               
               Self.deleteOldDatabase()
               
               // Reintentar con BD limpia
               modelContainer = try ModelContainer(
                   for: schema,
                   configurations: [modelConfiguration]
               )
               
               print("✅ SwiftData inicializado con BD nueva")
           }
           
           // Configurar el servicio compartido con el contenedor
           SwiftDataService.shared.configure(with: modelContainer)
           
       } catch {
           fatalError("No se pudo inicializar SwiftData: \(error.localizedDescription)")
       }
   }
   
   /// Borra la base de datos antigua para permitir migración limpia
   private static func deleteOldDatabase() {
       let fileManager = FileManager.default
       
       // Obtener el directorio de Application Support
       guard let appSupport = fileManager.urls(
           for: .applicationSupportDirectory,
           in: .userDomainMask
       ).first else {
           print("⚠️ No se pudo encontrar Application Support")
           return
       }
       
       // Lista de archivos de base de datos a borrar
       let dbFiles = [
           "default.store",
           "default.store-shm",
           "default.store-wal"
       ]
       
       for fileName in dbFiles {
           let fileURL = appSupport.appendingPathComponent(fileName)
           
           if fileManager.fileExists(atPath: fileURL.path) {
               do {
                   try fileManager.removeItem(at: fileURL)
                   print("🗑️ Borrado: \(fileName)")
               } catch {
                   print("⚠️ No se pudo borrar \(fileName): \(error)")
               }
           }
       }
       
       print("✅ Limpieza de BD completada")
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
