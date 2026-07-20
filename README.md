# Asif Foam Center ERP

A high-performance, enterprise-grade retail inventory and accounting ledger application built with Flutter and Firebase, custom-designed for foam retail business management.

> **Status:** Production Ready  
> **Platform:** Android 5.0+ (API 21)  
> **Architecture:** Flutter + Firebase Firestore + Riverpod State Management

---

## Architecture

The application implements a **real-time double-entry accounting engine** with automated **Weighted Average Cost (WAC)** asset valuation. Every financial transaction flows through mathematically verified formulas:

| Metric | Formula |
|---|---|
| COGS | `Σ(Items Sold × Historical WAC Cost Price)` |
| Gross Profit | `Revenue − COGS` |
| Net Profit | `Gross Profit − Total Expenses` |
| Cash in Hand | `Opening Capital + Cash Sales + Recoveries − Purchases − Expenses − Supplier Payments` |
| Customer Baqaya | `Σ(Sale Balances) − Σ(Recovery Payments)` |
| Inventory Value | `Σ(Current Stock × WAC Cost Price)` |

All multi-document mutations are wrapped in **atomic Firestore transactions** (`runTransaction`) to guarantee mathematical consistency. The system includes idempotency tokens to prevent duplicate invoice processing.

---

## Features

### Dashboard
- Real-time Revenue, COGS, Gross Profit, Net Profit
- Inventory valuation at weighted average cost
- Cash flow tracking with opening capital
- Low stock alerts

### Sales
- Cash and credit sales with partial payments
- Line-item discounts, delivery/cutting charges
- Quote-to-sale conversion
- Automatic stock deduction and COGS calculation
- Negative stock prevention

### Inventory
- Weighted Average Cost (WAC) on every restock
- Buy price and sell price tracking
- Low stock threshold alerts
- Product categorization (Foam, Mattress, Sponge, Pillow, Custom Cut)

### Customer Khata
- Complete ledger with sale and payment history
- Outstanding balance tracking
- One-tap collect payment with validation

### Supplier Khata
- Purchase history with balance tracking
- Supplier payment management

### Customer Recovery
- Search customers by name
- View outstanding balances with sale history
- Collect payments with form validation
- Recent activity timeline per customer

### Reports & Export
- Daily, Weekly, Monthly, Yearly sales reports
- **CSV export** (opens in Excel)
- **PDF export** (bank-statement style with summary grid, alternating rows, page numbers)
- Date range filtering for custom periods

### Theme
- Full Material 3 light and dark mode
- WCAG-compliant contrast ratios in both modes
- Category-tinted stat cards (Sales, Purchases, Expenses, Profit, Inventory)
- Persistent theme selection

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter 3.44+ (Dart 3.12+) |
| State Management | Riverpod |
| Backend | Firebase Firestore |
| Authentication | Firebase Auth + Google Sign-In |
| PDF Generation | pdf + printing |
| CSV Export | csv |
| Fonts | Plus Jakarta Sans (headings), Inter (body) |
| CI/CD | GitHub Actions |

---

## Screenshots

| Light Mode | Dark Mode |
|---|---|
| Dashboard with accounting metrics | High-contrast dark theme |
| Customer Khata with balance card | Color-coded transaction history |
| Inventory with stock status | Filter pills and search |

---

## Getting Started

### Prerequisites

- Flutter SDK 3.4.0+ ([install guide](https://docs.flutter.dev/get-started/install))
- Android Studio or VS Code with Flutter plugin
- A Firebase project with Firestore, Auth, and Google Sign-In enabled

### Setup

```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/foam-shop-erp.git
cd foam-shop-erp

# Install dependencies
flutter pub get

# Configure Firebase
# 1. Create a Firebase project at https://console.firebase.google.com
# 2. Enable Firestore, Authentication (Google Sign-In)
# 3. Download google-services.json and place in android/app/
# 4. Download GoogleService-Info.plist and place in ios/Runner/
# 5. Run the Firebase configuration command:
#    flutterfire configure

# Run in debug mode
flutter run

# Build release APK
flutter build apk --release
```

### Build Split APK (smaller size)

```bash
flutter build apk --release --split-per-abi
```

Output APKs will be in `build/app/outputs/flutter-apk/`:
| APK | Size | Architecture |
|---|---|---|
| `app-arm64-v8a-release.apk` | ~22 MB | Modern phones (2015+) |
| `app-armeabi-v7a-release.apk` | ~20 MB | Older phones |
| `app-x86_64-release.apk` | ~23 MB | Emulators / Chromebooks |

---

## Project Structure

```
lib/
├── main.dart              # App entry point with Firebase init
├── firebase_options.dart  # Auto-generated Firebase config
├── models/                # Data models (Sale, Product, Customer, etc.)
├── services/              # Business logic
│   ├── accounting_service.dart   # Double-entry accounting engine
│   ├── firestore_service.dart    # Firestore CRUD with atomic transactions
│   ├── auth_service.dart         # Firebase authentication
│   └── export_service.dart       # CSV and PDF report generation
├── providers/             # Riverpod state providers
├── screens/               # UI screens
│   ├── dashboard_screen.dart
│   ├── sales_entry_screen.dart
│   ├── inventory_screen.dart
│   ├── customer_khata_screen.dart
│   ├── supplier_khata_screen.dart
│   ├── customer_recovery_screen.dart
│   ├── expense_sheet_screen.dart
│   ├── billing_screen.dart
│   ├── reports_screen.dart
│   ├── export_screen.dart
│   ├── account_settings_screen.dart
│   └── sign_in_screen.dart
├── theme/                # Material 3 theme with AppColors extensions
└── widgets/              # Reusable widgets
```

---

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## License

Distributed under the MIT License. See `LICENSE` for more information.

---

## Contact

Project Link: [https://github.com/YOUR_USERNAME/foam-shop-erp](https://github.com/YOUR_USERNAME/foam-shop-erp)
