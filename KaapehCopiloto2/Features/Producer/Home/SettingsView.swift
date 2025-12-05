//
//  SettingsView.swift
//  KaapehCopiloto2
//
//  Created by Cafe Swift Team on 05/11/25.
//

import SwiftUI
import Combine

struct SettingsView: View {
    let user: UserProfile
    @Environment(\.dismiss) private var dismiss
    @Environment(AppViewModel.self) private var appViewModel
    @Environment(AccessibilityManager.self) private var accessibilityManager
    @StateObject private var viewModel: SettingsViewModel
    @ObservedObject private var translator = KaapehTranslator.shared
    
    init(user: UserProfile) {
        self.user = user
        self._viewModel = StateObject(wrappedValue: SettingsViewModel(user: user))
    }
    
    var body: some View {
        ZStack {
            // Fondo degradado adaptable
            LinearGradient(
                colors: [
                    accessibilityManager.backgroundColor,
                    accessibilityManager.backgroundColor.opacity(0.95)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Header flotante moderno (ahora dentro del ScrollView)
                    modernHeader
                        .padding(.top, 10)
                    
                    // Perfil card moderno
                    modernProfileCard
                    
                    // Vista de debug de accesibilidad (oculta pero reactiva)
                    Text("Accesibilidad: Texto Grande: \(accessibilityManager.isLargeTextEnabled ? "ON" : "OFF"), Alto Contraste: \(accessibilityManager.isHighContrastEnabled ? "ON" : "OFF")")
                        .font(.system(size: 1))
                        .foregroundStyle(.clear)
                        .frame(height: 0)
                    
                    // Accesibilidad section moderno
                    modernAccessibilitySection
                    
                    // Idioma section moderno
                    modernLanguageSection
                    
                    // Cuenta section moderno
                    modernAccountSection
                }
                .padding()
            }
        }
    }
    
    // MARK: - Modern Header
    
    private var modernHeader: some View {
        HStack {
            Spacer()
            
            Text(translator.t("Ajustes"))
                .font(.system(size: accessibilityManager.headlineFontSize, weight: .bold))
                .foregroundStyle(accessibilityManager.primaryTextColor)
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.15), radius: 12, y: 6)
        )
    }
    
    // MARK: - Modern Profile Card
    
    private var modernProfileCard: some View {
        HStack(spacing: 16) {
            // Avatar circular con gradiente
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.Colors.coffeeBrown, AppTheme.Colors.coffeeBrown.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 70, height: 70)
                    .shadow(color: AppTheme.Colors.coffeeBrown.opacity(0.4), radius: 12, y: 6)
                
                Text(user.userName.prefix(2).uppercased())
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(user.userName)
                    .font(.system(size: accessibilityManager.titleFontSize, weight: .bold))
                    .foregroundStyle(accessibilityManager.primaryTextColor)
                
                HStack(spacing: 8) {
                    Image(systemName: user.role == "Productor" ? "leaf.fill" : "wrench.and.screwdriver.fill")
                        .font(.system(size: accessibilityManager.captionFontSize))
                        .foregroundStyle(AppTheme.Colors.coffeeGreen)
                    
                    Text(user.role)
                        .font(.system(size: accessibilityManager.bodyFontSize))
                        .foregroundStyle(accessibilityManager.secondaryTextColor)
                }
            }
            
            Spacer()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.15), radius: 12, y: 6)
        )
    }
    
    // MARK: - Modern Accessibility Section
    
    private var modernAccessibilitySection: some View {
        VStack(spacing: 0) {
            // Header de sección
            HStack {
                Image(systemName: "accessibility")
                    .font(.system(size: 18))
                    .foregroundStyle(AppTheme.Colors.coffeeBrown)
                
                Text(translator.t("Accesibilidad"))
                    .font(.system(size: accessibilityManager.headlineFontSize, weight: .bold))
                    .foregroundStyle(accessibilityManager.primaryTextColor)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 12)
            
            // Toggles con diseño moderno
            VStack(spacing: 0) {
                ModernToggleRow(
                    icon: "textformat.size",
                    title: translator.t("Texto Grande"),
                    description: translator.t("Aumenta el tamaño de la fuente"),
                    isOn: $viewModel.largeTextEnabled,
                    color: AppTheme.Colors.coffeeBrown
                )
                
                Divider()
                    .padding(.horizontal, 20)
                
                ModernToggleRow(
                    icon: "circle.lefthalf.filled",
                    title: translator.t("Alto Contraste"),
                    description: translator.t("Mejora la visibilidad del texto"),
                    isOn: $viewModel.highContrastEnabled,
                    color: AppTheme.Colors.coffeeBrown
                )
                
                Divider()
                    .padding(.horizontal, 20)
                
                ModernToggleRow(
                    icon: "mic.fill",
                    title: translator.t("Interacción por Voz"),
                    description: translator.t("Habilita controles de voz"),
                    isOn: $viewModel.voiceInteractionPreferred,
                    color: AppTheme.Colors.coffeeGreen
                )
            }
            .padding(.bottom, 20)
        }
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.15), radius: 12, y: 6)
        )
        .onChange(of: viewModel.largeTextEnabled) { _, _ in
            Task { await viewModel.saveSettings() }
        }
        .onChange(of: viewModel.highContrastEnabled) { _, _ in
            Task { await viewModel.saveSettings() }
        }
        .onChange(of: viewModel.voiceInteractionPreferred) { _, _ in
            Task { await viewModel.saveSettings() }
        }
    }
    
    // MARK: - Modern Language Section
    
    private var modernLanguageSection: some View {
        VStack(spacing: 0) {
            // Header de sección
            HStack {
                Image(systemName: "globe")
                    .font(.system(size: 18))
                    .foregroundStyle(AppTheme.Colors.coffeeGreen)
                
                Text(translator.t("Idioma"))
                    .font(.system(size: accessibilityManager.headlineFontSize, weight: .bold))
                    .foregroundStyle(accessibilityManager.primaryTextColor)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 12)
            
            // Picker moderno
            VStack(spacing: 12) {
                ForEach([("es", "Español", "🇲🇽"), ("tsz", "Tsotsil", "🏔️")], id: \.0) { code, name, emoji in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            viewModel.selectedLanguage = code
                        }
                    } label: {
                        HStack(spacing: 16) {
                            Text(emoji)
                                .font(.system(size: 32))
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(name)
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundStyle(accessibilityManager.primaryTextColor)
                                
                                Text("\(translator.t("Idioma")) \(name.lowercased())")
                                    .font(.system(size: accessibilityManager.captionFontSize))
                                    .foregroundStyle(accessibilityManager.secondaryTextColor)
                            }
                            
                            Spacer()
                            
                            if viewModel.selectedLanguage == code {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundStyle(AppTheme.Colors.coffeeGreen)
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(viewModel.selectedLanguage == code ? AppTheme.Colors.coffeeGreen.opacity(0.1) : Color.white.opacity(0.5))
                        )
                    }
                    .sensoryFeedback(.selection, trigger: viewModel.selectedLanguage)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.15), radius: 12, y: 6)
        )
        .onChange(of: viewModel.selectedLanguage) { _, newLanguage in
            print("🔄 Idioma seleccionado: \(newLanguage)")
            Task { await viewModel.saveSettings() }
        }
    }
    
    // MARK: - Modern Account Section
    
    private var modernAccountSection: some View {
        VStack(spacing: 0) {
            // Header de sección
            HStack {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.red.opacity(0.8))
                
                Text(translator.t("Cuenta"))
                    .font(.system(size: accessibilityManager.headlineFontSize, weight: .bold))
                    .foregroundStyle(accessibilityManager.primaryTextColor)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 12)
            
            // Botón de cerrar sesión moderno
            Button {
                appViewModel.authViewModel.logout()
                dismiss()
            } label: {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.red.opacity(0.15))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 20))
                            .foregroundStyle(.red)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(translator.t("Cerrar Sesión"))
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.red)
                        
                        Text(translator.t("Desconectar de tu cuenta"))
                            .font(.system(size: accessibilityManager.captionFontSize))
                            .foregroundStyle(accessibilityManager.secondaryTextColor)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color(red: 0.6, green: 0.4, blue: 0.2))
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.red.opacity(0.05))
                )
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            .sensoryFeedback(.warning, trigger: appViewModel.authViewModel.isAuthenticated)
        }
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.15), radius: 12, y: 6)
        )
    }
}

