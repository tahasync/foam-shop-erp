# Asif Foam Center ERP

A high-performance, enterprise-grade retail inventory and accounting ledger application built with Flutter and Firebase, custom-designed for foam retail business management.

> **Status:** Production Ready  
> **Platform:** Android 5.0+ (API 21)  
> **Architecture:** Flutter + Firebase Firestore + Riverpod State Management  
> **License:** MIT

---

## Architecture

The application implements a **real-time double-entry accounting engine** with automated **Weighted Average Cost (WAC)** asset valuation. Every financial transaction flows through mathematically verified formulas with **costPriceAtSale snapshotting** — COGS is frozen at the time of each sale, preventing historical drift:

| Metric | Formula |
|---|---|
| COGS | `Σ(Items Sold × costPriceAtSale)` with fallback: `currentCostPrice → salePrice × 0.70` |
| Gross Profit | `Revenue − COGS` |
| Net Profit | `Gross Profit − Total Expenses` |
| Cash in Hand | `Opening Capital + Cash Sales + Recoveries − Purchases − Expenses − Supplier Payments` |
| Customer Baqaya | `Σ(Sale Balances) − Σ(Recovery Payments)` floored at `≥ 0` |
| Supplier Payable | `Σ(Purchase Invoices) − Σ(Supplier Payments)` floored at `≥ 0` |
| Inventory Value | `Σ(Current Stock × Cost Price)` with `unitPrice × 0.70` fallback |

All multi-document mutations are wrapped in **atomic Firestore transactions** (`runTransaction`) to guarantee mathematical consistency. Idempotency tokens (`transactionUuid`) prevent duplicate invoice processing across network interruptions.

---

## Features

### Dashboard
- Real-time Revenue, COGS, Gross Profit, Net Profit
- Inventory valuation with cost price fallback estimation
- Cash flow tracking with opening capital
- Non-negative Baqaya and Supplier Payable with floor guards
- Low stock alerts

### Sales
- Cash and credit sales with partial payments
- Line-item discounts, delivery/cutting charges
- Quote-to-sale conversion
- **costPriceAtSale snapshot** — COGS frozen at time of sale
- Automatic stock deduction and COGS calculation
- Negative stock prevention

### Inventory
- Weighted Average Cost (WAC) on every restock
- Buy price (`costPrice`) and sell price (`unitPrice`) tracking
- Zero-value cost protection — fallback to `unitPrice × 0.70` if missing
- Low stock threshold alerts
- Product categorization (Foam, Mattress, Sponge, Pillow, Custom Cut)

### Customer Khata
- Complete ledger with sale and payment history
- Outstanding balance tracking with recovery deduction
- One-tap collect payment with validation
- Dashboard sync via `ref.invalidate(accountingSummaryProvider)`

### Supplier Khata
- Purchase history with balance tracking
- Supplier payment management
- Non-negative payable floor — payments cannot flip balance negative

### Customer Recovery
- Search customers by name
- View outstanding balances with sale and payment history
- Collect payments with form validation
- Atomic Firestore transaction for recovery (`savePaymentTransaction`)
- Recent activity timeline per customer

### Reports & Export
- Daily, Weekly, Monthly, Yearly sales reports with end-of-day boundary filtering
- **CSV export** — saved directly to device **Downloads** folder
- **PDF export** — bank-statement style with summary grid, alternating rows, page numbers
- Date range filtering for custom periods
- Public storage routing — files accessible via device file manager

### Theme
- Full Material 3 light and dark mode
- WCAG-compliant contrast ratios (`--ink: #F5F7F6` in dark mode)
- Category-tinted stat cards (Sales, Purchases, Expenses, Profit, Inventory)
- Persistent theme selection across sessions

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

## Getting Started

### Prerequisites

