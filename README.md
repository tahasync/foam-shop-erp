<div align="center">

# 🏪 Foam Shop ERP

**Enterprise-Grade Retail Inventory & Accounting System**

[![Flutter](https://img.shields.io/badge/Flutter-3.44+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.12-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Firestore-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com)
[![Riverpod](https://img.shields.io/badge/State-Riverpod-4DB33D?logo=flutter&logoColor=white)](https://riverpod.dev)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)
[![Android](https://img.shields.io/badge/Platform-Android%205.0+-3DDC84?logo=android&logoColor=white)](https://developer.android.com)

</div>

---

## 📋 Overview

Foam Shop ERP is a **production-ready mobile retail management system** built for foam and mattress businesses. It features a **real-time double-entry accounting engine** with **Weighted Average Cost (WAC)** valuation, automated **COGS snapshotting**, and **atomic Firestore transactions** — all wrapped in a polished Material 3 UI with full dark mode support.

| Module | Scope | Integration |
|:------:|:-----|:-----------:|
| **📊 Dashboard** | Live Revenue, COGS, Profit, Cash, Inventory Value | Riverpod + AccountingService |
| **🛒 Sales** | Cash/credit, discounts, quotes, stock deduction | Atomic Firestore transactions |
| **📦 Inventory** | WAC restock, buy/sell price, low stock alerts | Weighted average cost engine |
| **👤 Customer Khata** | Ledger, baqaya, recovery, payment history | Real-time streams |
| **🏭 Supplier Khata** | Purchases, payments, payable tracking | Real-time streams |
| **📈 Reports** | Daily/Weekly/Monthly/Yearly + CSV/PDF export | ExportService |

---

## ✨ Features

- **🔢 Double-Entry Accounting** — Revenue, COGS, Gross Profit, Net Profit with `costPriceAtSale` snapshotting
- **⚖️ Weighted Average Cost (WAC)** — Auto-calculated on every restock, zero-value fallback protection
- **📸 COGS Snapshotting** — `costPriceAtSale` frozen at checkout — historical reports never drift
- **🧮 Non-Negative Ledgers** — Baqaya and Supplier Payable floored at `≥ 0` with `sanitizeDouble()` guards
- **🔐 Atomic Transactions** — Every sale, restock, void, and recovery wrapped in `runTransaction`
- **🆔 Idempotency** — `transactionUuid` prevents duplicate invoice processing
- **📱 Public Downloads Export** — CSV/PDF saved directly to device Downloads folder
- **🌙 Material 3 Dark Mode** — WCAG-compliant contrast, persistent theme selection
- **🤖 CI/CD** — Auto-build APK on every push via GitHub Actions

---

## 🗂️ Project Structure

```
foam-shop-erp/
├── lib/
│   ├── main.dart                          # App entry + Firebase init
│   ├── firebase_options.dart              # Firebase config (auto-generated)
│   ├── models/                            # Data models
│   │   ├── sale.dart                      # SaleLineItem with costPriceAtSale
│   │   ├── product.dart                   # costPrice + unitPrice + WAC
│   │   ├── customer.dart
│   │   ├── supplier.dart
│   │   ├── purchase.dart
│   │   ├── expense.dart
│   │   ├── payment.dart
│   │   ├── supplier_payment.dart
│   │   └── opening_balance.dart
│   ├── services/                          # Business logic
│   │   ├── accounting_service.dart        # Double-entry engine + sanitizeDouble
│   │   ├── firestore_service.dart         # Atomic CRUD with runTransaction
│   │   ├── auth_service.dart              # Firebase Auth
│   │   └── export_service.dart            # CSV/PDF → public Downloads
│   ├── providers/                         # Riverpod state providers
│   ├── screens/
│   │   ├── dashboard_screen.dart          # Live accounting summary cards
│   │   ├── sales_entry_screen.dart        # Sale form with costPriceAtSale
│   │   ├── inventory_screen.dart          # Product CRUD + WAC restock
│   │   ├── customer_khata_screen.dart
│   │   ├── supplier_khata_screen.dart
│   │   ├── customer_recovery_screen.dart
│   │   ├── expense_sheet_screen.dart
│   │   ├── billing_screen.dart            # PDF receipt + printing
│   │   ├── reports_screen.dart            # Period filter reports
│   │   ├── export_screen.dart             # Export UI with date range
│   │   ├── account_settings_screen.dart
│   │   └── sign_in_screen.dart
│   ├── theme/                             # Material 3 + AppColors extension
│   └── widgets/
│       └── sync_status_indicator.dart
├── .github/workflows/
│   ├── build.yml                          # Auto-build on push to main
│   └── release.yml                        # Tag-triggered GitHub Release
├── android/                               # Android native shell
├── ios/                                   # iOS native shell
├── firestore.rules                        # Security rules (anti-negative stock)
├── pubspec.yaml
└── README.md
```

---

## 🚀 Getting Started

### Prerequisites

| Requirement | Version | Download |
|:------------|:-------:|:---------|
| Flutter SDK | 3.4.0+ | [docs.flutter.dev](https://docs.flutter.dev/get-started/install) |
| Dart | 3.12+ | Bundled with Flutter |
| Firebase Project | — | [console.firebase.google.com](https://console.firebase.google.com) |
| Android Studio | 2024+ | [developer.android.com](https://developer.android.com/studio) |

### 1. Clone

```bash
git clone https://github.com/mtahanaeem/foam-shop-erp.git
cd foam-shop-erp
```

### 2. Firebase Setup

| Step | Action |
|:----:|:-------|
| 1 | Create project at [Firebase Console](https://console.firebase.google.com) |
| 2 | Enable **Firestore Database** + **Authentication** (Google Sign-In) |
| 3 | Download `google-services.json` → `android/app/` |
| 4 | Download `GoogleService-Info.plist` → `ios/Runner/` |
| 5 | Run `dart run flutterfire configure --project=YOUR_PROJECT_ID` |

### 3. Install & Run

```bash
# Install dependencies
flutter pub get

# Run in debug mode
flutter run

# Build release APK
flutter build apk --release

# Build split APK (smaller size)
flutter build apk --release --split-per-abi
```

### Output APKs

| APK | Size | Architecture |
|:----|:----:|:-------------|
| `app-arm64-v8a-release.apk` | ~22 MB | Modern phones (2015+) |
| `app-armeabi-v7a-release.apk` | ~20 MB | Older phones |
| `app-x86_64-release.apk` | ~23 MB | Emulators / Chromebooks |

---

## 🤖 CI/CD

Two automated workflows — zero manual builds needed:

| Workflow | Trigger | Output |
|:---------|:-------:|:-------|
| `build.yml` | Every push to `main` | APK artifacts in Actions tab |
| `release.yml` | Push tag `v*` | GitHub Release with APK downloads |

### Setup (one time)

```bash
# Base64 your Firebase config
base64 -w 0 android/app/google-services.json | clip

# Add as repo secret named: GOOGLE_SERVICES_JSON
```

### Daily Workflow

```bash
git add .
git commit -m "your changes"
git push origin main
```

Wait ~3 minutes, then go to **Actions** tab → latest run → **Artifacts** → download APK.

### Release Workflow

```bash
git tag v1.1.0
git push origin v1.1.0
```

Creates a GitHub Release page with all 3 split APKs attached.

---

## 🧠 How It Works

```
Sale Created → costPriceAtSale Snapshot → Stock Deducted (Atomic)
                    ↓
         AccountingService.compute()
                    ↓
     Revenue ↑ | COGS ← costPriceAtSale | costPrice | salePrice×0.70
     ─────────────────────────────────────────────────────────────────
     Gross Profit = Revenue − COGS
     Net Profit   = Gross Profit − Expenses
     Cash in Hand = Capital + CashSales + Recoveries − Purchases − Expenses − SupplierPmts
     Baqaya       = max(0, ΣSale.Balance − ΣRecoveryPayments)
```

| Step | Component | What It Does |
|:----:|:----------|:-------------|
| 1 | **Sales Entry** | User enters items, quantities, prices, discounts. `costPriceAtSale` frozen per line item |
| 2 | **Validation** | `AccountingService.validateSale()` checks stock, amounts, empty items |
| 3 | **Atomic Transaction** | `FirestoreService.saveSaleTransaction()` writes sale + deducts stock in one `runTransaction` |
| 4 | **COGS Calculation** | `qtyOrArea × costPriceAtSale` — falls back to `costPrice` → `salePrice × 0.70` |
| 5 | **Dashboard Recompute** | `ref.invalidate(accountingSummaryProvider)` triggers live UI update |
| 6 | **Export** | CSV/PDF generated with same accounting formulas → saved to public Downloads |

---

## 🛠️ Tech Stack

| Layer | Technology |
|:------|:-----------|
| **Framework** | Flutter 3.44+ / Dart 3.12+ |
| **State Management** | Riverpod |
| **Backend** | Firebase Firestore |
| **Authentication** | Firebase Auth + Google Sign-In |
| **PDF Generation** | `pdf` + `printing` |
| **CSV Export** | `csv` |
| **Typography** | Plus Jakarta Sans (headings), Inter (body) |
| **CI/CD** | GitHub Actions |

---

## 📈 Key Takeaways

1. **🔐 Atomic transactions prevent ledger drift** — Wrapping sale + stock deduction in a single `runTransaction` eliminates partial-write bugs that plague accounting apps.

2. **📸 COGS snapshotting is essential** — Without `costPriceAtSale`, recalculating historical reports uses today's cost prices, producing inaccurate margins. Freezing cost at sale time guarantees historical accuracy.

3. **🛡️ Non-negative guards prevent impossible states** — Customer baqaya can't go below zero. Supplier payable can't go below zero. These floor guards catch data entry errors immediately.

4. **🧮 70% fallback saves legacy data** — Products created before the `costPrice` field existed default to `unitPrice × 0.70` instead of Rs 0, keeping historical COGS meaningful.

5. **⚡ Real-time dashboard sync** — `ref.invalidate(accountingSummaryProvider)` after every mutation keeps the UI in lockstep with the database without polling.

---

## 🤝 Connect

<div align="center">

[![GitHub](https://img.shields.io/badge/GitHub-mtahanaeem-181717?logo=github)](https://github.com/mtahanaeem)
[![LinkedIn](https://img.shields.io/badge/LinkedIn-Connect-0A66C2?logo=linkedin)](https://linkedin.com/in/mtahanaeem)

**If you find this project useful, consider giving it a ⭐!**

</div>
