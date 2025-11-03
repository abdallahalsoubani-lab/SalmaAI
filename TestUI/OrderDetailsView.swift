//
//  OrderDetailsView.swift
//  SalmaAI
//
//  Created by Soubani on 10/01/2025.
//

import SwiftUI

// MARK: - Order Details View
struct OrderDetailsView: View {
    @EnvironmentObject var coordinator: AppNavigationCoordinator
    
    // Order data
    let items: [OrderItem]
    let total: Double
    let orderId: String?
    let orderDate: Date?
    
    // MARK: - State
    @State private var showSuccessAnimation: Bool = false
    
    // Date formatter
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ar_JO")
        return formatter
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            // Blue background gradient
            LinearGradient(
                colors: [Brand.bgTop, Brand.bgTop.opacity(0.9)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea(edges: .top)
            .frame(height: 180)
            
            VStack(spacing: 0) {
                header()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Order info card (if orderId exists)
                        if let id = orderId {
                            orderInfoCard(orderId: id)
                        }
                        
                        // Order items list
                        orderItemsCard()
                        
                        // Total card
                        totalCard()
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
                }
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
    }
    
    // MARK: - Header
    @ViewBuilder
    private func header() -> some View {
        VStack(spacing: 16) {
            // Navigation bar
            HStack {
                Button(action: {
                    coordinator.navigateBack()
                }) {
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
                
                Text("تفاصيل الطلب")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
                
                Spacer()
                
                Color.clear.frame(width: 70, height: 1)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .padding(.top, 8)
    }
    
    // MARK: - Order Info Card
    @ViewBuilder
    private func orderInfoCard(orderId: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "doc.text.fill")
                    .font(.title3)
                    .foregroundStyle(.blue)
                
                Text("معلومات الطلب")
                    .font(.headline)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("رقم الطلب:")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(orderId)
                        .font(.subheadline.weight(.semibold))
                        .fontDesign(.monospaced)
                }
                
                if let date = orderDate {
                    HStack {
                        Text("التاريخ والوقت:")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(dateFormatter.string(from: date))
                            .font(.subheadline.weight(.semibold))
                    }
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Order Items Card
    @ViewBuilder
    private func orderItemsCard() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "cart.fill")
                    .font(.title3)
                    .foregroundStyle(.green)
                
                Text("الأصناف")
                    .font(.headline)
                
                Spacer()
            }
            
            Divider()
            
            if items.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "cart.badge.questionmark")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary.opacity(0.5))
                    Text("لا توجد أصناف في الطلب")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                ForEach(items) { item in
                    orderItemRow(item: item)
                    
                    if item.id != items.last?.id {
                        Divider()
                            .padding(.vertical, 4)
                    }
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Order Item Row
    @ViewBuilder
    private func orderItemRow(item: OrderItem) -> some View {
        HStack(alignment: .top, spacing: 12) {
            // Item info
            VStack(alignment: .leading, spacing: 6) {
                Text(item.name)
                    .font(.body.weight(.semibold))
                    .multilineTextAlignment(.leading)
                
                HStack(spacing: 8) {
                    Text("\(formatPrice(item.price)) دينار")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    if item.quantity > 1 {
                        Text("•")
                            .foregroundStyle(.secondary)
                        
                        Text("الكمية: \(item.quantity)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Item total
            Text("\(formatPrice(item.total)) دينار")
                .font(.body.weight(.bold))
                .foregroundStyle(.primary)
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Total Card
    @ViewBuilder
    private func totalCard() -> some View {
        VStack(spacing: 16) {
            HStack {
                Text("المجموع الكلي")
                    .font(.title3.weight(.bold))
                
                Spacer()
                
                Text("\(formatPrice(total)) دينار")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Brand.bgTop)
            }
            
            // Success message (optional)
            if showSuccessAnimation {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("تم تأكيد الطلب بنجاح")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.green)
                }
                .padding(.top, 8)
                .transition(.opacity.combined(with: .scale))
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
    }
    
    // MARK: - Helper Functions
    private func formatPrice(_ price: Double) -> String {
        String(format: "%.2f", price)
    }
}

// MARK: - Preview
#Preview {
    OrderDetailsView(
        items: [
            OrderItem(name: "قهوة تركية", price: 3.50, quantity: 2),
            OrderItem(name: "إسبريسو", price: 4.00, quantity: 1),
            OrderItem(name: "كابتشينو", price: 5.00, quantity: 1)
        ],
        total: 16.00,
        orderId: "ORD-12345",
        orderDate: Date()
    )
    .environmentObject(AppNavigationCoordinator())
}
