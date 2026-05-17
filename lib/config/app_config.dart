/// App configuration and constants
library;

class AppConfig {
  // API Configuration
  static const String baseUrl = 'https://api.fabricgrid.com';
  static const String apiVersion = 'v1';

  // App Information
  static const String appName = 'FabricGrid';
  static const String appVersion = '1.0.0';
  static const String buildNumber = '1';

  // Firebase Configuration (Update with your Firebase details)
  static const String firebaseProjectId = 'fabricgrid-project';
  static const String firebaseApiKey = 'YOUR_API_KEY';
  static const String firebaseMessagingSenderId = 'YOUR_SENDER_ID';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Cache Configuration
  static const int imageCacheSizeInMB = 100;
  static const Duration cacheExpireTime = Duration(days: 7);

  // Pagination
  static const int pageSize = 20;

  // UI Configuration
  static const double defaultPadding = 16;
  static const double defaultBorderRadius = 12;
}

class ScreenRoutes {
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String home = '/home';
  static const String discover = '/discover';
  static const String shopDetail = '/shop-detail';
  static const String booking = '/booking';
  static const String bookingConfirmation = '/booking-confirmation';
  static const String marketplace = '/marketplace';
  static const String productDetail = '/product-detail';
  static const String listItem = '/list-item';
  static const String profile = '/profile';
  static const String liveMap = '/live-map';
  static const String recycleDropoff = '/recycle-dropoff';
  static const String mapPinDetail = '/map-pin-detail';

  // Additional utility routes
  static const String notifications = '/notifications';
  static const String settings = '/settings';
  static const String forgotPassword = '/forgot-password';
  static const String terms = '/terms';
  static const String support = '/support';
  static const String about = '/about';
  static const String orders = '/orders';
  static const String wishlist = '/wishlist';
  static const String addresses = '/addresses';
  static const String paymentMethods = '/payment-methods';
  static const String checkout = '/checkout';
}

class ValidationRules {
  // Email validation
  static const String emailPattern =
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';

  // Password requirements
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 128;

  // Phone validation
  static const String phonePattern = r'^[+]?[(]?[0-9]{3}[)]?[-\s.]?[0-9]{3}[-\s.]?[0-9]{4,6}$';

  // Price validation
  static const double minPrice = 0;
  static const double maxPrice = 999999.99;

  // Text lengths
  static const int minNameLength = 2;
  static const int maxNameLength = 50;
  static const int minTitleLength = 3;
  static const int maxTitleLength = 100;
  static const int minDescriptionLength = 10;
  static const int maxDescriptionLength = 1000;
}

class ApiEndpoints {
  // Auth endpoints
  static const String login = '/auth/login';
  static const String signup = '/auth/signup';
  static const String logout = '/auth/logout';
  static const String refresh = '/auth/refresh';

  // Services endpoints
  static const String services = '/services';
  static const String serviceDetail = '/services/:id';
  static const String nearbyServices = '/services/nearby';

  // Products endpoints
  static const String products = '/products';
  static const String productDetail = '/products/:id';
  static const String searchProducts = '/products/search';

  // Bookings endpoints
  static const String bookings = '/bookings';
  static const String createBooking = '/bookings/create';
  static const String bookingDetail = '/bookings/:id';

  // User endpoints
  static const String profile = '/users/profile';
  static const String updateProfile = '/users/profile/update';
  static const String favorites = '/users/favorites';
}

class ErrorMessages {
  static const String networkError = 'Network connection error';
  static const String timeoutError = 'Request timeout';
  static const String serverError = 'Server error occurred';
  static const String unauthorizedError = 'Unauthorized access';
  static const String notFoundError = 'Resource not found';
  static const String invalidInputError = 'Invalid input provided';
  static const String unexpectedError = 'An unexpected error occurred';
  
  // Role-based authentication errors
  static const String invalidRoleEmail = 'The email address is invalid';
  static const String roleNotFound = 'User role not found';
  static const String roleSelectionRequired = 'Please select a role first';
}

class SuccessMessages {
  static const String loginSuccess = 'Login successful';
  static const String signupSuccess = 'Account created successfully';
  static const String bookingSuccess = 'Booking confirmed';
  static const String profileUpdated = 'Profile updated successfully';
  static const String itemListed = 'Item listed successfully';
}
