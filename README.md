# Foam Shop ERP — Digital Register

**v1.5.0** — A modern, high-performance Flutter application for real-time inventory management, sales tracking, dynamic register slip generation, and customer Khata (ledger) settlements.

Built with Material 3 design language, Riverpod state management, and Firebase backend.

---

## Features

- **📊 Reactive Dashboard** — Real-time business analytics (Revenue, COGS, Net Profit, Cash in Hand) with dynamic register slip numbering (`#0001` auto-incrementing)
- **📦 Inventory Management** — Search, filter (All/Low Stock), restock with WAC costing, and low-stock alerts with animated UI
- **💳 Sales Entry** — Product search with live highlighting, recent-item chips, multi-item cart, partial payments, and save-success modal
- **👤 Customer Khata** — Per-customer ledger with transaction history, dynamic item-level descriptions, over-collection protection, and torn-receipt balance card
- **🏢 Supplier Khata** — Purchase ledger with payment tracking and balance calculation
- **📄 Report Export** — CSV, styled XLSX (with teal header + frozen rows), and branded PDF reports
- **🖨 Receipt PDF** — Branded receipt with itemized table, totals card, and paid/due status badge
- **🔔 Update Checker** — In-app version check against GitHub releases
- **🎨 Premium UI** — Floating pill nav bar with amber dot indicators, scale-feedback buttons, haptic touch, staggered list animations, and smooth route transitions

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter (Dart) |
| State Management | Riverpod |
| Backend | Firebase Auth, Cloud Firestore |
| PDF | `pdf` + `printing` |
| Excel | `excel` |
| Animations | `flutter_animate` |
| CI/CD | GitHub Actions (auto-build + release on tags) |

---

## Getting Started

```bash
# Clone the repo
git clone https://github.com/tahasync/foam-shop-erp.git
cd foam-shop-erp

# Install dependencies
flutter pub get

# Set up Firebase config (see SETUP.md)
cp env/firebase_config.example.json env/firebase_config.json
# Edit env/firebase_config.json with your Firebase project keys

# Run
flutter run --dart-define-from-file=env/firebase_config.json

# Build release APK
flutter build apk --release --dart-define-from-file=env/firebase_config.json
```

See [SETUP.md](SETUP.md) for detailed Firebase configuration steps.

---

## Build & Release

| Command | Description |
|---|---|
| `flutter analyze` | Static analysis — must be clean before release |
| `flutter build apk --release` | Universal APK |
| `flutter build apk --release --split-per-abi` | Per-architecture APKs |
| `git tag vX.Y.Z && git push --tags` | Triggers automated CI build + GitHub Release |

---

## Architecture

```
lib/
├── models/          # Data models (Sale, Product, Customer, Payment, etc.)
├── providers/       # Riverpod providers (streams + state)
├── screens/         # UI screens (Dashboard, Sales, Inventory, Khata, etc.)
├── services/        # Firebase service, accounting, export, PDF, update checker
├── widgets/         # Reusable widgets (CustomNavBar, TornReceiptCard, ScaleButton, etc.)
├── theme/           # AppTheme, AppColors (light + dark)
└── utils/           # Debouncer utility
```

---

## License

MIT
