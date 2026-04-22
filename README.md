# DAISHIN Order System - Flutter Mobile App

A Flutter mobile application for the DAISHIN Order System, supporting multi-language product browsing, cart and checkout flow, and manual payment methods including bank transfer with receipt upload.

## 📱 Features

- **Multi-Language Support**: English, Khmer, Japanese, Chinese
- **Authentication**: Login, Register, Forgot Password
- **Product Catalog**: Browse products by category, view details
- **Shopping Cart**: Add/remove items, update quantities
- **Multiple Payment Methods**:
  - Cash on Delivery (COD)
  - Bank Transfer (with QR code and receipt upload)
  - Invoice / Pay Later (for business customers)
- **Order Management**: Track order status and history
- **User Profile**: Manage profile, addresses, and settings
- **Theme Support**: Light and dark mode

## 🛠 Tech Stack

- **Flutter**: Cross-platform UI framework
- **Dart**: Programming language
- **Provider**: State management
- **GoRouter**: Declarative routing
- **Dio**: HTTP client for API communication
- **Flutter Secure Storage**: Secure local data storage
- **Connectivity Plus**: Network status monitoring

## 📁 Project Structure

```
📁 daishin_order_app/
├── 📁 android/              # Android-specific code
├── 📁 ios/                  # iOS-specific code
├── 📁 lib/                  # Main Flutter application code
│   ├── 📁 core/             # Core utilities and constants
│   │   ├── 📁 constants/    # App constants, API endpoints, themes
│   │   ├── 📁 routes/       # App routing configuration
│   │   └── 📁 theme/        # App theme definitions
│   ├── 📁 data/             # Data layer
│   │   ├── 📁 models/       # Data models
│   │   ├── 📁 dtos/         # Data transfer objects
│   │   └── 📁 repositories/ # Repository pattern
│   │       ├── 📁 abstract/      # Repository interfaces
│   │       └── 📁 implementations/ # Repository implementations
│   ├── 📁 presentation/     # Presentation layer
│   │   ├── 📁 providers/    # State management providers
│   │   ├── 📁 screens/      # UI screens
│   │   └── 📁 widgets/      # Reusable UI components
│   ├── 📁 utils/            # Helper utilities
│   └── 📄 main.dart         # Application entry point
├── 📁 assets/               # Static assets
│   ├── 📁 images/           # Images and logos
│   ├── 📁 icons/            # Custom icons
│   └── 📁 translations/     # Language JSON files
├── 📄 pubspec.yaml          # Flutter dependencies
├── 📄 .env.example          # Environment variables template
└── 📄 README.md             # This file
```

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (>=3.2.0)
- Dart SDK
- Android Studio / Xcode (for mobile development)

### Installation

1. Clone the repository
2. Navigate to the project directory:

   ```bash
   cd daishin_order_app
   ```

3. Copy the environment file:

   ```bash
   cp .env.example .env
   ```

4. Update the `.env` file with your API configuration

5. Install dependencies:

   ```bash
   flutter pub get
   ```

6. Run the app:
   ```bash
   flutter run
   ```

## 🔧 Configuration

Update the `.env` file with your backend API URL:

```
API_BASE_URL=https://api.daishintc.com
API_TIMEOUT=30000
APP_NAME=DAISHIN Order System
```

## 📱 Key Navigation Paths

- `/login` - Authentication screen
- `/home` - Main dashboard
- `/products` - Product listings
- `/products/:id` - Product details
- `/cart` - Shopping cart
- `/checkout` - Checkout flow
- `/orders` - Order history
- `/profile` - User profile

## 🌐 Multi-Language Support

The app supports 4 languages:

- English (en)
- Khmer (km)
- Japanese (ja)
- Chinese (zh)

Translation files are located in `assets/translations/`

## 💳 Payment Flow

### Bank Transfer

1. User selects Bank Transfer payment method
2. App displays bank details and QR code
3. User completes payment in their banking app
4. User uploads payment receipt
5. Admin verifies receipt manually
6. Order status updated to PAID

## 🏗 Development Status

This is the initial project structure with placeholder screens. Each screen needs to be implemented with:

- UI components
- Business logic
- API integration
- State management

## 📝 Next Steps

1. Implement authentication screens with form validation
2. Create product catalog with API integration
3. Build shopping cart functionality
4. Implement checkout and payment flows
5. Add order tracking features
6. Complete profile and settings screens
7. Implement state management with Provider
8. Add comprehensive error handling
9. Write unit and widget tests
10. Optimize performance and UX

## 📄 License

Copyright © 2026 DAISHIN Trading Co., Ltd.
