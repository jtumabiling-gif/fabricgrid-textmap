# FabricGrid - Flutter Mobile App

A comprehensive Flutter mobile application for FabricGrid, a marketplace platform for fabric services and products. This app provides users with a seamless experience to discover, book, and manage fabric-related services and products.

## Project Overview

FabricGrid is a full-featured mobile marketplace app with 16 distinct screens covering authentication, service discovery, booking management, product marketplace, and user profiles.

## Features

### Authentication
- **Login Screen**: User authentication with email and password
- **Sign Up Screen**: New user registration with terms acceptance

### Marketplace & Discovery
- **Home Dashboard**: Featured services and recent activity
- **Discover Services**: Browse and filter services by category
- **Shop Detail**: Detailed view of service providers with ratings and hours
- **Marketplace**: Browse and purchase fabric products
- **Product Detail**: Individual product information with quantity selection

### Booking & Scheduling
- **Book/Schedule**: Date and time selection for services
- **Booking Confirmation**: Order confirmation with booking details
- **Live Map**: Nearby service providers on a map
- **Map Pin Detail**: Detailed location and provider information

### User Features
- **List an Item**: Sell fabric products on the marketplace
- **Recycle Drop-off**: Find nearby fabric recycling centers
- **Profile**: User account management and settings
- **Splash/Onboarding**: App introduction and onboarding flow

## Project Structure

```
lib/
├── main.dart                          # App entry point with navigation routing
├── theme/
│   └── app_theme.dart                # Centralized theme and styling
├── screens/                           # All screen implementations
│   ├── splash_screen.dart
│   ├── onboarding_screen.dart
│   ├── login_screen.dart
│   ├── signup_screen.dart
│   ├── home_screen.dart
│   ├── discover_services_screen.dart
│   ├── shop_detail_screen.dart
│   ├── booking_screen.dart
│   ├── booking_confirmation_screen.dart
│   ├── marketplace_screen.dart
│   ├── product_detail_screen.dart
│   ├── list_item_screen.dart
│   ├── profile_screen.dart
│   ├── live_map_screen.dart
│   ├── recycle_dropoff_screen.dart
│   └── map_pin_detail_screen.dart
├── widgets/                           # Reusable UI components (ready for expansion)
├── models/                            # Data models (ready for expansion)
└── assets/
    ├── images/                        # Image assets
    └── icons/                         # Icon assets
```

## Theme & Styling

The app uses a cohesive design system with:
- **Primary Color**: `#6B5B95` (Purple)
- **Secondary Color**: `#F4A460` (Orange)
- **Accent Color**: `#88C540` (Green)
- **Typography**: Poppins (headings) and Roboto (body)
- **Dark/Light Mode Support**: Full theme implementation

## Screens Description

### 1. Splash Screen (`splash_screen.dart`)
- Animated splash screen with app branding
- Transitions to onboarding after 3 seconds

### 2. Onboarding Screen (`onboarding_screen.dart`)
- 4-page onboarding flow with page indicators
- Skip and Next navigation options

### 3. Login Screen (`login_screen.dart`)
- Email and password authentication
- Social login options (Google, Facebook)
- Forgot password and sign-up links

### 4. Sign Up Screen (`signup_screen.dart`)
- New user registration form
- Full name, email, password fields
- Terms and privacy policy agreement

### 5. Home Dashboard (`home_screen.dart`)
- Featured services carousel
- Recent services list
- Bottom navigation with 5 tabs
- Search functionality

### 6. Discover Services (`discover_services_screen.dart`)
- Service category filtering
- Grid view of available services
- Rating and pricing display

### 7. Shop Detail (`shop_detail_screen.dart`)
- Provider profile and information
- Hours of operation
- Services offered
- Book service CTA

### 8. Booking Screen (`booking_screen.dart`)
- Date and time selection
- Booking notes input
- Confirmation action

### 9. Booking Confirmation (`booking_confirmation_screen.dart`)
- Order confirmation summary
- Booking ID and details
- Total pricing

### 10. Marketplace (`marketplace_screen.dart`)
- Product listing grid
- Search and filter options
- Sort by popular, price, newest

