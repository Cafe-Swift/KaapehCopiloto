//
//  AuthenticationView.swift
//  KaapehCopiloto
//
//  Created by Cafe Swift on 28/10/25.
//

import SwiftUI

struct AuthenticationView: View {
    @EnvironmentObject var appState: AppStateViewModel
    @State private var userName: String = ""
    @State private var selectedRole: String = "Productor"
    @State private var selectedLanguage: String = "es"
    
    let roles = ["Productor", "Técnico"]
    let languages = [
        ("es", "Español"),
        ("tsz", "Tsotsil")
    ]
    
    var body: some View {
        ZStack {
            //fondo co gradiente
            LinearGradient(
                gradient: Gradient(colors: [Color.green.opacity(0.3), Color.brown.opacity(0.2)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack (spacing: 30) {
                // logo y titulo
                VStack (spacing: 10) {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(.green)
                        .accessibilityLabel("Logo de Káapeh Copiloto")
                    
                    Text("Káapeh Copiloto")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .accessibilityAddTraits(.isHeader)
                    
                    Text("Tu cafetal inteligente, en tu bolsillo")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                
                // formulario de registro
                VStack (spacing: 20) {
                    // nombre de usuario
                    VStack (alignment: .leading, spacing: 8) {
                        Text("Nombre de usuario")
                            .font(.headline)
                            .accessibilityAddTraits(.isHeader)
                        
                        TextField("Ingresa tu nombre", text: $userName)
                            .textFieldStyle(.roundedBorder)
                            .padding(.horizontal)
                            .accessibilityLabel("Campo de nombre de usuario")
                            .accessibilityHint("Ingresa tu nombre de usuario aquí")
                    }
                    
                    // rol
                    VStack (alignment: .leading, spacing: 8) {
                        Text("Soy un...")
                            .font(.headline)
                            .accessibilityAddTraits(.isHeader)
                        
                        Picker("Rol", selection: $selectedRole) {
                            ForEach(roles, id: \.self) { role in
                                Text(role).tag(role)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                        .accessibilityLabel("Selector de rol")
                    }
                    
                    // idioma
                    VStack (alignment: .leading, spacing: 8)  {
                        Text("Idioma preferido")
                            .font(.headline)
                            .accessibilityAddTraits(.isHeader)
                        
                        Picker("Idioma", selection: $selectedLanguage) {
                            ForEach(languages, id: \.0) { code, name in
                                Text(name).tag(code)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                        .accessibilityLabel("Selector de idioma")
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(15)
                .shadow(radius: 5)
                .padding(.horizontal)
                
                // boton de continuar
                Button(action: register) {
                    Text("Continuar")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isValidInput ? Color.green : Color.gray)
                        .cornerRadius(10)
                }
                .disabled(!isValidInput)
                .padding(.horizontal)
                .accessibilityLabel("Botón de continuar")
                .accessibilityHint(isValidInput ? "Toca para continuar con el registro" : "Completa todos los campos para continuar")
                
                Spacer()
            }
        }
    }
    
    private var isValidInput: Bool {
        userName.trimmingCharacters(in: .whitespacesAndNewlines).count >= 3
    }
    
    private func register() {
        appState.register(
            userName: userName,
            role: selectedRole,
            preferredLanguage: selectedLanguage
        )
    }
}

#Preview {
    AuthenticationView()
        .environmentObject(AppStateViewModel())
}
