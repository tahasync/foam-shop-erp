# Foam Shop POS

A Flutter POS and ledger app for **Asif Foam Center** with real-time Firestore sync, inventory costing, customer/seller Khata, expense tracking, and PDF/XLSX/CSV exports.

## What it does

Single-user (per Firebase Auth account) Flutter app managing a foam shop's daily operations: weighted average cost (WAC) inventory with low-stock alerts; sales entry with multi-item cart, partial payments, discounts, and delivery charges; customer ledger with per-item transaction history; supplier purchase tracking; expense recording; a real-time dashboard showing revenue, COGS, net profit, and cash; export to styled XLSX, CSV, and branded PDF receipts.

Data is live-synced to Firestore — each user sees only their own data (partitioned by `uid`).

## Tech stack

- **Framework:** Flutter (Dart 3.4+) + Riverpod 3
- **Backend:** Firebase Auth (Google Sign-In), Cloud Firestore, Crashlytics, Performance
- **Exports:** `pdf` + `printing`, `excel`, `csv`
- **UI:** `flutter_animate`, `shimmer`, `fl_chart`, `flutter_svg`
- **CI/CD:** GitHub Actions — deterministic APK builds on `v*` tags

## Features

- **Dashboard** — real-time revenue, COGS, net profit, cash-in-hand, register slip counter, low-stock alert tap → filtered inventory
- **Inventory** — search, filter, restock with WAC costing, low-stock threshold, archive
- **Sales entry** — product search with highlights, multi-item cart, partial payments, balance tracking, quotes
- **Customer Khata** — per-customer item-level ledger, payment collection with over-collection protection, balance card
- **Supplier Khata** — purchase ledger with payment tracking
- **Expenses** — category-based expense tracking
- **Exports** — CSV, styled XLSX (teal header + frozen rows), branded PDF with receipt printing
- **Theming** — light + dark mode with floating pill navigation

## Security

This project underwent a comprehensive security audit covering:

- **Rate limiting** — dual-key (device + account) throttling on auth with env-driven config
- **Input validation** — model-level assertions + `FormatException` rejection on all 9 models (Product, Sale, Customer, Supplier, Purchase, Expense, Payment, SupplierPayment, OpeningBalance)
- **Secrets management** — all Firebase keys and OAuth client IDs externalized to `env/firebase_config.json` (gitignored). Git history BFG-purged. No secrets in any commit or tag.
- **Error handling** — safe sanitizer masks Firebase and `PlatformException` stack traces from all 10 screens. Structured server-side logging via `logSecureError`.
- **Firestore rules** — field-level type guards, date validation, line-item schema enforcement, `transaction_uuid` idempotency, unknown collection denial
- **Dependency audit** — all 10 key dependencies updated to latest compatible versions (firebase_core 4.12.1, firebase_auth 6.5.6, pdf 3.12.0, http 1.6.0, etc.)
- **CSV injection** — formula prefix sanitization (`=`, `+`, `-`, `@` cells prefixed with apostrophe)
- **Build fix** — `applicationId` corrected to `com.asif.foamshop`, matching Firebase client entry

## Platform support

- **Android** — fully supported, CI builds universal release APKs on every `v*` tag
- **iOS** — Xcode project exists, CI does not build for iOS
- **Web / macOS / Windows / Linux** — scaffolding only

## Setup

```bash
git clone https://github.com/tahasync/foam-shop-pos.git
cd foam-shop-pos
flutter pub get

# 1. Create your own Firebase project
# 2. Download google-services.json → android/app/ (gitignored)
# 3. Create env/firebase_config.json with dart-define keys (see env/firebase_config.example.json)
# 4. Add FIREBASE_WEB_CLIENT_ID to the config for Google Sign-In

flutter run --dart-define-from-file=env/firebase_config.json
```

## CI/CD

Every push to `main` builds a debug APK. Every `v*` tag builds a release APK, signs it with the release keystore, and attaches it to a GitHub release.

```bash
git tag v1.0.1
git push origin v1.0.1
```

The pipeline uses:
- Flutter 3.44.6 pinned (deterministic)
- `pubspec.lock` committed for reproducible dependency resolution
- Base64-encoded Firebase config for reliable secret injection
- `google-services.json` validated against `applicationId` before build

## Status

**Production-grade Android app — actively maintained at Asif Foam Center.** No automated tests yet.