- Flutter SDK 3.4.0+ ([install guide](https://docs.flutter.dev/get-started/install))
- Android Studio or VS Code with Flutter plugin
- A Firebase project with Firestore, Auth, and Google Sign-In enabled

### Local Setup

```bash
# Clone the repository
git clone https://github.com/mtahanaeem/foam-shop-erp.git
cd foam-shop-erp

# Install dependencies
flutter pub get

# Configure Firebase
# 1. Create a Firebase project at https://console.firebase.google.com
# 2. Enable Firestore Database, Authentication (Google Sign-In)
# 3. Download google-services.json → android/app/
# 4. Download GoogleService-Info.plist → ios/Runner/
# 5. Generate Firebase options:
#    dart run flutterfire configure --project=YOUR_PROJECT_ID

# Run in debug mode
flutter run

# Build release APK
flutter build apk --release
```

### Build Split APK (smaller size)

```bash
flutter build apk --release --split-per-abi
```

Output APKs are in `build/app/outputs/flutter-apk/`:

| APK | Size | Architecture |
|---|---|---|
| `app-arm64-v8a-release.apk` | ~22 MB | Modern phones (2015+) |
| `app-armeabi-v7a-release.apk` | ~20 MB | Older phones |
| `app-x86_64-release.apk` | ~23 MB | Emulators / Chromebooks |

### GitHub Actions CI Setup

The repository includes an automated release workflow (`.github/workflows/release.yml`) that builds and publishes APKs when a version tag is pushed.

To enable CI builds:

1. **Enable GitHub Actions** in your repo settings → Actions → Allow all actions
2. **Add a repository secret** named `GOOGLE_SERVICES_JSON`:
   ```bash
   # Base64 encode your Firebase Android config
   base64 -w 0 android/app/google-services.json | clip
   ```
   Then paste into: repo → Settings → Secrets and variables → Actions → New repository secret

3. **Trigger a build** by pushing a version tag:
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```

The runner will:
- Check out code and install Flutter
- Decode `google-services.json` from the secret
- Build `flutter build apk --release --split-per-abi`
- Attach all 3 split APKs to the GitHub Release

---

## Project Structure

```
lib/
├── main.dart              # App entry point with Firebase init
├── firebase_options.dart  # Auto-generated Firebase config
├── models/                # Data models (Sale, Product, Customer, etc.)
│   ├── sale.dart          # SaleLineItem with costPriceAtSale snapshot
│   ├── product.dart       # Product with costPrice (buy price) + unitPrice (sell price)
│   ├── customer.dart
│   ├── supplier.dart
│   ├── purchase.dart
│   ├── expense.dart
│   ├── payment.dart
│   ├── supplier_payment.dart
│   └── opening_balance.dart
├── services/              # Business logic
│   ├── accounting_service.dart   # Double-entry engine with sanitizeDouble guards
│   ├── firestore_service.dart    # Atomic Firestore transactions
│   ├── auth_service.dart         # Firebase authentication
│   └── export_service.dart       # CSV/PDF export → public Downloads directory
├── providers/             # Riverpod state providers
├── screens/
│   ├── dashboard_screen.dart     # Real-time accounting summary cards
│   ├── sales_entry_screen.dart   # Sale creation with costPriceAtSale
│   ├── inventory_screen.dart     # Product CRUD + restock with WAC
│   ├── customer_khata_screen.dart
│   ├── supplier_khata_screen.dart
│   ├── customer_recovery_screen.dart
│   ├── expense_sheet_screen.dart
│   ├── billing_screen.dart       # PDF receipt generation + printing
│   ├── reports_screen.dart       # Daily/Weekly/Monthly/Yearly reports
│   ├── export_screen.dart        # Export UI with period selector
│   ├── account_settings_screen.dart
│   └── sign_in_screen.dart
├── theme/                # Material 3 theme + AppColors ThemeExtension
└── widgets/
    └── sync_status_indicator.dart
```

---

## Data Integrity

| Protection | Implementation |
|---|---|
| **Atomic transactions** | `runTransaction` for sales, restocks, voids, recoveries |
| **Idempotency** | `transactionUuid` on every sale — duplicate detection before write |
| **COGS snapshotting** | `costPriceAtSale` frozen on `SaleLineItem` at checkout |
| **Cost fallback** | `costPrice → unitPrice × 0.70` when cost is missing (legacy data) |
| **Non-negative baqaya** | `max(0, outstandingSales − recoveries)` floor guard |
| **Non-negative supplier** | `max(0, purchases − payments)` floor guard |
| **Data sanitization** | `sanitizeDouble()` on every numeric field — null/NaN/Infinity → 0 |
| **Stock validation** | `validateSale()` checks stock before any transaction |
| **Negative stock prevention** | Firestore rules enforce `current_stock >= 0` |
| **Dashboard sync** | `ref.invalidate(accountingSummaryProvider)` after every mutation |

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

Project Link: [https://github.com/mtahanaeem/foam-shop-erp](https://github.com/mtahanaeem/foam-shop-erp)
