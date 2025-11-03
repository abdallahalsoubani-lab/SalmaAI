//
//  LanguageView.swift
//  SwiftuiDemo
//
//  Created by Soubani on 01/11/2025.
//

import SwiftUI

struct LanguageView: View {
    @EnvironmentObject var coordinator: AppNavigationCoordinator
    @State private var selectedLanguage: LanguageOption = .arabic
    @Environment(\.layoutDirection) var layoutDirection
    @AppStorage("selectedLanguage") private var storedLanguage = "ar"
    
    enum LanguageOption: String, CaseIterable {
        case arabic = "ar"
        case english = "en"
        
        var displayName: (primary: String, secondary: String) {
            switch self {
            case .arabic:
                return ("العربية", "Arabic")
            case .english:
                return ("English", "الإنجليزية")
            }
        }
        
        var flag: String {
            switch self {
            case .arabic:
                return "🇸🇦" // Saudi Arabia flag
            case .english:
                return "🇺🇸" // US flag
            }
        }
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            // Background
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header with back button
                HStack {
                    Button(action: {
                        coordinator.navigateBack()
                    }) {
                        Text("< Back")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.blue)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Title section
                        VStack(spacing: 8) {
                            Text("اللغة")
                                .font(.system(size: 34, weight: .bold))
                            Text("Language")
                                .font(.system(size: 34, weight: .bold))
                            Text("LANGUAGE")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 40)
                        
                        // Language selection card
                        languageSelectionCard()
                            .padding(.horizontal, 20)
                        
                        // Info text
                        Text("يتغير اتجاه التطبيق ونصوصه فورًا بدون إعادة تشغيل.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                            .padding(.top, 20)
                    }
                    .padding(.vertical, 40)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
    }
    
    @ViewBuilder
    private func languageSelectionCard() -> some View {
        VStack(spacing: 0) {
            ForEach([LanguageOption.arabic, LanguageOption.english], id: \.self) { option in
                LanguageOptionRow(
                    option: option,
                    isSelected: selectedLanguage == option
                ) {
                    selectedLanguage = option
                    storedLanguage = option.rawValue
                    
                    // Trigger layout direction change
                    if option == .arabic {
                        // Force RTL
                    } else {
                        // Force LTR
                    }
                }
                
                if option != LanguageOption.allCases.last {
                    Divider()
                        .padding(.leading, 70)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
        )
    }
}

struct LanguageOptionRow: View {
    let option: LanguageView.LanguageOption
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Radio button
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 12, height: 12)
                    }
                }
                
                // Language text
                VStack(alignment: .leading, spacing: 4) {
                    Text(option.displayName.primary)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.primary)
                    Text(option.displayName.secondary)
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Flag
                Text(option.flag)
                    .font(.system(size: 32))
            }
            .padding(20)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    LanguageView()
        .environmentObject(AppNavigationCoordinator())
}
