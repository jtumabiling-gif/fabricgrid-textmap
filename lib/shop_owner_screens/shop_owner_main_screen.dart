import 'package:flutter/material.dart';

import 'shop_owner_bookings_screen.dart';
import 'shop_owner_insights_screen.dart';
import 'shop_owner_notifications_screen.dart';
import 'shop_owner_products_screen.dart';
import 'shop_owner_settings_screen.dart';
import 'shop_owner_users_screen.dart';

class ShopOwnerMainScreen extends StatefulWidget {
  const ShopOwnerMainScreen({super.key});

  @override
  State<ShopOwnerMainScreen> createState() => _ShopOwnerMainScreenState();
}

class _ShopOwnerMainScreenState extends State<ShopOwnerMainScreen> {
  int _selectedIndex = 0;

  // List of screens
  late final List<Widget> _screens = [
    const ShopOwnerInsightsScreen(),
    const ShopOwnerProductsScreen(),
    const ShopOwnerBookingsScreen(),
    const ShopOwnerUsersScreen(),
    const ShopOwnerSettingsScreen(),
  ];

  // Navigation items with icons and labels
  final List<BottomNavigationBarItem> _navigationItems = [
    const BottomNavigationBarItem(
      icon: Icon(Icons.insights),
      label: 'Insights',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.shopping_bag),
      label: 'Products',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.receipt),
      label: 'Bookings',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.people),
      label: 'Users',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.settings),
      label: 'Settings',
    ),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1F2F),
        elevation: 0,
        title: const Text(
          'Shop Owner Dashboard',
          style: TextStyle(
            color: Color(0xFF1EDDAC),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton(
              icon: const Icon(Icons.notifications, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ShopOwnerNotificationsScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF1A2B3F),
        elevation: 8,
        selectedItemColor: const Color(0xFF1EDDAC),
        unselectedItemColor: Colors.white54,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        currentIndex: _selectedIndex,
        selectedIconTheme: const IconThemeData(size: 24),
        unselectedIconTheme: const IconThemeData(size: 22),
        selectedLabelStyle: const TextStyle(fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        items: _navigationItems,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
}
