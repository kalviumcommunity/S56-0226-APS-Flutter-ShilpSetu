# 🎨 ShilpSetu

A Vocal-for-Local Digital Marketplace for Artisans 🛍️

---

## 📖 Overview

**ShilpSetu** is a mobile-first application designed to empower local artisans and craftsmen by providing a simple and accessible digital storefront. The app enables artisans to showcase handmade products, manage orders, and connect directly with buyers while preserving craft identity, regional origin, and cultural value.

Unlike generic e-commerce platforms, ShilpSetu emphasizes community-driven commerce, where every product represents the artisan, the craft, and its locality.

---

## ⚠️ Problem Statement

Local artisans face significant challenges in adopting digital platforms. They often lack an easy way to display their creations online, manage orders efficiently, or reach buyers beyond physical markets and exhibitions. Existing e-commerce solutions are complex, commission-heavy, and fail to reflect the cultural and local identity of handmade crafts.

---

## 💡 Solution

ShilpSetu provides a lightweight, mobile-first digital storefront that allows artisans to create personalized stores, list products with craft stories and origin details, manage carts and orders, and interact directly with buyers. The platform bridges the gap between traditional craftsmanship and modern digital commerce while supporting the “Vocal for Local” initiative.

---

## 👥 Target Users

* 🎭 Local artisans and craftsmen.
* 🏺 Small-scale handmade product sellers.
* 🤝 Self-help groups (SHGs) and NGOs supporting artisans.
* 🛒 Buyers seeking authentic local and handmade products.

---

## ✨ Key Features

### 👨‍🎨 Artisan Features

* Create and manage a personal storefront
* Upload products with images, pricing, and craft details
* Highlight product origin and artisan story
* Manage orders and quantities through a simple dashboard

### 🛍️ Buyer Features

* Browse artisan storefronts
* View product details with craft and locality information
* Add products to cart with quantity selection
* Place and track orders

---

## 🎯 MVP Scope

### ✅ Implemented Features

* **Authentication System**: Firebase Auth with role-based routing (buyer/seller)
* **Seller Dashboard**: Add, edit, delete products with image upload
* **Buyer Dashboard**: Browse products with pagination and infinite scroll
* **Product Management**: Full CRUD operations with Cloudinary image storage
* **Shopping Cart**: Add/remove items, quantity management
* **Order System**: Complete order placement with cart-to-order conversion
* **Data Persistence**: Firestore real-time database with offline support
* **State Management**: Provider pattern for auth, products, and cart

### 🚀 Planned for Phase 2

* Online payment integration
* Multi-language support
* Reviews and ratings
* Delivery and logistics tracking
* Push notifications

---

## 🛠️ Tech Stack

### 📱 Frontend

* Flutter
* Dart
* Provider (state management)

### ☁️ Backend (BaaS)

* Firebase Authentication
* Cloud Firestore
* Firebase Storage
* Cloudinary (Image Upload & CDN)

### 🔧 Tools and Platforms

* Android Studio or Visual Studio Code
* Git and GitHub
* GitHub Actions for CI/CD (optional)

---

## 📁 Project Structure

```plaintext
lib/
│
├── main.dart
├── firebase_options.dart
│
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── signup_screen.dart
│   ├── buyer/
│   │   ├── buyer_dashboard.dart
│   │   ├── product_detail_screen.dart
│   │   ├── cart_screen.dart
│   │   └── order_success_screen.dart
│   └── seller/
│       ├── seller_dashboard.dart
│       └── add_product_screen.dart
│
├── models/
│   ├── user_model.dart
│   ├── product_model.dart
│   ├── cart_item.dart
│   └── order_model.dart
│
├── providers/
│   ├── auth_provider.dart
│   ├── product_provider.dart
│   └── cart_provider.dart
│
├── services/
│   ├── cloudinary_service.dart
│   ├── product_service.dart
│   └── order_service.dart
│
├── widgets/
│   ├── custom_button.dart
│   ├── custom_textfield.dart
│   └── product_card.dart
│
└── core/
    ├── config/
    ├── constants/
    ├── services/
    └── validators/
```

---

## 🚀 Getting Started

### 📋 Prerequisites

* Flutter SDK installed
* Android Studio or Visual Studio Code
* Firebase account
* Git installed

Verify Flutter installation:

```bash
flutter doctor
```

---

## ⚙️ Setup Instructions
### Step 1: Clone the Repository

```bash
git clone https://github.com/ATHARVA279/S56-0226-APS-Flutter-ShilpSetu.git
cd S56-0226-APS-Flutter-ShilpSetu
```S56-0226-APS-Flutter-ShilpSetu
```

### Step 2: Install Dependencies

```bash
flutter pub get
```

### Step 3: Firebase Configuration

* Create a Firebase project
* Enable Firebase Authentication
* Enable Cloud Firestore
* Enable Firebase Storage
* Download `google-services.json`
* Place the file in:

```plaintext
android/app/
```
### Step 4: Environment Configuration

* Create a Cloudinary account at https://cloudinary.com
* Get your Cloud Name and create an Upload Preset (unsigned)
* Update credentials in `lib/core/config/env.dart`:

```dart
class Environment {
  static const String cloudinaryCloudName = 'YOUR_CLOUD_NAME';
  static const String cloudinaryUploadPreset = 'YOUR_UPLOAD_PRESET';
}
```tic const String uploadPreset = 'YOUR_UPLOAD_PRESET';
```

---

## ▶️ Running the Application

### 📱 Run on Android Emulator or Physical Device

```bash
flutter run
```

### 🌐 Run on Chrome (UI testing only)

```bash
flutter run -d chrome
```

### 📦 Build APK for Distribution

```bash
flutter build apk
```

The APK will be generated in:

```plaintext
build/app/outputs/flutter-apk/
```
## 🧪 Testing

The application has been thoroughly tested with:

* **Authentication Flow**: Login/signup with validation and role-based routing
* **Product Management**: CRUD operations for sellers with image uploads
* **Shopping Experience**: Cart management and order placement
* **Real-time Updates**: Firestore synchronization and offline persistence
* **Error Handling**: Graceful error handling with user feedback
* Widget tests for UI components
* Manual testing for authentication, product creation, cart flow, and order placement
* Firestore data validation and real-time updates

---

## 👥 Team Collaboration Guidelines

## 📊 Project Status

* ✅ **Complete MVP Implementation**: All core features functional
* ✅ **Firebase Integration**: Auth, Firestore, and Cloudinary working seamlessly  
* ✅ **Production Ready**: Clean codebase with proper architecture
* ✅ **Mobile Optimized**: Responsive UI with smooth user experience
* ✅ **Scalable Architecture**: Provider pattern with clean separation of concerns
## 📊 Success Metrics

* ✅ All MVP features implemented and functional.
* 🔥 Firebase Authentication, Firestore, and Storage integrated successfully.
* 📲 Stable APK build available for demonstration.
* ⭐ Positive feedback during project review or demo.
* 🎯 Clear differentiation from generic e-commerce platforms.

---

## 🔮 Future Enhancements

* 💳 Payment gateway integration (Razorpay or Stripe)
* 🌍 Multi-language and regional language support
* 🎤 Audio or video-based artisan storytelling
* 📍 Location-based discovery of local crafts

---

## 🙏 Acknowledgements

ShilpSetu is inspired by India's artisan communities