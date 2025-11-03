//
//  HomePageView.swift
//  MobileBankingJKB
//
//  Created by Alaa Mohammed on 30/07/2025.
//

import SwiftUI

struct HomePageView: View {
  @StateObject private var coordinator = AppNavigationCoordinator()

  var body: some View {
    NavigationStack(path: $coordinator.path) {
      ZStack {
        // خلفية سوداء
        Color.black.ignoresSafeArea()

        // المحتوى في منتصف الشاشة
        VStack(spacing: 16) {
          Image("bank_logo")
            .resizable()
            .scaledToFit()
            .frame(width: 300, height: 300) // الحجم المطلوب
            .accessibilityLabel("AI Bank Logo")

          Text("AI Bank")
            .font(.system(size: 28, weight: .semibold))
            .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .padding()

        // زر AI العائم (قابل للسحب + يحفظ موقعه)
        FloatingDraggableButton {
          // Navigate to AI call view
          coordinator.navigateTo(.aiCall)
        }
        .padding(.bottom, 24)   // ملاحظة: الـ FloatingDraggableButton يستخدم position خاصته
        .padding(.trailing, 16) // padding هنا تجميلي، بس التحكم الفعلي بالموقع من داخل الكومبوننت
      }
      .withNavigationCoordinator()
    }
    .environmentObject(coordinator)
  }
}

// MARK: - Floating Draggable Button
struct FloatingDraggableButton: View {
  let action: () -> Void

  // تخزين موقع الزر (يحفظ آخر مكان)
  @State private var positionX: Double = UserDefaults.standard.double(forKey: "floatingButtonPositionX")
  @State private var positionY: Double = UserDefaults.standard.double(forKey: "floatingButtonPositionY")

  // حالات السحب
  @State private var dragOffset: CGSize = .zero
  @State private var isDragging: Bool = false

  private func initializePosition() {
    // ضبط موقع ابتدائي (أسفل يمين الشاشة)
    if positionX == 0 {
      positionX = UIScreen.main.bounds.width - 80
      UserDefaults.standard.set(positionX, forKey: "floatingButtonPositionX")
    }
    if positionY == 0 {
      positionY = UIScreen.main.bounds.height - 180
      UserDefaults.standard.set(positionY, forKey: "floatingButtonPositionY")
    }
  }

  private func savePosition() {
    UserDefaults.standard.set(positionX, forKey: "floatingButtonPositionX")
    UserDefaults.standard.set(positionY, forKey: "floatingButtonPositionY")
  }

  var body: some View {
    Button(action: action) {
      Image("bank_logo") // غيّرها لشعارك إن لزم
        .resizable()
        .scaledToFit()
        .frame(width: 65, height: 65)
        .background(
          Circle()
            .fill(
              LinearGradient(
                colors: [Color(hex: "#FDCB4A"), Color(hex: "#1E4B74")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
              )
            )
        )
        .overlay(
          Circle()
            .stroke(Color(hex: "#FDCB4A"), lineWidth: 3)
        )
        .shadow(color: Color.black.opacity(0.3),
                radius: isDragging ? 8 : 4,
                x: 0, y: isDragging ? 4 : 2)
        .scaleEffect(isDragging ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isDragging)
        .contentShape(Circle())
    }
    .position(x: positionX + dragOffset.width, y: positionY + dragOffset.height)
    .highPriorityGesture(
      DragGesture()
        .onChanged { value in
          isDragging = true
          dragOffset = value.translation
        }
        .onEnded { value in
          isDragging = false

          let finalX = positionX + value.translation.width
          let finalY = positionY + value.translation.height

          let screenBounds = UIScreen.main.bounds
          let safeAreaInsets = UIApplication.shared.windows.first?.safeAreaInsets ?? .zero

          // حدود آمنة
          let minX: CGFloat = 28 + safeAreaInsets.left
          let maxX: CGFloat = screenBounds.width - 28 - safeAreaInsets.right
          let minY: CGFloat = 100 + safeAreaInsets.top
          let maxY: CGFloat = screenBounds.height - 100 - safeAreaInsets.bottom

          let snappedX = max(minX, min(maxX, finalX))
          let snappedY = max(minY, min(maxY, finalY))

          positionX = snappedX
          positionY = snappedY
          savePosition()
          dragOffset = .zero
        }
    )
    .onAppear {
      initializePosition()

      let screenBounds = UIScreen.main.bounds
      let safeAreaInsets = UIApplication.shared.windows.first?.safeAreaInsets ?? .zero

      let minX: CGFloat = 28 + safeAreaInsets.left
      let maxX: CGFloat = screenBounds.width - 28 - safeAreaInsets.right
      let minY: CGFloat = 100 + safeAreaInsets.top
      let maxY: CGFloat = screenBounds.height - 100 - safeAreaInsets.bottom

      positionX = max(minX, min(maxX, positionX))
      positionY = max(minY, min(maxY, positionY))
      savePosition()
    }
  }
}

// MARK: - Color Hex Extension
public extension Color {
  init(hex: String) {
    let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
    var int = UInt64()
    Scanner(string: hex).scanHexInt64(&int)
    let a, r, g, b: UInt64
    switch hex.count {
    case 6: (a, r, g, b) = (255, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
    case 8: (a, r, g, b) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
    default: (a, r, g, b) = (255, 0, 0, 0)
    }
    self.init(.sRGB,
              red: Double(r) / 255,
              green: Double(g) / 255,
              blue: Double(b) / 255,
              opacity: Double(a) / 255)
  }
}
