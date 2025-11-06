//
//  KPICard.swift
//  KaapehCopiloto2
//
//  Created by Cafe Swift Team on 05/11/25.
//

import SwiftUI

struct KPICard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(color)
                    .clipShape(Circle())
                    .shadow(color: color.opacity(0.3), radius: 4, y: 2)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(Color(red: 0.2, green: 0.13, blue: 0.07))
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(Color(red: 0.4, green: 0.26, blue: 0.13))
                
                Text(title)
                    .font(.caption)
                    .foregroundStyle(Color(red: 0.5, green: 0.36, blue: 0.23))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(subtitle): \(value). \(title)")
    }
}

#Preview {
    ZStack {
        Color.black
        KPICard(
            title: "Precisión Percibida",
            value: "92.5%",
            subtitle: "TPP",
            icon: "checkmark.seal.fill",
            color: .green
        )
        .padding()
    }
}
