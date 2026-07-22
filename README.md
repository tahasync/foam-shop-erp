<div align="center">

# Foam Shop ERP

**Enterprise-Grade Retail Inventory & Accounting System**

[![Flutter](https://img.shields.io/badge/Flutter-3.44+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.12-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Firestore-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com)
[![Riverpod](https://img.shields.io/badge/State-Riverpod-4DB33D?logo=flutter&logoColor=white)](https://riverpod.dev)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)
[![Android](https://img.shields.io/badge/Platform-Android%205.0+-3DDC84?logo=android&logoColor=white)](https://developer.android.com)

Complete inventory management, point-of-sale, and customer ledger (Khata) system built with Flutter + Firebase.

</div>

---

## ✨ Features

- **📦 Inventory Management** — Products by size, thickness, density with stock tracking & low-stock alerts
- **🧾 Point of Sale** — Quick sales entry with editable pricing, discounts, and partial payments
- **📒 Customer Khata** — Ledger-based outstanding balance tracking with payment collection
- **🏭 Supplier Management** — Purchase/restock logging with weighted-average cost calculation
- **💰 Expense Tracking** — Operational expense logging with reporting
- **📊 Dashboard** — Aggregated accounting summaries (total sales, balances, profit overview)
- **🌓 Dark/Light Theme** — Material 3 with custom amber/teal color scheme
- **☁️ Cloud Sync** — Firebase Firestore with atomic transactions for stock consistency

---

## 🛠 Tech Stack

| Layer | Technology |
|-------|-----------|
| **Frontend** | Flutter 3.x, Dart |
| **State Management** | Riverpod |
| **Backend** | Firebase Auth, Cloud Firestore |
| **Theming** | Material 3 |
| **Platform** | Android 5.0+ |

---

## 📁 Project Structure

```
lib/
├── main.dart                   # App entry, Firebase init, router
├── theme/
│   └── app_theme.dart          # Light/dark M3 palette
├── models/                     # Product, Customer, Sale, Payment, etc.
├── services/
│   └── firestore_service.dart  # Firestore CRUD + atomic transactions
├── providers/                  # Riverpod state providers
└── screens/                    # Login, Dashboard, Inventory, Sales, Khata, etc.
```

---

## 🚀 Quick Start

### Prerequisites

- Flutter SDK 3.x
- Firebase project with Firestore + Auth enabled

### Setup

```bash
# Clone the repository
git clone https://github.com/tahasync/foam-shop-erp.git
cd foam-shop-erp

# Install dependencies
flutter pub get

# Run in development
flutter run

# Build release APK
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk

# Static analysis
flutter analyze
```

---

## 🔐 Firebase Setup

1. Create a project at [Firebase Console](https://console.firebase.google.com)
2. Enable **Email/Password Authentication**
3. Create a **Cloud Firestore** database
4. Download `google-services.json` and place in `android/app/`
5. Enable offline persistence (handled by Firestore SDK)

---

## 🧠 Core Logic

### Selling Flow

```
Select Products → Edit Prices → Set Paid Amount → Save Sale
  ├─ Atomic stock deduction per product
  ├─ Payment record auto-created
  └─ Customer balance updated
```

### Accounting Engine

- Sales track cost price at time of sale for profit calculation
- Restock uses weighted-average cost price
- Customer balance = `sum(sales.amount) - sum(payments)`
- Automatic stock restoration on voided sales

---

## 👤 Author

<div align="center">

**Muhammad Taha Naeem**

[![GitHub](https://img.shields.io/badge/GitHub-tahasync-181717?logo=github)](https://github.com/tahasync)
[![LinkedIn](https://img.shields.io/badge/LinkedIn-heyitxtaha-0A66C2?logo=linkedin)](https://linkedin.com/in/heyitxtaha)

</div>
