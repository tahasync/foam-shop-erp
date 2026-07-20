# Asif Foam Center — Flutter ERP

# Foam Shop ERP

**Enterprise-Grade Retail Inventory & Accounting System**

[![Flutter](https://img.shields.io/badge/Flutter-3.44+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.12-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Firestore-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com)
[![Riverpod](https://img.shields.io/badge/State-Riverpod-4DB33D?logo=flutter&logoColor=white)](https://riverpod.dev)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)
[![Android](https://img.shields.io/badge/Platform-Android%205.0+-3DDC84?logo=android&logoColor=white)](https://developer.android.com)

</div>
Complete inventory management, point-of-sale, and customer ledger (Khata) system built with Flutter + Firebase.

---

## Project Overview

A single-user ERP for a foam (polyurethane foam) shop. The app manages products (foam sheets/blocks by size, thickness, density), tracks inventory stock, records sales with partial/full payment, maintains customer Khata ledgers, and logs supplier purchases and operational expenses.

**Tech Stack**
- Flutter 3.x (Dart)
- Firebase Auth (email/password)
- Cloud Firestore
- Riverpod (state management)
- Material 3 (M3 theming)

---

## App Architecture

```
lib/
├── main.dart                    # App entry, Firebase init, router
├── theme/
│   └── app_theme.dart           # Light/dark M3 palette, custom colors
├── models/
│   ├── product.dart             # Product (dimensions, unitPrice, costPrice, stock)
│   ├── customer.dart            # Customer (name, phone)
│   ├── supplier.dart            # Supplier (name, phone)
│   ├── sale.dart                # Sale + SaleLineItem (qty, salePrice, discounts)
│   ├── payment.dart             # Customer payment recovery
│   ├── purchase.dart            # Supplier purchase (stock restock)
│   ├── expense.dart             # Operational expense
│   ├── supplier_payment.dart    # Supplier payment
│   └── opening_balance.dart     # Capital / opening balance entry
├── services/
│   └── firestore_service.dart   # All Firestore CRUD + atomic transactions
├── providers/
│   ├── firebase_providers.dart  # FirestoreService provider
│   ├── product_provider.dart    # Products stream
│   ├── customer_provider.dart   # Customers stream
│   ├── sale_provider.dart       # Sales stream
│   ├── payment_provider.dart    # Payments stream
│   ├── sales_provider.dart      # Sale cart state (CartItem, SalesNotifier)
│   └── dashboard_provider.dart  # Aggregated accounting summaries
├── screens/
│   ├── login_screen.dart
│   ├── home_screen.dart         # Dashboard with summary cards
│   ├── inventory_screen.dart    # Product list, add/edit, restock
│   ├── sales_entry_screen.dart  # New Sale (product picker, cart, save)
│   ├── customer_khata_screen.dart # Customer ledger (balance, transactions)
│   ├── customer_recovery_screen.dart
│   ├── supplier_khata_screen.dart
│   └── ... other screens
```

---

## Models

### Product (`lib/models/product.dart`)

| Field | Type | Description |
|-------|------|-------------|
| `id` | `String` | Firestore doc ID |
| `name` | `String` | Product name |
| `type` | `String` | Product type/category |
| `sizeLength`, `sizeWidth` | `double` | Dimensions in inches |
| `thickness` | `double` | Foam thickness |
| `density` | `double` | Foam density |
| `unitType` | `String` | `'per_sqft'` or `'pcs'` |
| `unitPrice` | `double` | Default selling price |
| `costPrice` | `double` | Supplier buying cost |
| `currentStock` | `double` | Available stock |
| `lowStockThreshold` | `double` | Min stock alert |
| `isArchived` | `bool` | Soft delete flag |

**Getters:**
- `effectivePrice` — Returns `unitPrice` if > 0, else `costPrice`, else 0
- `unitLabel` — Returns `'sq.ft'` or `'pcs'` based on `unitType`
- `isLowStock` — `currentStock <= lowStockThreshold`
- `stockLabel` — Formatted stock string with unit

### Customer (`lib/models/customer.dart`)

| Field | Type |
|-------|------|
| `id` | `String` |
| `name` | `String` |
| `phone` | `String` |
| `isArchived` | `bool` |

### SaleLineItem (`lib/models/sale.dart`)

| Field | Type | Description |
|-------|------|-------------|
| `productId` | `String` | Product reference |
| `name` | `String?` | Snapshot name |
| `qtyOrArea` | `double` | Quantity / square footage |
| `salePrice` | `double` | Per-unit selling price |
| `lineDiscountAmount` | `double` | Per-item discount |
| `costPriceAtSale` | `double` | Cost at time of sale |
| `*lineTotal` | getter | `(qtyOrArea × salePrice) - lineDiscountAmount` |

### Sale (`lib/models/sale.dart`)

| Field | Type |
|-------|------|
| `id` | `String` |
| `date` | `DateTime` |
| `customerId` | `String` |
| `customerName` | `String?` |
| `lineItems` | `List<SaleLineItem>` |
| `paid` | `double` |
| `discountAmount / discountPercent` | `double?` |
| `deliveryCharge / cuttingCharge` | `double?` |
| `isVoided` | `bool` |
| `isQuote` | `bool` |

**Getters:** `subtotal`, `totalDiscount`, `amount`, `balance`

### Payment (`lib/models/payment.dart`)

| Field | Type |
|-------|------|
| `id` | `String` |
| `date` | `DateTime` |
| `customerId` | `String` |
| `amountCollected` | `double` |

---

## Firestore Structure

```
users/{uid}/
  products/{id}          # Product documents
  customers/{id}         # Customer documents
  suppliers/{id}         # Supplier documents
  sales/{id}             # Sale documents
  purchases/{id}         # Purchase / restock documents
  payments/{id}          # Customer payment recovery
  expenses/{id}          # Operational expenses
  supplier_payments/{id} # Supplier payments
  opening_balances/{id}  # Capital entries
```

### Atomic Transactions

**`saveSaleTransaction(sale, deductions)`**
1. Writes the Sale document
2. Deducts `currentStock` for each product atomically

**`restockTransaction(productId, qty, unitCost, amountPaid)`**
1. Updates product `currentStock` and `costPrice` (weighted average)
2. Creates a Purchase record

**`voidSale(saleId, reason)`**
1. Marks sale as voided
2. Restores stock atomically

---

## Cart & Sales Engine (`lib/providers/sales_provider.dart`)

### CartItem

| Field | Type | Description |
|-------|------|-------------|
| `product` | `Product` | The product reference |
| `quantity` | `int` | Quantity in cart |
| `salePrice` | `double` | Editable per-unit selling price |
| `*lineTotal` | getter | `quantity × salePrice` |

### SalesNotifier

| Method | Description |
|--------|-------------|
| `addToCart(product)` | Adds or increments cart item (initial `salePrice = product.effectivePrice`) |
| `removeFromCart(productId)` | Removes item |
| `changeQty(productId, delta)` | Increments/decrements quantity (clamped 1..stock) |
| `updateItemPrice(productId, newPrice)` | Updates per-unit selling price for a cart item |
| `setCustomer(name)` | Sets customer name |
| `clearCart()` | Empties cart |

---

## Selling Flow

1. Open **New Sale**
2. (Optional) Tap "Change" to set customer name
3. Tap a product from the product list → added to cart with `effectivePrice` pre-filled
4. Edit the **Selling Price** (PKR/unit) directly in the cart item
5. Adjust **Quantity** with `−` / `+` buttons
6. Enter **Paid (PKR)** amount
7. Balance auto-calculates as `subtotal - paid`
8. Tap **Save Sale**:
   - Writes Sale document with all line items
   - Deducts stock atomically
   - Creates a Payment record for the paid amount
   - Clears cart
9. Navigate to **Customer Khata** to see updated outstanding balance

---

## Khata (Customer Ledger)

### CustomerKhataScreen
- Lists all customers with computed `balance = sum(sale.amount) - sum(payment.amountCollected)`
- Tapping a customer opens detail view showing:
  - **Outstanding Baqaya** (total)
  - **Transaction History** (sales + payments, sorted descending)
- "Collect Payment" button creates a Payment record

---

## Dialog Lifecycle Fixes

All modal dialogs (`AddProductDialog`, `EditProductDialog`, `RestockDialog`) follow:

1. **Proper `StatefulWidget` lifecycle** — controllers created in `initState`, disposed in `dispose()` with listeners removed first
2. **`FocusScope.of(context).unfocus()`** — called before any async Firestore operation to detach active focus dependencies
3. **`if (!mounted) return`** — guarded after every `await` call
4. **`try`/`on Exception`** — errors caught to prevent unhandled rejections

---

## Theme (`lib/theme/app_theme.dart`)

- Material 3 color scheme with custom amber/teal brand colors
- Dark mode: background `#12171A`, surface `#1A2124`  
- Light mode: clean white/light-gray surfaces
- Custom `AppColors` extension with semantic tints (sale, profit, expense, inventory)

---

## Fixes Applied

| # | Fix | Files |
|---|-----|-------|
| 1 | `effectivePrice` getter (fallback `unitPrice` → `costPrice` → 0) | `lib/models/product.dart` |
| 2 | `unitLabel` getter (dynamic `sq.ft` / `pcs`) | `lib/models/product.dart` |
| 3 | `CartItem.lineTotal` delegates to `effectivePrice` | `lib/providers/sales_provider.dart` |
| 4 | Product selector card uses `effectivePrice` | `lib/screens/sales_entry_screen.dart` |
| 5 | Cart subtitle uses `effectivePrice` + `unitLabel` | `lib/screens/sales_entry_screen.dart` |
| 6 | `SaleLineItem.salePrice` uses `effectivePrice` | `lib/screens/sales_entry_screen.dart` |
| 7 | Extracted `_AddProductDialog` (proper `StatefulWidget`) | `lib/screens/inventory_screen.dart` |
| 8 | Extracted `_EditProductDialog` (proper `StatefulWidget`) | `lib/screens/inventory_screen.dart` |
| 9 | `RestockDialog`: listener cleanup, `unfocus()`, mounted guards | `lib/screens/inventory_screen.dart` |
| 10 | `CartItem.salePrice` editable field (user-overridable) | `lib/providers/sales_provider.dart` |
| 11 | `updateItemPrice()` in `SalesNotifier` | `lib/providers/sales_provider.dart` |
| 12 | Editable selling price field in `CartWidget` | `lib/screens/sales_entry_screen.dart` |
| 13 | Payment record auto-created on sale save | `lib/screens/sales_entry_screen.dart` |

---

## Build & Run

```bash
# Dependencies
flutter pub get

# Development
flutter run

# Release APK
flutter build apk --release

# Output
build/app/outputs/flutter-apk/app-release.apk

# Static analysis
flutter analyze
```

---

## Verification Checklist

- [ ] `flutter analyze` — 0 issues
- [ ] Open New Sale → Select product → editable selling price shows `effectivePrice`
- [ ] Change selling price in cart → line total recalculates
- [ ] Adjust quantity → total updates
- [ ] Enter partial payment → balance auto-calculates
- [ ] Save Sale → Payment record created in Firestore
- [ ] Customer Khata → balance matches sum(sales) − sum(payments)
- [ ] Add product dialog → opens/closes without context assertion
- [ ] Edit product → saves correctly
- [ ] Restock → live total calculation, atomic stock update
- [ ] Dark/Light theme toggle → readable text contrast
