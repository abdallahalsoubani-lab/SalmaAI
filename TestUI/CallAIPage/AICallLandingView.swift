// AICallLandingView.swift
// SalmaAI
//
// Created by Soubani on 01/10/2025.
//

import SwiftUI

struct AICallLandingView: View {
    @StateObject private var vm = RealtimeVoiceViewModel()
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject var coordinator: AppNavigationCoordinator
    
    @State private var isNavigating = false
    @State private var lastNavigationTarget: String? = nil
    
    // Helper function to process navigation
    private func processNavigation(_ pageStr: String) {
        // تنظيف الـ string من أي spaces أو newlines
        let cleanPageStr = pageStr.trimmingCharacters(in: .whitespacesAndNewlines)
        print("📄 Processing navigation: '\(cleanPageStr)' (original: '\(pageStr)')")
        
        // حوّل string لـ NavigationPage enum
        let page: NavigationPage?
        switch cleanPageStr {
        case "transfers":
            page = .transfers
        case "cliq_review":
            // استخدم cliqAmount و cliqPhoneNumber أو cliqAlias من vm إذا كانت متوفرة
            let amount = vm.cliqAmount ?? "5.00"
            let phone = vm.cliqPhoneNumber
            let alias = vm.cliqAlias
            page = .cliqReview(params: CliQReviewParams(amount: amount, phoneNumber: phone, alias: alias))
            print("📊 CliQ params: amount=\(amount), phone=\(phone ?? "nil"), alias=\(alias ?? "nil")")
        case "order", "orderDetails", "cart":
            // ✅ تبسيط: افتح صفحة السلة مباشرة إذا كان في منتجات
            print("✅ Matched cart/order case!")
            print("📊 Current vm.orderItems count: \(vm.orderItems.count)")
            
            // إذا كان orderItems فاضية، لا تفتح صفحة
            if vm.orderItems.isEmpty {
                print("⚠️ orderItems empty - NOT opening cart page")
                page = nil
                return
            }
            
            let items = vm.orderItems
            let total = items.reduce(0.0) { $0 + $1.total }
            page = .orderDetails(params: OrderDetailsParams(
                items: items,
                total: total,
                orderId: vm.orderId,
                orderDate: Date()
            ))
            print("📦 Opening cart page: \(items.count) items, total=\(total)")
        case "add_product":
            // ✅ add_product لا يفتح صفحة - فقط يضيف المنتج للسلة
            // المستخدم يضغط على زر Checkout في productsTable لفتح صفحة السلة
            print("✅ add_product detected - product will be added to cart, but page won't open")
            print("📝 User can press Checkout button to open cart page")
            page = nil // لا تفتح صفحة بعد
            return
        case "language":
            page = .language
        default:
            page = nil
            print("❌ Unknown page: '\(pageStr)'")
        }
        
        if let page = page {
            isNavigating = true
            lastNavigationTarget = pageStr
            
            print("🎯 Navigating to page: \(page)")
            print("👤 Coordinator path before: \(coordinator.path.count) items")
            
            coordinator.navigateTo(page)
            
            print("👤 Coordinator path after: \(coordinator.path.count) items")
            
            // Reset بعد وقت قصير
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                isNavigating = false
                lastNavigationTarget = nil
                print("✅ Navigation reset, ready for next request")
            }
        }
    }
    
    var body: some View {
        ZStack {
            LinearGradient(colors: [Brand.bgTop, Brand.bgBottom],
                           startPoint: .top,
                           endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // العنوان
                Text("🎧 محادثة صوتية مع المساعد")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.top, 16)
                    .padding(.bottom, 20)
                
                // موجات الصوت (في الأعلى)
                VStack(spacing: 6) {
                    WaveBars(values: vm.bands)
                        .frame(height: 120)
                        .padding(.horizontal, 24)
                        .drawingGroup() // تحسين الأداء
                }
                .padding(.bottom, 20)

                if vm.isConnected == false {
                    ProgressView("🔗 جاري الاتصال...")
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .foregroundColor(.white)
                        .padding(.top, 8)
                        .padding(.bottom, 20)
                }

                Spacer()

                // جدول المنتجات المطلوبة (خلفية شفافة ممتدة للأسفل)
                ZStack(alignment: .bottom) {
                    // خلفية شفافة ممتدة
                    VStack(spacing: 0) {
                        productsTable()
                            .padding(.horizontal, 16)
                        
                        Spacer()
                    }
                    
                    // زر Checkout في الأسفل
                    if !vm.orderItems.isEmpty {
                        Button(action: {
                            let items = vm.orderItems
                            let total = items.reduce(0.0) { $0 + $1.total }
                            let orderPage = NavigationPage.orderDetails(params: OrderDetailsParams(
                                items: items,
                                total: total,
                                orderId: vm.orderId,
                                orderDate: Date()
                            ))
                            coordinator.navigateTo(orderPage)
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "cart.fill")
                                    .font(.system(size: 18, weight: .semibold))
                            Text("إتمام الطلب")
                                .font(.system(size: 18, weight: .bold))
                                
                                Spacer()
                                
                                Text("\(formatPrice(vm.orderItems.reduce(0.0) { $0 + $1.total })) دينار")
                                    .font(.system(size: 16, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Brand.bgTop)
                                    .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
                            )
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 30)
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    // Reset navigation state when going back
                    isNavigating = false
                    lastNavigationTarget = nil
                    print("🔙 Back button pressed - reset navigation state")
                    coordinator.navigateBack()
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("رجوع")
                    }
                    .foregroundColor(.white)
                }
            }
        }
        // نستخدم .task لتجنب تكرار الاتصال
        .task {
            if !vm.isConnected {
                await vm.connectToRealtime()
            }
        }
        // فصل/إعادة وصل حسب حالة المشهد
        .onChange(of: scenePhase) { phase in
            if phase == .active, !vm.isConnected {
                Task { await vm.connectToRealtime() }
            }
            if phase == .background {
                vm.disconnect()
            }
        }
        .onDisappear {
            // افحص إذا كانت الصفحة راحت لصفحة ثانية (طول navigation path > 1)
            if coordinator.path.count > 1 {
                print("👋 View disappeared - navigating to another page")
                print("🔌 Disconnecting AI call")
                vm.disconnect()
            } else {
                print("👋 View disappeared - keeping connection alive")
            }
        }
        .onAppear {
            // Reset navigation state when view appears (returning from another page)
            isNavigating = false
            lastNavigationTarget = nil
            print("👀 View appeared - reset navigation state for next request")
            
            // Check for any pending navigation
            if let pendingNav = vm.pendingNavigation {
                print("🔔 Found pending navigation on appear: \(pendingNav)")
                processNavigation(pendingNav)
                vm.pendingNavigation = nil
            }
        }
        .onChange(of: vm.pendingNavigation) { pending in
            if let pageStr = pending {
                print("🔔 Pending navigation detected: \(pageStr)")
                processNavigation(pageStr)
                vm.pendingNavigation = nil
            }
        }
        .onChange(of: vm.navigationTarget) { target in
            print("🔄 onChange triggered - navigationTarget: \(target ?? "nil")")
            print("🔄 isNavigating: \(isNavigating), lastNavigationTarget: \(lastNavigationTarget ?? "nil")")
            print("📊 Current orderItems count: \(vm.orderItems.count)")
            
            // تجنب التنقل المكرر
            if isNavigating {
                print("⏸️ Already navigating, ignoring duplicate request")
                vm.navigationTarget = nil
                return
            }
            
            if let pageStr = target {
                // امسح navigationTarget فوراً
                vm.navigationTarget = nil
                
                // Process navigation مباشرة بدون فحص lastNavigationTarget
                // لأن المستخدم ممكن يطلب نفس الصفحة مرة ثانية عمداً
                processNavigation(pageStr)
            } else {
                print("ℹ️ Target is nil")
            }
        }
        .onChange(of: vm.orderItems) { items in
            print("🛒 orderItems changed in view! Count: \(items.count)")
            if !items.isEmpty {
                print("📦 Current cart contents:")
                for (index, item) in items.enumerated() {
                    print("   [\(index + 1)] \(item.name) - \(item.price) × \(item.quantity) = \(item.total)")
                }
            }
        }
    }
    
    // MARK: - Products Table
    @ViewBuilder
    private func productsTable() -> some View {
        VStack(spacing: 0) {
            // Header للجدول
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "list.bullet.rectangle")
                        .font(.system(size: 18))
                    Text("المنتجات المطلوبة")
                        .font(.system(size: 18, weight: .semibold))
                    if !vm.orderItems.isEmpty {
                        Text("(\(vm.orderItems.count))")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .foregroundColor(.white)
                
                Spacer()
                
                // الإجمالي
                if !vm.orderItems.isEmpty {
                    Text("المجموع: \(formatPrice(vm.orderItems.reduce(0.0) { $0 + $1.total })) دينار")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.white.opacity(0.2))
            )
            
            // جدول المنتجات
            if vm.orderItems.isEmpty {
                // رسالة إذا ما في منتجات
                VStack(spacing: 8) {
                    Image(systemName: "cart.badge.questionmark")
                        .font(.system(size: 32))
                        .foregroundColor(.white.opacity(0.5))
                    Text("لا توجد منتجات بعد")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(vm.orderItems) { item in
                            productTableRow(item: item)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 8)
                }
                .frame(maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
    
    // MARK: - Product Table Row
    @ViewBuilder
    private func productTableRow(item: OrderItem) -> some View {
        HStack(spacing: 12) {
            // صورة المنتج
            if let imageName = item.imageName {
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 55, height: 55)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 55, height: 55)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.white.opacity(0.5))
                    )
            }
            
            // معلومات المنتج
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                HStack(spacing: 4) {
                    Text("\(formatPrice(item.price)) دينار")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text("×")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text("\(item.quantity)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                    
                    Text("=")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text("\(formatPrice(item.total)) دينار")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            
            Spacer()
            
            // أزرار التعديل
            HStack(spacing: 10) {
                // تقليل الكمية أو حذف
                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        if let index = vm.orderItems.firstIndex(where: { $0.id == item.id }) {
                            if item.quantity > 1 {
                                var updatedItems = vm.orderItems
                                let updatedItem = OrderItem(
                                    id: item.id,
                                    name: item.name,
                                    price: item.price,
                                    quantity: item.quantity - 1,
                                    imageName: item.imageName
                                )
                                updatedItems[index] = updatedItem
                                vm.orderItems = updatedItems
                            } else {
                                // حذف المنتج إذا الكمية = 1
                                vm.orderItems.removeAll { $0.id == item.id }
                            }
                        }
                    }
                }) {
                    Image(systemName: item.quantity > 1 ? "minus.circle.fill" : "trash.fill")
                        .font(.system(size: 22))
                        .foregroundColor(item.quantity > 1 ? .white.opacity(0.9) : .red.opacity(0.9))
                }
                
                // زيادة الكمية
                Button(action: {
                    withAnimation(.spring(response: 0.2)) {
                        if let index = vm.orderItems.firstIndex(where: { $0.id == item.id }) {
                            var updatedItems = vm.orderItems
                            let updatedItem = OrderItem(
                                id: item.id,
                                name: item.name,
                                price: item.price,
                                quantity: item.quantity + 1,
                                imageName: item.imageName
                            )
                            updatedItems[index] = updatedItem
                            vm.orderItems = updatedItems
                        }
                    }
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.white.opacity(0.9))
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.white.opacity(0.15))
        )
    }
    
    // MARK: - Helper Functions
    private func formatPrice(_ price: Double) -> String {
        String(format: "%.2f", price)
    }
    
    // MARK: - Sample Order Items (fallback) - DEPRECATED
    // لا نستخدم static data - نستخدم orderItems من vm فقط
    private func getSampleOrderItems() -> [OrderItem] {
        print("⚠️ WARNING: getSampleOrderItems called - this should not happen!")
        print("⚠️ Returning empty array - use vm.orderItems instead")
        return []
    }
}

// MARK: - موجات الصوت
struct WaveBars: View {
    let values: [CGFloat]
    
    var body: some View {
        GeometryReader { geo in
            let count = max(1, values.count)
            let slot = geo.size.width / CGFloat(count)
            let barWidth = max(2.0, slot * 0.55)
            let spacing  = max(2.0, slot - barWidth)
            
            HStack(spacing: spacing) {
                ForEach(values.indices, id: \.self) { i in
                    Capsule()
                        .fill(.white)
                        .frame(width: barWidth,
                               height: max(6, values[i] * geo.size.height))
                        .shadow(color: Brand.accent.opacity(0.6), radius: 4)
                        .animation(.linear(duration: 0.08), value: values[i])
                }
            }
        }
    }
}
