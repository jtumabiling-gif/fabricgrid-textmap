import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../theme/app_theme.dart';

class ShopDetailScreen extends StatefulWidget {
  const ShopDetailScreen({super.key});

  @override
  State<ShopDetailScreen> createState() => _ShopDetailScreenState();
}

class _ShopDetailScreenState extends State<ShopDetailScreen> {
  bool _isFavorite = false;

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_outline),
            onPressed: () => setState(() => _isFavorite = !_isFavorite),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor.withOpacity(0.3),
                    AppTheme.secondaryColor.withOpacity(0.3),
                  ],
                ),
              ),
              child: const Icon(
                Icons.store,
                size: 100,
                color: AppTheme.primaryColor,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Premium Fabric Shop',
                              style: AppTheme.headingMedium,
                            ),
                            SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.star,
                                    color: AppTheme.warning, size: 16),
                                SizedBox(width: 4),
                                Text('4.8 (250 reviews)',
                                    style: AppTheme.bodySmall),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Text(
                        r'$50/hr',
                        style: AppTheme.headingSmall.copyWith(
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('About', style: AppTheme.headingSmall),
                  const SizedBox(height: 8),
                  const Text(
                    'A leading fabric service provider with 10+ years of experience. We offer premium fabric cleaning, repair, and tailoring services with attention to detail.',
                    style: AppTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  const Text('Services Offered', style: AppTheme.headingSmall),
                  const SizedBox(height: 8),
                  const Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(label: Text('Cleaning')),
                      Chip(label: Text('Repair')),
                      Chip(label: Text('Tailoring')),
                      Chip(label: Text('Dyeing')),
                      Chip(label: Text('Pressing')),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Hours', style: AppTheme.headingSmall),
                  const SizedBox(height: 8),
                  const Text('Mon - Fri: 9:00 AM - 6:00 PM',
                      style: AppTheme.bodyMedium),
                  const Text('Sat: 10:00 AM - 4:00 PM',
                      style: AppTheme.bodyMedium),
                  const Text('Sun: Closed', style: AppTheme.bodyMedium),
                  const SizedBox(height: 16),
                  const Text('Location', style: AppTheme.headingSmall),
                  const SizedBox(height: 8),
                  const Text('123 Fabric Street, City',
                      style: AppTheme.bodyMedium),
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
