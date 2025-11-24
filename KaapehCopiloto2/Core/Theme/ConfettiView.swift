//
//  ConfettiView.swift
//  KaapehCopiloto2
//
//  Vista de animación de confetti para celebrar completar tareas
//

import SwiftUI

// MARK: - Confetti Piece Model

struct ConfettiPiece: Identifiable {
    let id = UUID()
    let color: Color
    var x: CGFloat
    var y: CGFloat
    var rotation: Double
    let scale: CGFloat
    
    static func random(width: CGFloat) -> ConfettiPiece {
        let colors: [Color] = [.red, .blue, .green, .yellow, .orange, .purple, .pink]
        
        return ConfettiPiece(
            color: colors.randomElement() ?? .blue,
            x: CGFloat.random(in: 0...width),
            y: -50,
            rotation: Double.random(in: 0...360),
            scale: CGFloat.random(in: 0.5...1.5)
        )
    }
}

// MARK: - Confetti View

struct ConfettiView: View {
    let trigger: Bool
    
    @State private var pieces: [ConfettiPiece] = []
    @State private var animationComplete: Bool = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(pieces) { piece in
                    Circle()
                        .fill(piece.color)
                        .frame(width: 8, height: 8)
                        .scaleEffect(piece.scale)
                        .rotationEffect(.degrees(piece.rotation))
                        .position(x: piece.x, y: piece.y)
                }
            }
            .onChange(of: trigger) { _, newValue in
                if newValue {
                    startConfetti(width: geometry.size.width, height: geometry.size.height)
                }
            }
        }
        .allowsHitTesting(false)
    }
    
    private func startConfetti(width: CGFloat, height: CGFloat) {
        pieces = []
        animationComplete = false
        
        // Crear 50 piezas de confetti
        for _ in 0..<50 {
            pieces.append(ConfettiPiece.random(width: width))
        }
        
        // Animar cada pieza con un ligero delay
        for (index, _) in pieces.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.02) {
                animatePiece(index: index, height: height)
            }
        }
        
        // Limpiar después de 3 segundos
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation {
                pieces = []
                animationComplete = true
            }
        }
    }
    
    private func animatePiece(index: Int, height: CGFloat) {
        guard index < pieces.count else { return }
        
        withAnimation(
            .spring(response: 1.5, dampingFraction: 0.6)
            .delay(Double.random(in: 0...0.3))
        ) {
            pieces[index].x += CGFloat.random(in: -100...100)
            pieces[index].y = height + 50
            pieces[index].rotation += Double.random(in: 360...720)
        }
    }
}

// MARK: - Confetti Modifier

struct ConfettiModifier: ViewModifier {
    @Binding var isActive: Bool
    
    func body(content: Content) -> some View {
        content
            .overlay(
                ConfettiView(trigger: isActive)
            )
    }
}

extension View {
    func confetti(isActive: Binding<Bool>) -> some View {
        self.modifier(ConfettiModifier(isActive: isActive))
    }
}
