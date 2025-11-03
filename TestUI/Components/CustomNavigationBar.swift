//
//  CustomNavigationBar.swift
//  TestUI
//
//  Created by AI Assistant
//

import SwiftUI

struct CustomNavigationBar: View {
    let title: String
    let onBack: () -> Void
    
    var body: some View {
        HStack {
            // Back button with modern design
            Button(action: onBack) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                    
                    Text("رجوع")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.white.opacity(0.2))
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                )
            }
            
            Spacer()
            
            // Title with modern styling
            Text(title)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)
            
            Spacer()
            
            // Balance the layout
            Color.clear.frame(width: 70, height: 1)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            LinearGradient(
                colors: [.brandBlue, .brandBlue.opacity(0.9)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

#Preview {
    VStack {
        CustomNavigationBar(title: "الحوالات") {
            print("Back tapped")
        }
        Spacer()
    }
    .background(Color.gray.opacity(0.1))
}

