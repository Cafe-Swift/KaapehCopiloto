//
//  LogConfig.swift
//  KaapehCopiloto2
//
//

import Foundation

/// Niveles de log
enum LogLevel: Int, Comparable {
    case none = 0      // Sin logs
    case error = 1     // Solo errores críticos
    case warning = 2   // Errores + advertencias
    case info = 3      // Errores + advertencias + info general
    case debug = 4     // Todo (modo desarrollo)
    
    static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

/// Categorías de log para filtrar específicamente
enum LogCategory: String {
    case app = "APP"
    case rag = "RAG"
    case voice = "VOICE"
    case sync = "SYNC"
    case db = "DB"
    case ui = "UI"
}

/// Configuración global de logs
final class LogConfig {
    
    #if DEBUG
    static var currentLevel: LogLevel = .debug
    #else
    static var currentLevel: LogLevel = .warning
    #endif
    
    // Categorías deshabilitadas (para silenciar spam específico)
    static var disabledCategories: Set<LogCategory> = []
    
    /// Log básico con nivel y categoría
    static func log(
        _ message: String,
        level: LogLevel = .info,
        category: LogCategory = .app,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        // Filtrar por nivel
        guard level.rawValue <= currentLevel.rawValue else { return }
        
        // Filtrar por categoría deshabilitada
        guard !disabledCategories.contains(category) else { return }
        
        // Obtener nombre de archivo limpio
        let fileName = (file as NSString).lastPathComponent
        
        // Emoji según nivel
        let emoji: String
        switch level {
        case .none:
            return
        case .error:
            emoji = "❌"
        case .warning:
            emoji = "⚠️"
        case .info:
            emoji = "ℹ️"
        case .debug:
            emoji = "🔍"
        }
        
        // Formato: [EMOJI] [CATEGORY] mensaje
        print("\(emoji) [\(category.rawValue)] \(message)")
        
        // En debug, agregar info de archivo/línea para errores
        #if DEBUG
        if level == .error {
            print("   └─ \(fileName):\(line) \(function)")
        }
        #endif
    }
    
    /// Shorthand para errores
    static func error(
        _ message: String,
        category: LogCategory = .app,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .error, category: category, file: file, function: function, line: line)
    }
    
    /// Shorthand para warnings
    static func warning(
        _ message: String,
        category: LogCategory = .app
    ) {
        log(message, level: .warning, category: category)
    }
    
    /// Shorthand para info
    static func info(
        _ message: String,
        category: LogCategory = .app
    ) {
        log(message, level: .info, category: category)
    }
    
    /// Shorthand para debug
    static func debug(
        _ message: String,
        category: LogCategory = .app
    ) {
        log(message, level: .debug, category: category)
    }
}