// MARK: - Modern Toggle Row Component
struct ModernToggleRow: View {
    let icon: String
    let title: String
    let description: String
    @Binding var isOn: Bool
    let color: Color
    @Environment(AccessibilityManager.self) private var accessibilityManager
    
    var body: some View {
        Toggle(isOn: $isOn) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundStyle(color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(accessibilityManager.primaryTextColor)
                    
                    Text(description)
                        .font(.system(size: 13))
                        .foregroundStyle(accessibilityManager.secondaryTextColor)
                }
            }
        }
        .tint(color)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .sensoryFeedback(.selection, trigger: isOn)
    }
}

// MARK: - ViewModel
@MainActor
final class SettingsViewModel: ObservableObject {
    let user: UserProfile
    @Published var largeTextEnabled: Bool
    @Published var highContrastEnabled: Bool
    @Published var voiceInteractionPreferred: Bool
    @Published var selectedLanguage: String {
        didSet {
            // Sincronizar con KaapehTranslator cuando cambie el idioma
            KaapehTranslator.shared.setLanguage(selectedLanguage)
        }
    }
    
    private let dataService = SwiftDataService.shared
    private let accessibilityManager = AccessibilityManager.shared
    
    init(user: UserProfile) {
        self.user = user
        self.largeTextEnabled = user.accessibilitySettings?.largeTextEnabled ?? false
        self.highContrastEnabled = user.accessibilitySettings?.highContrastEnabled ?? false
        self.voiceInteractionPreferred = user.accessibilitySettings?.voiceInteractionPreferred ?? false
        self.selectedLanguage = user.preferredLanguage
        
        // Sincronizar el idioma inicial con el traductor
        KaapehTranslator.shared.setLanguage(user.preferredLanguage)
    }
    
    func saveSettings() async {
        // PRIMERO: Aplicar los cambios visualmente de inmediato
        await MainActor.run {
            accessibilityManager.updateSettings(
                largeText: largeTextEnabled,
                highContrast: highContrastEnabled,
                voicePreferred: voiceInteractionPreferred
            )
            
            print("✅ Configuración aplicada visualmente")
            print("   📏 Texto Grande: \(largeTextEnabled ? "ON" : "OFF") - Tamaño: \(accessibilityManager.titleFontSize)pt")
            print("   🎨 Alto Contraste: \(highContrastEnabled ? "ON" : "OFF")")
            print("   🎤 Voz: \(voiceInteractionPreferred ? "ON" : "OFF")")
        }
        
        // SEGUNDO: Guardar en la base de datos
        do {
            try dataService.updateAccessibilityConfig(
                for: user,
                largeText: largeTextEnabled,
                highContrast: highContrastEnabled,
                voicePreferred: voiceInteractionPreferred
            )
            user.preferredLanguage = selectedLanguage
            print("✅ Configuración guardada en base de datos")
        } catch {
            print("❌ Error saving settings: \(error)")
        }
    }
}
