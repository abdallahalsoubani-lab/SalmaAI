//
//  NavigationCoordinator.swift
//  SalmaAI
//
//  Created by Soubani on 27/10/2025.
//

import SwiftUI

// MARK: - Navigation Parameters
struct CliQReviewParams: Hashable {
    let amount: String
    let phoneNumber: String?
    let alias: String?
    
    init(amount: String, phoneNumber: String? = nil, alias: String? = nil) {
        self.amount = amount
        self.phoneNumber = phoneNumber
        self.alias = alias
    }
}

// MARK: - Order Item Model
struct OrderItem: Identifiable, Hashable {
    let id: String
    let name: String
    let price: Double
    let quantity: Int
    
    var total: Double {
        price * Double(quantity)
    }
    
    init(id: String = UUID().uuidString, name: String, price: Double, quantity: Int = 1) {
        self.id = id
        self.name = name
        self.price = price
        self.quantity = quantity
    }
}

// MARK: - Order Details Parameters
struct OrderDetailsParams: Hashable {
    let items: [OrderItem]
    let total: Double
    let orderId: String?
    let orderDate: Date?
    
    init(items: [OrderItem], total: Double? = nil, orderId: String? = nil, orderDate: Date? = nil) {
        self.items = items
        self.total = total ?? items.reduce(0) { $0 + $1.total }
        self.orderId = orderId
        self.orderDate = orderDate ?? Date()
    }
}

// MARK: - Navigation Pages Enum
enum NavigationPage: Hashable {
    case aiCall
    case transfers
    case cliqReview(params: CliQReviewParams)
    case orderDetails(params: OrderDetailsParams)
    case language
}

// MARK: - App Navigation Coordinator
class AppNavigationCoordinator: ObservableObject {
    @Published var path = NavigationPath()
    @Published var navigationCallback: (() -> Void)?
    
    func navigateTo(_ page: NavigationPage) {
        path.append(page)
        print("🚀 Navigating to: \(page)")
        
        // Call callback if exists (for resetting state in parent views)
        if let callback = navigationCallback {
            callback()
            navigationCallback = nil
        }
    }
    
    func navigateBack() {
        if !path.isEmpty {
            path.removeLast()
            print("🔙 Navigated back, remaining path: \(path.count) items")
        }
    }
    
    func navigateToRoot() {
        path.removeLast(path.count)
        print("🏠 Navigated to root")
    }
    
    func setCallback(_ callback: @escaping () -> Void) {
        self.navigationCallback = callback
    }
}

// MARK: - Navigation Coordinator View Modifier
struct NavigationCoordinatorModifier: ViewModifier {
    @EnvironmentObject var coordinator: AppNavigationCoordinator
    
    func body(content: Content) -> some View {
        content
            .navigationDestination(for: NavigationPage.self) { page in
                destinationView(for: page)
            }
    }
    
    @ViewBuilder
    private func destinationView(for page: NavigationPage) -> some View {
        switch page {
        case .aiCall:
            AICallLandingView()
        case .transfers:
            TransfersView()
        case .cliqReview(let params):
            TransferCliqReviewView(
                amount: params.amount,
                phoneNumber: params.phoneNumber,
                alias: params.alias
            )
        case .orderDetails(let params):
            OrderDetailsView(items: params.items, total: params.total, orderId: params.orderId, orderDate: params.orderDate)
        case .language:
            LanguageView()
        }
    }
}

extension View {
    func withNavigationCoordinator() -> some View {
        modifier(NavigationCoordinatorModifier())
    }
}