### 11. Product Detail (`product_detail_screen.dart`)
- Product images and description
- Specifications
- Quantity selector
- Add to cart/wishlist

### 12. List an Item (`list_item_screen.dart`)
- Photo upload for products
- Product details form
- Category and price selection

### 13. Profile (`profile_screen.dart`)
- User account information
- Quick links (Orders, Wishlist, Addresses)
- Settings and logout

### 14. Live Map (`live_map_screen.dart`)
- Map view with service providers
- Nearby services list
- Distance information

### 15. Recycle Drop-off (`recycle_dropoff_screen.dart`)
- Recycling center locations
- Accepted materials
- Distance and hours

### 16. Map Pin Detail (`map_pin_detail_screen.dart`)
- Location details
- Provider information
- Hours and services

## Dependencies

Key packages used:
- **get**: State management and navigation
- **flutter_riverpod**: Reactive state management
- **http/dio**: API communication
- **firebase_auth**: Authentication
- **cloud_firestore**: Backend database
- **google_maps_flutter**: Map integration
- **cached_network_image**: Image caching
- **intl**: Internationalization

Full dependency list in `pubspec.yaml`

## Getting Started

### Prerequisites
- Flutter SDK 3.0+
- Dart 3.0+
- Android Studio or Xcode (for Android/iOS development)

### Installation

1. **Clone or navigate to project**:
   ```bash
   cd textmap
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run the app**:
   ```bash
   flutter run
   ```

4. **Build release**:
   ```bash
   # Android
   flutter build apk

   # iOS
   flutter build ios
   ```

## Navigation Routes

The app uses GetX routing with the following named routes:

- `/splash` - Splash screen
- `/onboarding` - Onboarding flow
- `/login` - Login screen
- `/signup` - Sign up screen
- `/home` - Home dashboard
- `/discover` - Discover services
- `/shop-detail` - Shop/service details
- `/booking` - Book service
- `/booking-confirmation` - Booking confirmation
- `/marketplace` - Product marketplace
- `/product-detail` - Product details
- `/list-item` - List a new item
- `/profile` - User profile
- `/live-map` - Map view
- `/recycle-dropoff` - Recycling centers
- `/map-pin-detail` - Map location details

## Theme Customization

Modify colors and styles in `lib/theme/app_theme.dart`:

```dart
static const Color primaryColor = Color(0xFF6B5B95);
static const Color secondaryColor = Color(0xFFF4A460);
// ... other theme properties
```

## Next Steps - Implementation Guide

1. **Set up Firebase**:
   - Create Firebase project
   - Configure authentication
   - Set up Firestore database

2. **API Integration**:
   - Implement backend services in `lib/models/`
   - Add API calls using Dio/HTTP

3. **State Management**:
   - Implement Riverpod providers for data
   - Add business logic controllers

4. **Database Models**:
   - Create data models in `lib/models/`
   - Implement serialization/deserialization

5. **Add Reusable Components**:
   - Build custom widgets in `lib/widgets/`
   - Create shared UI components

6. **Testing**:
   - Add unit tests
   - Add integration tests
   - Widget testing

## Architecture Notes

- **Clean Architecture**: Screens are stateful widgets with local state management
- **Navigation**: GetX for routing and navigation
- **Theme**: Centralized theme system for consistency
- **Modularity**: Each screen is in its own file for maintainability

## Contributing

To extend the app:

1. Create new screens in `lib/screens/`
2. Add models in `lib/models/`
3. Create reusable widgets in `lib/widgets/`
4. Update routes in `main.dart`
5. Maintain theme consistency

## Responsive Design

The app uses:
- Flexible widgets for responsive layouts
- MediaQuery for device-specific sizing
- Flutter's built-in responsive sizing

## Performance Considerations

- Lazy loading with ListView.builder and GridView.builder
- Cached network images
- Efficient state management
- Optimized widget rebuilds

## License

Proprietary - FabricGrid

## Support

For issues or questions, refer to Flutter documentation:
- [Flutter Docs](https://flutter.dev/docs)
- [GetX Documentation](https://github.com/jonataslaw/getx)

---

**Version**: 1.0.0  
**Last Updated**: April 22, 2026
