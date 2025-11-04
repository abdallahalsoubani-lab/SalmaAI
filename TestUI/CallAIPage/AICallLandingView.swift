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
        print("📄 Processing navigation: '\(pageStr)'")
        
        // حوّل string لـ NavigationPage enum
        let page: NavigationPage?
        switch pageStr {
        case "transfers":
            page = .transfers
        case "cliq_review":
            // استخدم cliqAmount و cliqPhoneNumber أو cliqAlias من vm إذا كانت متوفرة
            let amount = vm.cliqAmount ?? "5.00"
            let phone = vm.cliqPhoneNumber
            let alias = vm.cliqAlias
            page = .cliqReview(params: CliQReviewParams(amount: amount, phoneNumber: phone, alias: alias))
            print("📊 CliQ params: amount=\(amount), phone=\(phone ?? "nil"), alias=\(alias ?? "nil")")
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

            VStack(spacing: 16) {
                // العنوان
                Text("🎧 محادثة صوتية مع المساعد")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.top, 16)
                
                // موجات الصوت (تتحرك فقط وقت صوت AI/المستخدم)
                VStack(spacing: 6) {
                    WaveBars(values: vm.bands)
                        .frame(height: 140)
                        .padding(.horizontal, 24)
                        .drawingGroup() // تحسين الأداء
                }

                if vm.isConnected == false {
                    ProgressView("🔗 جاري الاتصال...")
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .foregroundColor(.white)
                        .padding(.top, 8)
                }

                Spacer()

                // أزرار التحكم
                HStack(spacing: 12) {
                    if vm.isConnected {
                        Button(role: .destructive, action: {
                            vm.disconnect()
                        }) {
                            Text("🛑 إنهاء المكالمة")
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(Color.red)
                                .cornerRadius(10)
                        }
                    } else {
                        Button(action: {
                            Task { await vm.connectToRealtime() }
                        }) {
                            Text("🔄 إعادة الاتصال")
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(Color.blue.opacity(0.85))
                                .cornerRadius(10)
                        }
                    }
                }
                .padding(.bottom, 24)
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
