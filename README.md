# Foam Shop — Digital Register (POS + Khata)

A Flutter POS/register app for **Asif Foam Center** with real-time Firestore-based inventory, sales, customer/supplier ledgers (Khata), expense tracking, PDF/XLSX/CSV exports, and printed receipts.

## What it does

Single-user (per Firebase Auth account) Flutter app that manages a foam shop's daily operations: inventory with Weighted Average Cost (WAC) costing and low-stock alerts; sales entry with multi-item cart, partial payments, discounts, and delivery charges; customer ledger with per-item transaction history and over-collection protection; supplier purchase tracking; expense recording; a real-time dashboard showing revenue, COGS, net profit, and cash; and export to styled XLSX, CSV, and branded PDF receipts with printing.

**Data is live-synced to Firebase Cloud Firestore** (not local-only). Each Firebase Auth user sees only their own data (partitioned by `uid`). This is not a collaborative multi-user system.

## Tech stack

- **Framework:** Flutter (Dart) + Riverpod (state management)
- **Backend:** Firebase Auth, Cloud Firestore, Firebase Crashlytics + Performance
- **Auth:** Email/password + Google Sign-In
- **Exports:** `pdf` + `printing`, `excel`, `csv`
- **UI:** `flutter_animate`, `shimmer`, `fl_chart`, `flutter_svg`
- **CI/CD:** GitHub Actions (Android APK on `v*` tags)

## Features

- **Dashboard** — real-time revenue, COGS, net profit, cash in hand, register slip counter
- **Inventory** — search, filter, restock with WAC costing, low-stock alerts
- **Sales entry** — product search with highlights, multi-item cart, partial payments, discounts, delivery/cutting charges
- **Customer Khata** — per-customer item-level ledger, over-collection protection, balance card
- **Supplier Khata** — purchase ledger with payment tracking
- **Expenses** — track shop expenses with categories
- **Exports** — CSV, styled XLSX (teal header + frozen rows), branded PDF with receipt printing
- **Theming** — full light + dark mode, floating pill nav, staggered animations

## Platform support

- **Android** — fully supported, CI builds release APKs
- **iOS** — Xcode project + Podfile exist, but CI does not build for iOS
- **Web / macOS / Windows / Linux** — Firebase throws `UnsupportedError`; these are scaffolding only

## Setup

```bash
git clone https://github.com/tahasync/foam-shop-erp.git
cd foam-shop-erp
flutter pub get

# Firebase setup (see SETUP.md)
# Create your own Firebase project, download google-services.json to android/app/
# Create env/firebase_config.json with your dart-define keys:
#   FIREBASE_ANDROID_API_KEY, FIREBASE_ANDROID_APP_ID, etc.
# See env/.gitkeep for the required key names

flutter run --dart-define-from-file=env/firebase_config.json
```

### Build release

```bash
flutter build apk --release --dart-define-from-file=env/firebase_config.json
```

### Trigger CI build

```bash
git tag v1.5.0
git push origin v1.5.0
```

## Security notice

The file `env/firebase_config.json` previously contained live Firebase API keys committed to git. This has been moved to `.gitignore`. If you forked or cloned before this fix, rotate your Firebase API keys immediately and remove the file from any public repos.

## Status

**Production-grade Android app — actively maintained.** Used at Asif Foam Center. No automated tests exist (risky for a financial POS). Some platform folders (web/macOS/Windows/Linux) are non-functional scaffolding. iOS is configured but not built in CI.