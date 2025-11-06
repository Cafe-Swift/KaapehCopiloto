//
//  AppTheme.swift
//  KaapehCopiloto2
//
//  Created by Cafe Swift Team on 06/11/25.
//

import SwiftUI

/// Káapeh Copiloto Design System 
struct AppTheme {
    
    // MARK: - Colors
    struct Colors {
        // Primary Brown Palette
        static let coffeeBrown = Color(red: 0.4, green: 0.26, blue: 0.13)
        static let lightBrown = Color(red: 0.6, green: 0.4, blue: 0.2)
        static let darkBrown = Color(red: 0.25, green: 0.16, blue: 0.08)
        static let creamBrown = Color(red: 0.85, green: 0.75, blue: 0.65)
        
        // Accent Colors
        static let coffeeGreen = Color(red: 0.2, green: 0.5, blue: 0.3)
        static let espresso = Color(red: 0.2, green: 0.13, blue: 0.07)
        
        // Status Colors
        static let healthy = Color.green
        static let warning = Color.orange
        static let error = Color.red
        
        // Glass Effects
        static let glassOverlay = Color.white.opacity(0.15)
        static let glassBorder = Color.white.opacity(0.3)
    }
    
    // MARK: - Gradients
    struct Gradients {
        static let coffeeGradient = LinearGradient(
            colors: [Colors.coffeeBrown, Colors.darkBrown],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let lightCoffeeGradient = LinearGradient(
            colors: [Colors.lightBrown, Colors.coffeeBrown],
            startPoint: .top,
            endPoint: .bottom
        )
        
        static let greenCoffeeGradient = LinearGradient(
            colors: [Colors.coffeeGreen, Colors.coffeeBrown],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Typography
    struct Typography {
        static let largeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
        static let title = Font.system(size: 28, weight: .bold, design: .rounded)
        static let headline = Font.system(size: 17, weight: .semibold, design: .rounded)
        static let body = Font.system(size: 17, weight: .regular, design: .default)
        static let caption = Font.system(size: 12, weight: .regular, design: .default)
    }
    
    // MARK: - Spacing
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
    }
    
    // MARK: - Corner Radius
    struct CornerRadius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
    }
}

// MARK: - Liquid Glass Card Modifier
struct LiquidGlassCard: ViewModifier {
    var cornerRadius: CGFloat = AppTheme.CornerRadius.lg
    
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(AppTheme.Colors.glassBorder, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

extension View {
    func liquidGlassCard(cornerRadius: CGFloat = AppTheme.CornerRadius.lg) -> some View {
        modifier(LiquidGlassCard(cornerRadius: cornerRadius))
    }
}

// MARK: - Liquid Glass Background
struct LiquidGlassBackground: View {
    var body: some View {
        ZStack {
            AppTheme.Gradients.coffeeGradient
                .ignoresSafeArea()
            
            // Floating coffee beans effect
            GeometryReader { geometry in
                ForEach(0..<3) { i in
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    AppTheme.Colors.lightBrown.opacity(0.3),
                                    AppTheme.Colors.coffeeBrown.opacity(0.1)
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 150
                            )
                        )
                        .frame(width: 200, height: 200)
                        .offset(
                            x: CGFloat(i) * geometry.size.width / 3 - 100,
                            y: CGFloat(i) * geometry.size.height / 4
                        )
                        .blur(radius: 30)
                }
            }
        }
    }
}
