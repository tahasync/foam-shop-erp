# 📋 Foam Shop ERP — Digital Register

A modern Flutter-based ERP for **Asif Foam Center** — real-time inventory management, POS checkout, customer/supplier Khata (ledgers), purchases, expenses, and financial reporting.

---

## ✨ Features

| Module | Capabilities |
|:-------|:-------------|
| **📊 Dashboard** | Real-time Revenue, COGS, Net Profit, Cash in Hand, auto-incrementing register slip |
| **📦 Inventory** | Search, filter (All/Low Stock), restock with WAC costing, low-stock alerts |
| **💳 Sales Entry** | Product search with live highlights, recent-item chips, multi-item cart, partial payments, save-success modal |
| **👤 Customer Khata** | Per-customer ledger with item-level transaction history, over-collection protection, torn-receipt balance card |
| **🏢 Supplier Khata** | Purchase ledger with payment tracking, balance calculation |
| **📄 Reports** | CSV, styled XLSX (teal header + frozen rows), branded PDF export |
| **🖨 Receipt PDF** | Branded receipt with itemized table, totals card, paid/due status badge |
| **🔔 Update Checker** | In-app version check against GitHub releases |

---

## 🎨 Premium UI

- Floating pill navigation bar with amber dot indicators
- Scale-feedback buttons with haptic touch
- Staggered list animations with `flutter_animate`
- Smooth route transitions (`ZoomPageTransitionsBuilder` / `CupertinoPageTransitionsBuilder`)
- Full light + dark theme support

---

## 🛠 Tech Stack

| Layer | Technology |
|:------|:-----------|
| Framework | Flutter (Dart) |
| State Management | Riverpod |
| Backend | Firebase Auth, Cloud Firestore |
| PDF | `pdf` + `printing` |
| Excel | `excel` |
| Animations | `flutter_animate` |
| CI/CD | GitHub Actions (auto-build + release on `v*` tags) |

---

## 🚀 Getting Started

```bash
git clone https://github.com/tahasync/foam-shop-erp.git
cd foam-shop-erp
flutter pub get

# Firebase setup (see SETUP.md)
cp env/firebase_config.example.json env/firebase_config.json
# Edit env/firebase_config.json with your Firebase project keys

flutter run --dart-define-from-file=env/firebase_config.json
```

### Build Release

```bash
flutter build apk --release --dart-define-from-file=env/firebase_config.json
```

---

## 📁 Project Structure

```
lib/
├── models/        # Data models
├── providers/     # Riverpod providers
├── screens/       # UI screens
├── services/      # Firebase, accounting, export, PDF
├── widgets/       # Reusable widgets
├── theme/         # AppTheme, AppColors
└── utils/         # Utilities
design/            # UI mockup references
env/               # Firebase config (gitignored)
```

---

## 📦 Release

Tag a version to trigger automated CI build:

```bash
git tag v1.5.0
git push origin v1.5.0
```

GitHub Actions builds and attaches APKs (split + universal) to the Release.

---

## 👤 Author

**Muhammad Taha Naeem** — [@tahasync](https://github.com/tahasync)
