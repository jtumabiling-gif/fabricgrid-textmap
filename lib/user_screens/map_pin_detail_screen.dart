import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../theme/app_theme.dart';

class MapPinDetailScreen extends StatefulWidget {
  const MapPinDetailScreen({super.key});

  @override
  State<MapPinDetailScreen> createState() => _MapPinDetailScreenState();
}

class _MapPinDetailScreenState extends State<MapPinDetailScreen> {
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 250,
              width: double.infinity,
              color: Colors.grey[200],
              child: const Icon(Icons.map, size: 100, color: Colors.grey),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Premium Fabric Services', style: AppTheme.headingMedium),
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      Icon(Icons.location_on, color: AppTheme.primaryColor, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text('123 Main Street, City, State 12345', style: AppTheme.bodyMedium),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      Icon(Icons.phone, color: AppTheme.primaryColor, size: 18),
                      SizedBox(width: 8),
                      Text('+1 (555) 123-4567', style: AppTheme.bodyMedium),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.star, color: AppTheme.warning, size: 18),
                      const SizedBox(width: 8),
                      const Text('4.8 (250 reviews)', style: AppTheme.bodyMedium),
                      const Spacer(),
                      TextButton(
                        onPressed: () => Get.toNamed('/shop-detail'),
                        child: const Text('View More'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Hours of Operation', style: AppTheme.headingSmall),
                  const SizedBox(height: 8),
                  const Text('Mon - Fri: 9:00 AM - 6:00 PM', style: AppTheme.bodyMedium),
                  const Text('Sat: 10:00 AM - 4:00 PM', style: AppTheme.bodyMedium),
                  const Text('Sun: Closed', style: AppTheme.bodyMedium),
                  const SizedBox(height: 24),
                  const Text('Services Offered', style: AppTheme.headingSmall),
                  const SizedBox(height: 8),
                  const Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(label: Text('Cleaning')),
                      Chip(label: Text('Repair')),
                      Chip(label: Text('Tailoring')),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: () => Get.toNamed('/booking'),
          child: const Text('Book Service'),
        ),
      ),
    );
}
