//
//  LiquidGlassComponents.swift
//  KaapehCopiloto2
//
//  Biblioteca de componentes reutilizables con diseño "Liquid Glass"
//

import SwiftUI

// MARK: - LiquidGlassHeader
/// Header flotante moderno para reemplazar la barra de navegación café
struct LiquidGlassHeader: View {
    let title: String
    let subtitle: String?
    let icon: String?
    let trailingContent: AnyView?
    let accessibilityManager: AccessibilityManager
    
    init(
        title: String,
        subtitle: String? = nil,
        icon: String? = nil,
        accessibilityManager: AccessibilityManager,
        @ViewBuilder trailingContent: () -> AnyView = { AnyView(EmptyView()) }
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.accessibilityManager = accessibilityManager
        self.trailingContent = trailingContent()
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 10) {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.system(size: accessibilityManager.titleFontSize))
                            .foregroundStyle(AppTheme.Colors.coffeeBrown)
                    }
                    
                    Text(title)
                        .font(.system(size: accessibilityManager.titleFontSize, weight: .bold))
                        .foregroundStyle(Color(red: 0.2, green: 0.13, blue: 0.07))
                }
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: accessibilityManager.captionFontSize))
                        .foregroundStyle(Color(red: 0.4, green: 0.26, blue: 0.13))
                }
            }
            
            Spacer()
            
            trailingContent
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.15), radius: 12, y: 6)
        )
    }
}

// MARK: - LiquidGlassActionCard
/// Tarjeta de acción principal con gradiente y animaciones
struct LiquidGlassActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let gradient: LinearGradient
    let accentColor: Color
    let accessibilityManager: AccessibilityManager
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(gradient)
                        .frame(width: 60, height: 60)
                        .shadow(color: accentColor.opacity(0.3), radius: 8, y: 4)
                    
                    Image(systemName: icon)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: accessibilityManager.bodyFontSize + 2, weight: .bold))
                        .foregroundStyle(Color(red: 0.2, green: 0.13, blue: 0.07))
                    
                    Text(subtitle)
                        .font(.system(size: accessibilityManager.captionFontSize))
                        .foregroundStyle(Color(red: 0.4, green: 0.26, blue: 0.13))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color(red: 0.4, green: 0.26, blue: 0.13))
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
            )
            .scaleEffect(isPressed ? 0.97 : 1.0)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isPressed = pressing
            }
        }, perform: {})
        .sensoryFeedback(.selection, trigger: isPressed)
    }
}

// MARK: - LiquidGlassStatsBar
/// Barra de estadísticas con divisores verticales
struct LiquidGlassStatsBar: View {
    let stats: [StatItem]
    let accessibilityManager: AccessibilityManager
    
    struct StatItem: Identifiable {
        let id = UUID()
        let icon: String
        let value: String
        let label: String
        let color: Color
    }
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(stats.enumerated()), id: \.element.id) { index, stat in
                ModernStatItem(
                    icon: stat.icon,
                    value: stat.value,
                    label: stat.label,
                    color: stat.color,
                    accessibilityManager: accessibilityManager
                )
                
                if index < stats.count - 1 {
                    Rectangle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 1, height: 50)
                }
            }
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.15), radius: 12, y: 6)
        )
    }
}







// MARK: - LiquidGlassButton
/// Botón moderno con efecto de vidrio y feedback háptico
struct LiquidGlassButton: View {
    let title: String
    let icon: String?
    let style: ButtonStyleType
    let accessibilityManager: AccessibilityManager
    let action: () -> Void
    
    @State private var isPressed = false
    
    enum ButtonStyleType {
        case primary
        case secondary
        case destructive
        
        var backgroundColor: Color {
            switch self {
            case .primary: return Color(red: 0.4, green: 0.26, blue: 0.13)
            case .secondary: return .white
            case .destructive: return .red
            }
        }
        
        var foregroundColor: Color {
            switch self {
            case .primary: return .white
            case .secondary: return Color(red: 0.2, green: 0.13, blue: 0.07)
            case .destructive: return .white
            }
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: accessibilityManager.bodyFontSize))
                }
                
                Text(title)
                    .font(.system(size: accessibilityManager.bodyFontSize, weight: .semibold))
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(style.backgroundColor)
                    .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
            )
            .foregroundStyle(style.foregroundColor)
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isPressed = pressing
            }
        }, perform: {})
        .sensoryFeedback(.selection, trigger: isPressed)
    }
}

// MARK: - LiquidGlassTextField
/// Campo de texto moderno con efecto de vidrio
struct LiquidGlassTextField: View {
    let placeholder: String
    let icon: String
    @Binding var text: String
    let accessibilityManager: AccessibilityManager
    var isSecure: Bool = false
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: accessibilityManager.bodyFontSize))
                .foregroundStyle(Color(red: 0.4, green: 0.26, blue: 0.13))
            
            if isSecure {
                SecureField(placeholder, text: $text)
                    .font(.system(size: accessibilityManager.bodyFontSize))
                    .focused($isFocused)
            } else {
                TextField(placeholder, text: $text)
                    .font(.system(size: accessibilityManager.bodyFontSize))
                    .focused($isFocused)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isFocused ? Color(red: 0.4, green: 0.26, blue: 0.13) : Color.clear, lineWidth: 2)
                )
                .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isFocused)
    }
}

// MARK: - LiquidGlassCircleButton
/// Botón circular flotante para acciones rápidas
struct LiquidGlassCircleButton: View {
    let icon: String
    let size: CGFloat
    let backgroundColor: Color
    let foregroundColor: Color
    let action: () -> Void
    
    @State private var isPressed = false
    
    init(
        icon: String,
        size: CGFloat = 44,
        backgroundColor: Color = .white,
        foregroundColor: Color = Color(red: 0.4, green: 0.26, blue: 0.13),
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.size = size
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(backgroundColor)
                    .frame(width: size, height: size)
                    .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                
                Image(systemName: icon)
                    .font(.system(size: size * 0.45, weight: .semibold))
                    .foregroundStyle(foregroundColor)
            }
            .scaleEffect(isPressed ? 0.9 : 1.0)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isPressed = pressing
            }
        }, perform: {})
        .sensoryFeedback(.impact(weight: .medium), trigger: isPressed)
    }
}

// MARK: - View Extensions
extension View {
    /// Aplica el estilo de tarjeta moderna a cualquier vista
    func modernCard(padding: CGFloat = 20, cornerRadius: CGFloat = 24) -> some View {
        self
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.15), radius: 12, y: 6)
            )
    }
    
    /// Aplica el estilo de tarjeta simple con fondo blanco
    func simpleCard(padding: CGFloat = 16, cornerRadius: CGFloat = 16) -> some View {
        self
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
            )
    }
}

// MARK: - Animation Presets
enum AnimationPresets {
    static let spring = Animation.spring(response: 0.3, dampingFraction: 0.7)
    static let smooth = Animation.smooth(duration: 0.3)
    static let easeInOut = Animation.easeInOut(duration: 0.3)
}
