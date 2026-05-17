import 'package:flutter/material.dart';

class ShopOwnerMapScreen extends StatefulWidget {
  const ShopOwnerMapScreen({super.key});

  @override
  State<ShopOwnerMapScreen> createState() => _ShopOwnerMapScreenState();
}

class _ShopOwnerMapScreenState extends State<ShopOwnerMapScreen> {
  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: const Color(0xFF0F1F2F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1F2F),
        elevation: 0,
        title: const Text(
          'MarketplaceLoom',
          style: TextStyle(
            color: Color(0xFF1EDDAC),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton(
              icon: const Icon(Icons.notifications, color: Colors.white),
              onPressed: () {},
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            color: Colors.grey[600],
            child: const Center(
              child: Icon(Icons.map, size: 100, color: Colors.white54),
            ),
          ),
          Positioned(
            bottom: 120,
            left: 0,
            right: 0,
            child: Center(
              child: Column(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1EDDAC),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Text(
                      'Your Shop Location',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF1EDDAC),
                    ),
                    child: const Icon(Icons.location_on,
                        color: Colors.black87, size: 32),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
}
