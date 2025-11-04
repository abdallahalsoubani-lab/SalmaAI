//
//  TransfersView.swift
//  SwiftuiDemo
//
//  Created by Soubani on 27/10/2025.
//


import SwiftUI

// MARK: - Transfers Hub Screen (Grid) — refined
struct TransfersView: View {
    @EnvironmentObject var coordinator: AppNavigationCoordinator
    
    struct TransferOption: Identifiable {
        let id = UUID()
        let title: String
        let systemImage: String
        let tint: Color
    }

    // خيارات الشبكة
    private let options: [TransferOption] = [
        .init(title: "Between Accounts",   systemImage: "arrow.triangle.2.circlepath", tint: .teal),
        .init(title: "Inside Bank",        systemImage: "diamond",                      tint: .purple),
        .init(title: "Domestic",           systemImage: "building.columns",            tint: .purple.opacity(0.85)),
        .init(title: "International",      systemImage: "globe",                       tint: .pink),
        .init(title: "CliQ",               systemImage: "magnifyingglass.circle",      tint: .indigo),
        .init(title: "Fawri (Blockchain)", systemImage: "square.grid.3x3.fill",        tint: .teal)
    ]

    // أسماء التحويل السريع
    private let quickNames: [String] = ["soubaniiban", "MOATH", "FATINA", "We", "GHAITH", "LAMA"]

    // قياسات عامة
    private let gridSpacing: CGFloat = 12
    private let hPadding: CGFloat = 16

    var body: some View {
        ZStack(alignment: .top) {

            // خلفية الهيدر الزرقاء
            Color.brandBlue
                .ignoresSafeArea(edges: .top)
                .frame(height: 130)

            VStack(spacing: 0) {
                header()

                ScrollView {
                    VStack(spacing: 16) {

                        // GRID: عمودان، المربعات تتكيّف والعرض/الارتفاع متساوي
                        LazyVGrid(
                            columns: [
                                GridItem(.flexible(), spacing: gridSpacing),
                                GridItem(.flexible(), spacing: gridSpacing)
                            ],
                            spacing: gridSpacing
                        ) {
                            ForEach(options) { opt in
                                TransferTile(
                                    title: opt.title,
                                    systemImage: opt.systemImage,
                                    tint: opt.tint
                                )
                            }
                        }
                        .padding(.horizontal, hPadding)
                        .padding(.top, 12)

                        // القسم الرمادي السفلي بالكامل
                        VStack(spacing: 14) {
                            TransferHistoryRow()
                                .padding(.horizontal, hPadding)

                            VStack(alignment: .leading, spacing: 10) {
                                Text("Quick Transfer")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundStyle(.primary)
                                    .padding(.horizontal, hPadding)

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 16) {
                                        ForEach(quickNames, id: \.self) { name in
                                            QuickTransferChip(name: name)
                                        }
                                    }
                                    .padding(.horizontal, hPadding)
                                    .padding(.vertical, 6)
                                }
                            }
                        }
                        .padding(.vertical, 16)
                        .background(Color(UIColor.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .padding(.top, 8)
                    }
                }
                .background(Color(UIColor.systemGray6))
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
    }

    // MARK: - Header
    @ViewBuilder
    private func header() -> some View {
        CustomNavigationBar(title: "الحوالات") {
            coordinator.navigateBack()
        }
    }
}

// MARK: - Components
/// بطاقة مربعة، نص على سطرين، أيقونة صغيرة
struct TransferTile: View {
    let title: String
    let systemImage: String
    let tint: Color

    var body: some View {
        ZStack(alignment: .center) {
            // خلفية البطاقة
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)

            // المحتوى
            HStack(spacing: 10) {
                TileIcon(systemImage: systemImage, tint: tint)

                Text(title)
                    .font(.subheadline.weight(.semibold)) // أصغر من body
                    .lineLimit(2)                          // ✅ يسمح بسطرين
                    .multilineTextAlignment(.leading)
                    .truncationMode(.tail)
                    .foregroundStyle(.primary)

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(12)
        }
        .aspectRatio(1, contentMode: .fit) // ✅ مربّع دائمًا
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

/// أيقونة داخل مربع صغير ملوّن بخلفية شفافة
private struct TileIcon: View {
    let systemImage: String
    let tint: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(tint.opacity(0.12))
                .frame(width: 36, height: 36)              // ✅ أصغر
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .semibold)) // ✅ أصغر
                .foregroundStyle(tint)
        }
    }
}

struct TransferHistoryRow: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.primary)

            Text("Transfer History")
                .font(.callout.weight(.semibold))
                .foregroundStyle(.primary)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)
        )
    }
}

struct QuickTransferChip: View {
    let name: String

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(Color(UIColor.systemBackground))
                    .frame(width: 56, height: 56)
                    .shadow(color: Color.black.opacity(0.06), radius: 5, x: 0, y: 3)
                Image(systemName: "checkmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color(UIColor.systemBlue))
            }
            Text(name)
                .font(.caption)
                .foregroundStyle(.primary)
                .lineLimit(1)
                .frame(width: 74)
        }
    }
}

// MARK: - Theme helpers
extension Color {
    /// درجة قريبة من لقطة الشاشة
    static let brandBlue = Color(red: 0.04, green: 0.29, blue: 0.56)
}

