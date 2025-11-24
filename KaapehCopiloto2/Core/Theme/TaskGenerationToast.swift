//
//  TaskGenerationToast.swift
//  KaapehCopiloto2
//
//  Toast notification para indicar generación de tareas
//

import SwiftUI

struct TaskGenerationToast: View {
    let message: String
    let isGenerating: Bool
    
    @Environment(AccessibilityManager.self) private var accessibilityManager
    
    var body: some View {
        HStack(spacing: 12) {
            if isGenerating {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(0.9)
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.white)
            }
            
            Text(message)
                .font(.system(size: accessibilityManager.isLargeTextEnabled ? 16 : 14, weight: .medium))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isGenerating ? AppTheme.Colors.coffeeBrown : AppTheme.Colors.coffeeGreen)
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 4)
        )
        .padding(.horizontal, 20)
    }
}

// MARK: - Toast Modifier

struct ToastModifier: ViewModifier {
    @Binding var isShowing: Bool
    let message: String
    let isGenerating: Bool
    let duration: TimeInterval
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if isShowing {
                VStack {
                    Spacer()
                    
                    TaskGenerationToast(message: message, isGenerating: isGenerating)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isShowing)
                    
                    Spacer()
                        .frame(height: 100)
                }
                .zIndex(999)
            }
        }
        .onChange(of: isShowing) { _, newValue in
            if newValue && !isGenerating {
                // Auto-dismiss después de la duración especificada
                Task {
                    try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
                    withAnimation {
                        isShowing = false
                    }
                }
            }
        }
    }
}

extension View {
    func taskGenerationToast(
        isShowing: Binding<Bool>,
        message: String,
        isGenerating: Bool = false,
        duration: TimeInterval = 3.0
    ) -> some View {
        self.modifier(
            ToastModifier(
                isShowing: isShowing,
                message: message,
                isGenerating: isGenerating,
                duration: duration
            )
        )
    }
}
