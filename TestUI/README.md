# TestUI - MVVM Architecture

## Overview
This project has been refactored into a professional MVVM (Model-View-ViewModel) architecture with reusable components and easy API integration.

## Architecture Structure

### 📁 Models
- **HomeModels.swift**: Contains all data models (AccountBalance, BillItem, etc.)
- **UIHelpers.swift**: UI constants and helper structures

### 📁 ViewModels
- **HomePageViewModel.swift**: Main ViewModel handling business logic and state management

### 📁 Views
- **HomePageView.swift**: Main view using MVVM pattern
- **Components/**: Reusable UI components
  - **CommonComponents.swift**: Basic UI components (buttons, cards, etc.)
  - **PromoComponents.swift**: Promo-related components
  - **BalanceComponents.swift**: Balance-related components
  - **BillsComponents.swift**: Bills-related components
  - **SectionComponents.swift**: Section components (Accounts, Cards, Deposits, Loans)
  - **PagerComponents.swift**: Pager-related components

### 📁 Services
- **HomeDataService.swift**: Data service layer with protocol-based architecture
  - **MockHomeDataService**: Static data for development
  - **APIHomeDataService**: Ready for API integration

### 📁 Configuration
- **AppConfiguration.swift**: Centralized configuration for easy switching between mock and API data

## Key Features

### ✅ MVVM Pattern
- Clear separation of concerns
- Testable business logic
- Reactive UI updates

### ✅ Reusable Components
- Modular UI components
- Easy to maintain and extend
- Consistent design system

### ✅ API Integration Ready
- Protocol-based service layer
- Easy switching between mock and API data
- Centralized configuration

### ✅ Professional Structure
- Organized file structure
- Clear naming conventions
- Comprehensive documentation

## How to Switch to API Data

When your backend API is ready, simply change the data source in `AppConfiguration.swift`:

```swift
private static var dataSource: DataSource {
    return .api // Change from .mock to .api
}
```

And update the API base URL:

```swift
private static var apiBaseURL: String {
    return "https://your-actual-api-url.com/v1"
}
```

## Adding New Features

### 1. Add New Data Models
Add your models to `Models/HomeModels.swift` or create new model files.

### 2. Add New API Endpoints
Add endpoints to `Configuration/AppConfiguration.swift`:

```swift
struct APIEndpoints {
    static let newFeature = "/new-feature"
}
```

### 3. Implement API Service
Add methods to `APIHomeDataService`:

```swift
func fetchNewFeature() async throws -> [NewFeatureModel] {
    // Implement API call
}
```

### 4. Update ViewModel
Add methods to `HomePageViewModel`:

```swift
func loadNewFeature() async {
    // Handle loading and error states
}
```

### 5. Create UI Components
Add reusable components to the `Views/Components/` directory.

## Benefits of This Architecture

1. **Maintainability**: Clear separation makes code easy to maintain
2. **Testability**: ViewModels can be easily unit tested
3. **Reusability**: Components can be reused across different views
4. **Scalability**: Easy to add new features and sections
5. **API Ready**: Simple switch from mock to real API data
6. **Professional**: Follows iOS development best practices

## File Organization

```
TestUI/
├── Models/
│   ├── HomeModels.swift
│   └── UIHelpers.swift
├── ViewModels/
│   └── HomePageViewModel.swift
├── Views/
│   ├── HomePageView.swift
│   └── Components/
│       ├── CommonComponents.swift
│       ├── PromoComponents.swift
│       ├── BalanceComponents.swift
│       ├── BillsComponents.swift
│       ├── SectionComponents.swift
│       └── PagerComponents.swift
├── Services/
│   └── HomeDataService.swift
├── Configuration/
│   └── AppConfiguration.swift
└── TestUIApp.swift
```

This architecture ensures your app is ready for production and easy to maintain as it grows.

