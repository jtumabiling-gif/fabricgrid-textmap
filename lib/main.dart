import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'admin_screens/admin_main_screen.dart';
import 'controllers/role_controller.dart';
import 'services/auth_service.dart';
import 'shop_owner_screens/shop_owner_details_screen.dart';
import 'shop_owner_screens/shop_owner_main_screen.dart';
import 'shop_owner_screens/shop_owner_subscription_screen.dart';
import 'theme/app_theme.dart';
import 'user_screens/book_service_screen.dart';
import 'user_screens/booking_screen.dart';
import 'user_screens/discover_service_detail_screen.dart';
import 'user_screens/landing_page_screen.dart';
import 'user_screens/list_item_screen.dart';
import 'user_screens/login_screen.dart';
import 'user_screens/map_pin_detail_screen.dart';
import 'user_screens/my_bookings_screen.dart';
import 'user_screens/notifications_screen.dart';
import 'user_screens/onboarding_screen.dart';
import 'user_screens/product_detail_screen.dart';
import 'user_screens/product_search_by_owner_screen.dart';
import 'user_screens/review_submission_screen.dart';
import 'user_screens/role_selection_screen.dart';
import 'user_screens/settings_screen_full.dart';
import 'user_screens/shop_detail_screen.dart';
import 'user_screens/signup_screen.dart';
import 'user_screens/splash_screen.dart';
import 'user_screens/user_balance_screen.dart';
import 'user_screens/user_details_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService().initialize();
  // Initialize RoleController
  Get.put(RoleController());
  runApp(const FabricGridApp());
}

class FabricGridApp extends StatelessWidget {
  const FabricGridApp({super.key});

  @override
  Widget build(BuildContext context) => GetMaterialApp(
      debugShowCheckedModeBanner: false, // <--- Add this line here
      title: 'FabricGrid',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      defaultTransition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
      initialRoute: '/splash',
      getPages: _getPages(),
      home: const SplashScreen(),
      builder: (context, child) => Scaffold(
          body: child,
        ),
    );

  static List<GetPage<dynamic>> _getPages() => [
      GetPage(
        name: '/splash',
        page: () => const SplashScreen(),
        transition: Transition.fade,
      ),
      GetPage(
        name: '/role-selection',
        page: () => const RoleSelectionScreen(),
        transition: Transition.fade,
      ),
      GetPage(
        name: '/onboarding',
        page: () => const OnboardingScreen(),
        transition: Transition.fade,
      ),
      GetPage(
        name: '/login',
        page: () => const LoginScreen(),
      ),
      GetPage(
        name: '/signup',
        page: () => const SignupScreen(),
      ),
      GetPage(
        name: '/shop-owner-main',
        page: () => const ShopOwnerMainScreen(),
        transition: Transition.fade,
      ),
      GetPage(
        name: '/admin-main',
        page: () => const AdminMainScreen(),
        transition: Transition.fade,
      ),
      GetPage(
        name: '/discover',
        page: () => const LandingPageScreen(),
      ),
      GetPage(
        name: '/shop-detail',
        page: () => const ShopDetailScreen(),
      ),
      GetPage(
        name: '/booking',
        page: () => const BookingScreen(),
      ),
      GetPage(
        name: '/book-service',
        page: () => const BookServiceScreen(),
      ),
      GetPage(
        name: '/marketplace',
        page: () => const LandingPageScreen(),
      ),
      GetPage(
        name: '/product-detail',
        page: () => const ProductDetailScreen(),
      ),
      GetPage(
        name: '/list-item',
        page: () => const ListItemScreen(),
      ),
      GetPage(
        name: '/profile',
        page: () => const LandingPageScreen(),
      ),
      GetPage(
        name: '/live-map',
        page: () => const LandingPageScreen(),
      ),
      GetPage(
        name: '/map-pin-detail',
        page: () => const MapPinDetailScreen(),
      ),
      GetPage(
        name: '/my-bookings',
        page: () => const MyBookingsScreen(),
      ),
      GetPage(
        name: '/notifications',
        page: () => const NotificationsScreen(),
      ),
      GetPage(
        name: '/shop-owner-subscription',
        page: () => const ShopOwnerSubscriptionScreen(),
      ),
      GetPage(
        name: '/review-submission',
        page: () {
          // This route requires a booking to be passed via navigation arguments
          // Use: Get.toNamed('/review-submission', arguments: booking)
          final booking = Get.arguments;
          if (booking == null) {
            return const Scaffold(
              body: Center(
                child: Text('Error: Booking data not found'),
              ),
            );
          }
          return ReviewSubmissionScreen(booking: booking);
        },
      ),
      GetPage(
        name: '/discover-service-detail',
        page: () => const DiscoverServiceDetailScreen(),
      ),
      GetPage(
        name: '/settings-full',
        page: () => const SettingsScreenFull(),
      ),
      GetPage(
        name: '/user-balance',
        page: () => const UserBalanceScreen(),
      ),
      GetPage(
        name: '/user-details',
        page: () => const UserDetailsScreen(),
      ),
      GetPage(
        name: '/shop-owner-details',
        page: () => const ShopOwnerDetailsScreen(),
      ),
      GetPage(
        name: '/product-search-by-owner',
        page: () => const ProductSearchByShopOwnerScreen(),
      ),
    ];
}
