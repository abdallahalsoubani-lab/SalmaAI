//
//  Brand.swift
//  SalmaAI
//
//  Created by Soubani on 01/10/2025.
//

import SwiftUI

struct Brand {
    static let accent   = Color(hex6: "#FFD046")
    static let accent2  = Color(hex6: "#F3C22A")
    static let bgTop    = Color(red: 0.04, green: 0.08, blue: 0.14)
    static let bgBottom = Color.black
}

// MARK: - Hex Extension
extension Color {
    init(hex6: String) {
        var hex = hex6.trimmingCharacters(in: .alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let a, r, g, b: UInt64
        switch hex.count {
        case 6: (a,r,g,b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a,r,g,b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:(a,r,g,b) = (255,0,0,0)
        }

        self.init(.sRGB,
                  red: Double(r)/255,
                  green: Double(g)/255,
                  blue: Double(b)/255,
                  opacity: Double(a)/255)
    }
}

extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            self.append(data)
        }
    }
}


//private let elevenAPIKey = "sk_1db9098d0fbac26c1e9b995113e37b1b2ebf4fb2e0222f6a"
//private let elevenVoiceID = "FjJJxwBrv1I5sk34AdgP"
//private let llamaURL = URL(string: "http://34.16.78.158:8000/v1/chat/completions")!
//private let openAIKey = "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"
