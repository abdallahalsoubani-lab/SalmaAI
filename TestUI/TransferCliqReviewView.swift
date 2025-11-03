//
//  TransferCliqReviewView.swift
//  SwiftuiDemo
//
//  Created by Soubani on 01/11/2025.
//

import SwiftUI

// MARK: - CliQ Review Screen
struct TransferCliqReviewView: View {
    @EnvironmentObject var coordinator: AppNavigationCoordinator
    
    // البيانات المرسلة من الـ AI
    var amount: String?
    var phoneNumber: String?
    var alias: String?
    
    // MARK: - State
    @State private var confirmedAmount: String = "5.000"
    @State private var fromAccountName: String = "أستاذ غيث محمد"
    @State private var fromAccountMasked: String = "1234-5678-9012-3456"
    @State private var beneficiaryAlias: String = "00962787075008"
    @State private var beneficiaryPhone: String? = nil
    @State private var showFeesInfo: Bool = false
    @State private var isEditingAmount: Bool = false
    @State private var isEditingPhone: Bool = false
    @State private var tempAmount: String = ""
    @State private var tempPhone: String = ""

    
    var body: some View {
        ZStack(alignment: .top) {
            // Blue background gradient
            LinearGradient(
                colors: [.brandBlue, .brandBlue.opacity(0.9)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea(edges: .top)
            .frame(height: 180)
            
            VStack(spacing: 0) {
                header()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Main amount card - big and prominent
                        mainAmountCard()
                        
                        // Details cards - side by side
                        HStack(spacing: 12) {
                            fromAccountCard()
                            toBeneficiaryCard()
                        }
                        
                        Spacer(minLength: 120)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
                }
                
                confirmBar()
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
        .sheet(isPresented: $showFeesInfo) {
            VStack(spacing: 16) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.secondary.opacity(0.3))
                    .frame(width: 40, height: 6)
                    .padding(.top, 8)
                Text("رسوم التحويل")
                    .font(.headline)
                Text("قد تُطبّق رسوم بسيطة حسب نوع التحويل والبنك المستفيد. ستظهر الرسوم النهائية قبل الإرسال.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                Button("تم") { showFeesInfo = false }
                    .buttonStyle(.borderedProminent)
                    .padding(.bottom, 24)
            }
            .presentationDetents([.height(260)])
        }
        .onAppear {
            loadData()
        }
    }

    // MARK: - Header
    @ViewBuilder
    private func header() -> some View {
        VStack(spacing: 16) {
            // Navigation bar - inline (without gradient since background has it)
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
                
                Text("مراجعة وتحويل")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
                
                Spacer()
                
                Color.clear.frame(width: 70, height: 1)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            
            // Step bar (1 of 4)
            HStack {
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.3))
                        .frame(height: 8)
                    
                    GeometryReader { geo in
                        Capsule()
                            .fill(Color.white)
                            .frame(width: geo.size.width * 0.25, height: 8)
                    }
                }
                .frame(height: 8)
                
                Spacer()
                
                Text("الخطوة 1 من 4")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white.opacity(0.8))
            }
            .padding(.horizontal, 20)
        }
        .padding(.top, 8)
    }

    // MARK: - Main Amount Card
    @ViewBuilder
    private func mainAmountCard() -> some View {
        VStack(spacing: 20) {
            // Amount display
            HStack {
                VStack(spacing: 8) {
                    Text("المبلغ")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                    
                    if isEditingAmount {
                        TextField("المبلغ", text: $tempAmount)
                            .font(.system(size: 52, weight: .bold, design: .rounded))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.center)
                    } else {
                        Text("\(confirmedAmount) JOD")
                            .font(.system(size: 52, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                    }
                }
                .frame(maxWidth: .infinity)
                
                Button(action: {
                    if isEditingAmount {
                        confirmedAmount = tempAmount
                    } else {
                        tempAmount = confirmedAmount
                    }
                    isEditingAmount.toggle()
                }) {
                    Image(systemName: isEditingAmount ? "checkmark" : "pencil")
                        .font(.title3)
                        .foregroundStyle(.blue)
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(Color.blue.opacity(0.1)))
                }
            }
            
            Divider()
                .padding(.horizontal, 20)
            
            // Beneficiary (Alias or Phone)
            HStack {
                VStack(spacing: 8) {
                    Text(beneficiaryPhone != nil ? "رقم المستفيد" : "الاسم المستعار")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                    
                    if isEditingPhone {
                        TextField(beneficiaryPhone != nil ? "الرقم" : "الاسم", text: $tempPhone)
                            .font(.system(size: 20, weight: .semibold, design: .default))
                            .multilineTextAlignment(.center)
                    } else {
                        Text(beneficiaryAlias)
                            .font(.system(size: 20, weight: .semibold, design: beneficiaryPhone != nil ? .monospaced : .default))
                            .foregroundStyle(.blue)
                    }
                }
                .frame(maxWidth: .infinity)
                
                Button(action: {
                    if isEditingPhone {
                        if !tempPhone.isEmpty {
                            if beneficiaryPhone != nil {
                                beneficiaryAlias = formatPhoneNumber(tempPhone)
                            } else {
                                beneficiaryAlias = tempPhone
                            }
                        }
                    } else {
                        if beneficiaryPhone != nil {
                            tempPhone = beneficiaryAlias.replacingOccurrences(of: "00962", with: "0")
                        } else {
                            tempPhone = beneficiaryAlias
                        }
                    }
                    isEditingPhone.toggle()
                }) {
                    Image(systemName: isEditingPhone ? "checkmark" : "pencil")
                        .font(.title3)
                        .foregroundStyle(.blue)
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(Color.blue.opacity(0.1)))
                }
            }
            
            // Fees info button
            Button(action: { showFeesInfo = true }) {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle.fill")
                    Text("Transfer Fees")
                        .font(.footnote.weight(.medium))
                }
                .foregroundStyle(.blue)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule().fill(Color.blue.opacity(0.1))
                )
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        )
    }
    
    // MARK: - From Account Card
    @ViewBuilder
    private func fromAccountCard() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "creditcard.fill")
                    .font(.title2)
                    .foregroundStyle(.green)
                Spacer()
            }
            
            Text("من حساب")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(fromAccountName)
                    .font(.body.weight(.semibold))
                Text(fromAccountMasked)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - To Beneficiary Card
    @ViewBuilder
    private func toBeneficiaryCard() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: beneficiaryPhone != nil ? "phone.fill" : "at.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.blue)
                Spacer()
            }
            
            Text("إلى المستفيد")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
            
            Text(beneficiaryAlias)
                .font(.body.weight(.semibold))
                .lineLimit(2)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }

    // MARK: - Bottom Bar
    @ViewBuilder
    private func confirmBar() -> some View {
        VStack(spacing: 0) {
            Divider()
            HStack {
                Button(action: {
                    // TODO: Send transfer
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: "lock.fill")
                            .foregroundStyle(.black.opacity(0.7))
                        Text("Confirm And Transfer")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.yellow)
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 12)
            .background(.ultraThinMaterial)
        }
        .ignoresSafeArea(edges: .bottom)
    }
    
    private func loadData() {
        // تعبئة البيانات من parameters أو defaults
        if let aiAmount = amount {
            confirmedAmount = aiAmount
        }
        
        // Check if alias or phone
        if let aiAlias = alias {
            beneficiaryAlias = aiAlias
            beneficiaryPhone = nil
        } else if let aiPhone = phoneNumber {
            beneficiaryAlias = formatPhoneNumber(aiPhone)
            beneficiaryPhone = aiPhone
        }
    }
    
    private func formatPhoneNumber(_ phone: String) -> String {
        // إذا الرقم فيه 00962 أو 962، استخدمه مباشرة
        if phone.hasPrefix("00962") || phone.hasPrefix("962") || phone.hasPrefix("+962") {
            return phone
        }
        
        // إذا الرقم أردني (يبدأ بـ 07)، أزل الصفر الأول وأضف 00962
        if phone.hasPrefix("0") && phone.count == 10 {
            let withoutZero = String(phone.dropFirst()) // أزل أول رقم (0)
            return "00962\(withoutZero)"
        }
        
        // إذا الرقم بدون الصفر الأول (يبدأ بأرقام من 7)، أضف 00962
        if phone.count == 9 && phone.first?.isNumber == true {
            return "00962\(phone)"
        }
        
        // في الحالات الأخرى، استخدم الرقم كما هو
        return phone
    }
}

// MARK: - Preview
#Preview {
    // Preview with phone number
    TransferCliqReviewView(amount: "5.00", phoneNumber: "0787075008")
        .environmentObject(AppNavigationCoordinator())
}

#Preview("With Alias") {
    // Preview with alias
    TransferCliqReviewView(amount: "10.00", alias: "soubani")
        .environmentObject(AppNavigationCoordinator())
}
