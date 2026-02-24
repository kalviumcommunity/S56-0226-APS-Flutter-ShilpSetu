# 🎨 ShilpSetu

> A Vocal-for-Local Digital Marketplace for Artisans

ShilpSetu is a production-ready, mobile-first Flutter application that empowers local artisans and craftsmen with a digital storefront. Buyers discover and purchase authentic handmade products; sellers manage inventory and fulfil orders; and a platform admin maintains quality and oversight — all backed by Firebase and Cloudinary.

---

## 📖 Table of Contents

1. [Overview](#-overview)
2. [Features](#-features)
3. [Tech Stack](#-tech-stack)
4. [Architecture](#-architecture)
5. [Project Structure](#-project-structure)
6. [Getting Started](#-getting-started)
7. [Environment Configuration](#-environment-configuration)
8. [Running the App](#-running-the-app)
9. [Firestore Data Model](#-firestore-data-model)
10. [Security](#-security)
11. [Build & Release](#-build--release)
12. [Troubleshooting](#-troubleshooting)

---

## 📖 Overview

ShilpSetu ("Artisan Bridge") connects India's local craft communities with modern digital commerce. Sellers list handmade products with images, pricing, and geographic origin; buyers browse, review, and order directly; and an admin console provides platform-wide moderation and analytics.

The platform is built around three principles:
- **Simplicity** — artisans with minimal tech experience can manage a full storefront
- **Authenticity** — every product carries craft category, regional origin, and seller identity
- **Reliability** — atomic Firestore transactions ensure stock, orders, and ratings are always consistent

---

## ✨ Features

### 🛒 Buyer
| Feature | Detail |
|---|---|
| Product Discovery | Real-time stream, filter by category, sort by price / rating / newest |
| Product Detail | Full description, seller info, origin map (Google Maps), reviews |
| Cart | Multi-seller cart, quantity control, persistent across sessions |
| Address Management | Add / edit / delete saved delivery addresses |
| Checkout | Address selection → payment method → atomic order creation |
| Order History | Full order timeline with item thumbnails and status tracking |
| Reviews & Ratings | Leave star-rated reviews; admin-moderated |

### 🎨 Seller
| Feature | Detail |
|---|---|
| Product Management | Add / edit / delete products with Cloudinary image upload |
| Inventory | Stock tracking with low-stock and out-of-stock indicators |
| Orders | View incoming orders, update fulfilment status |
| Analytics | Revenue totals, top products, recent orders (cached FutureBuilder) |
| Profile | Public-facing seller profile with storefront grid |
| Location | Pin product geographic origin via GPS + Google Maps |

### 🛡️ Admin
| Feature | Detail |
|---|---|
| User Management | View all users, role assignments |
| Product Moderation | Browse and remove any product |
| Order Oversight | Platform-wide order list |
| Review Moderation | Delete reviews with atomic rating recalculation |
| Platform Analytics | Live stats — users, sellers, buyers, products, orders, revenue |

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter 3 (Dart, sound null safety) |
| State Management | Provider ^6 |
| Authentication | Firebase Auth ^5 |
| Database | Cloud Firestore ^5 |
| Image Storage | Cloudinary (unsigned upload preset) |
| Image Loading | cached_network_image ^3.3 |
| Maps | Google Maps Flutter ^2.12 |
| Location | geolocator ^13 + geocoding ^3 |
| Fonts | Google Fonts ^6 |
| HTTP | http ^1.2 |
| Formatting | intl ^0.19 |

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────┐
│             Flutter UI Layer            │
│  screens/  ←→  widgets/                 │
└────────────────┬────────────────────────┘
                 │ watches / reads
┌────────────────▼────────────────────────┐
│           Provider Layer                │
│  AuthProvider  ProductProvider          │
│  CartProvider                           │
└────────────────┬────────────────────────┘
                 │ calls
┌────────────────▼────────────────────────┐
│            Service Layer                │
│  ProductService   OrderService          │
│  ReviewService    AdminService          │
│  SellerService    AnalyticsService      │
│  AddressService   CloudinaryService     │
└────────────────┬────────────────────────┘
                 │
┌────────────────▼────────────────────────┐
│           Firebase / Cloudinary         │
│  Firestore  Auth  Cloudinary CDN        │
└─────────────────────────────────────────┘
```

**Key design decisions:**
- Services are pure data-layer classes — no BuildContext, no UI state
- All multi-document writes use a single `runTransaction` (atomic stock deduction + order creation)
- Review deletion recalculates `averageRating` inside a transaction — no stale stats
- `Future` results are cached in `initState` to prevent repeated Firestore reads on every rebuild
- Streams are created once (`late final`) and shared between multiple `StreamBuilder`s in the same screen

---

## 📁 Project Structure

```
lib/
├── main.dart                        # App entry, Firebase init, Provider setup
├── firebase_options.dart            # FlutterFire generated config
│
├── core/
│   ├── config/
│   │   └── env.dart                 # Build-time secrets (--dart-define)
│   ├── constants/
│   │   ├── colors.dart
│   │   ├── firestore_collections.dart
│   │   └── text_styles.dart
│   └── validators/
│
├── models/
│   ├── user_model.dart
│   ├── product_model.dart
│   ├── cart_item.dart
│   ├── order_model.dart
│   ├── review_model.dart
│   ├── review_with_product.dart
│   ├── address_model.dart
│   ├── seller_stats.dart
│   ├── analytics_model.dart
│   ├── platform_stats.dart
│   ├── top_product.dart
│   ├── sort_option.dart
│   └── time_period.dart
│
├── providers/
│   ├── auth_provider.dart
│   ├── product_provider.dart
│   └── cart_provider.dart
│
├── services/
│   ├── product_service.dart         # Product CRUD + Cloudinary upload
│   ├── order_service.dart           # Atomic order creation via runTransaction
│   ├── review_service.dart
│   ├── admin_service.dart           # Admin ops + atomic review deletion
│   ├── analytics_service.dart
│   ├── seller_service.dart
│   ├── address_service.dart
│   └── cloudinary_service.dart
│
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── signup_screen.dart
│   ├── buyer/
│   │   ├── buyer_dashboard.dart     # Single shared stream, filter + sort
│   │   ├── product_detail_screen.dart
│   │   ├── cart_screen.dart
│   │   ├── select_address_screen.dart
│   │   ├── manage_address_screen.dart
│   │   ├── add_edit_address_screen.dart
│   │   ├── payment_selection_screen.dart
│   │   ├── order_success_screen.dart
│   │   ├── order_history_screen.dart
│   │   └── add_review_screen.dart
│   ├── seller/
│   │   ├── seller_dashboard.dart    # TabController with listener for FAB
│   │   ├── add_product_screen.dart
│   │   ├── seller_orders_screen.dart
│   │   ├── analytics_screen.dart    # Cached FutureBuilder
│   │   ├── seller_profile_screen.dart
│   │   └── edit_seller_profile_screen.dart
│   ├── admin/
│   │   ├── admin_dashboard.dart
│   │   ├── users_tab.dart
│   │   ├── products_tab.dart
│   │   ├── orders_tab.dart
│   │   ├── reviews_tab.dart
│   │   └── platform_analytics_tab.dart  # Cached FutureBuilder + RefreshIndicator
│   └── common/
│
├── widgets/
│   ├── buyer_product_card.dart      # Animated card, shimmer, overflow-safe
│   ├── product_card.dart
│   ├── top_product_item.dart
│   ├── recent_order_item.dart
│   ├── metric_card.dart
│   ├── filter_bottom_sheet.dart
│   ├── app_card.dart
│   ├── custom_button.dart
│   └── custom_textfield.dart
│
└── utils/
```

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK ≥ 3.0.0 (`flutter doctor` should report no critical issues)
- Android Studio or VS Code with Flutter extension
- A Firebase project with **Authentication**, **Cloud Firestore** enabled
- A **Cloudinary** account with an unsigned upload preset
- A **Google Cloud** project with **Maps SDK for Android** enabled

### Step 1 — Clone

```bash
git clone https://github.com/ATHARVA279/S56-0226-APS-Flutter-ShilpSetu.git
cd S56-0226-APS-Flutter-ShilpSetu
```

### Step 2 — Install dependencies

```bash
flutter pub get
```

### Step 3 — Firebase setup

1. In [Firebase Console](https://console.firebase.google.com), create a project
2. Enable **Email/Password** sign-in under Authentication
3. Create a **Cloud Firestore** database (start in production mode, then apply the rules below)
4. Download `google-services.json` and place it at:

```
android/app/google-services.json
```

### Step 4 — Firestore security rules

Deploy the included `firestore.rules` file:

```bash
firebase deploy --only firestore:rules
```

Or paste the contents directly into the Firebase Console → Firestore → Rules tab.

### Step 5 — Google Maps API key

In `android/local.properties` add:

```properties
MAPS_API_KEY=YOUR_GOOGLE_MAPS_API_KEY
```

---

## 🔐 Environment Configuration

Cloudinary credentials are injected at **build time** via `--dart-define` — they are never hardcoded in source.

```dart
// lib/core/config/env.dart
class Environment {
  static const String cloudinaryCloudName =
      String.fromEnvironment('CLOUDINARY_CLOUD_NAME');
  static const String cloudinaryUploadPreset =
      String.fromEnvironment('CLOUDINARY_UPLOAD_PRESET');
}
```

Pass them on every `flutter run` / `flutter build` call:

```bash
flutter run \
  --dart-define=CLOUDINARY_CLOUD_NAME=your_cloud_name \
  --dart-define=CLOUDINARY_UPLOAD_PRESET=your_upload_preset
```

> **Tip:** In VS Code, add these to `.vscode/launch.json` under `"toolArgs"` so you never have to type them manually.

```json
{
  "configurations": [
    {
      "name": "ShilpSetu (debug)",
      "request": "launch",
      "type": "dart",
      "toolArgs": [
        "--dart-define=CLOUDINARY_CLOUD_NAME=your_cloud_name",
        "--dart-define=CLOUDINARY_UPLOAD_PRESET=your_upload_preset"
      ]
    }
  ]
}
```

---

## ▶️ Running the App

```bash
# Debug on a connected device / emulator
flutter run \
  --dart-define=CLOUDINARY_CLOUD_NAME=xxx \
  --dart-define=CLOUDINARY_UPLOAD_PRESET=yyy

# Release mode on device
flutter run --release \
  --dart-define=CLOUDINARY_CLOUD_NAME=xxx \
  --dart-define=CLOUDINARY_UPLOAD_PRESET=yyy
```

---

## 🗄️ Firestore Data Model

```
/users/{userId}
  name          : String
  email         : String
  role          : "buyer" | "seller" | "admin"
  profileImageUrl : String?
  phone         : String?
  createdAt     : Timestamp

/products/{productId}
  sellerId      : String
  sellerName    : String
  title         : String
  description   : String
  price         : Number
  category      : String
  imageUrl      : String
  isActive      : Boolean
  stock         : Number
  averageRating : Number
  reviewCount   : Number
  originLat     : Number?
  originLng     : Number?
  originCity    : String?
  createdAt     : Timestamp

  /reviews/{reviewId}
    buyerId     : String
    buyerName   : String
    rating      : Number (1–5)
    comment     : String
    createdAt   : Timestamp

/orders/{orderId}
  buyerId       : String
  sellerId      : String
  items         : Array<OrderItem>
  totalAmount   : Number
  status        : "pending" | "processing" | "shipped" | "delivered" | "cancelled"
  paymentMethod : String
  addressId     : String
  createdAt     : Timestamp

/addresses/{addressId}
  userId        : String
  label         : String
  street        : String
  city          : String
  state         : String
  pincode       : String
```

> **Atomicity guarantee:** `OrderService.createOrders()` runs a single `runTransaction` that reads all product documents, validates stock, deducts inventory, and writes all order documents in one atomic operation. Partial fulfilment is impossible.

---

## 🔒 Security

| Concern | Implementation |
|---|---|
| Auth secrets | Firebase Auth — no passwords stored in Firestore |
| Image secrets | `--dart-define` build-time injection; no defaults in source |
| Firestore rules | Role-verified server-side rules (`hasRole()` checks `/users/{uid}.role`) |
| Seller-only create | `isSeller()` rule required to write to `/products` |
| Review integrity | Only authenticated buyers can create; only admin can delete |
| Logging | All debug output uses `debugPrint` inside `kDebugMode` guards — nothing logged in release builds |
| Image loading | `CachedNetworkImage` throughout — no raw `Image.network` calls |

---

## 📦 Build & Release

```bash
# Release APK
flutter build apk --release \
  --dart-define=CLOUDINARY_CLOUD_NAME=xxx \
  --dart-define=CLOUDINARY_UPLOAD_PRESET=yyy

# App Bundle (Play Store)
flutter build appbundle --release \
  --dart-define=CLOUDINARY_CLOUD_NAME=xxx \
  --dart-define=CLOUDINARY_UPLOAD_PRESET=yyy

# iOS (macOS only)
flutter build ios --release \
  --dart-define=CLOUDINARY_CLOUD_NAME=xxx \
  --dart-define=CLOUDINARY_UPLOAD_PRESET=yyy
```

Output APK path:
```
build/app/outputs/flutter-apk/app-release.apk
```

---

## ❗ Troubleshooting

**`google-services.json` not found / Firebase init fails**
```bash
ls android/app/google-services.json   # verify the file exists
flutter clean && flutter pub get && flutter run
```

**Image uploads fail**
- Confirm `CLOUDINARY_CLOUD_NAME` and `CLOUDINARY_UPLOAD_PRESET` are passed via `--dart-define`
- Ensure the upload preset is set to **Unsigned** in your Cloudinary dashboard

**Maps not rendering**
- Verify `MAPS_API_KEY` is set in `android/local.properties`
- Confirm **Maps SDK for Android** is enabled in Google Cloud Console for that key

**Build errors after pulling**
```bash
flutter clean
flutter pub get
cd android && ./gradlew clean && cd ..
flutter run
```

**Overflow / layout errors**
- These have been resolved in the final code. If you see new ones, check that `GridView` cell sizes haven't changed and that `buyer_product_card.dart` uses `mainAxisSize: MainAxisSize.max` with an `Expanded` title.