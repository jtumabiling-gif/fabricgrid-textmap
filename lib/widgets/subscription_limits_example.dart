import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../config/subscription_limits.dart';
import '../widgets/subscription_limit_display.dart';

/// Example implementation of realtime subscription limits
/// 
/// This shows how to integrate the new subscription limits system
/// into your shop owner screens or dashboards

class SubscriptionLimitsExample extends StatefulWidget {
  const SubscriptionLimitsExample({super.key});

  @override
  State<SubscriptionLimitsExample> createState() =>
      _SubscriptionLimitsExampleState();
}

class _SubscriptionLimitsExampleState extends State<SubscriptionLimitsExample> {
  late String shopOwnerId;

  @override
  void initState() {
    super.initState();
    shopOwnerId = FirebaseAuth.instance.currentUser?.uid ?? '';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
        title: const Text('Subscription & Limits'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Option 1: Streaming (Real-time updates)
            Text(
              'Real-Time Subscription Status',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            StreamingSubscriptionLimitDisplay(
              shopOwnerId: shopOwnerId,
              showDetailed: true,
            ),
            const SizedBox(height: 32),

            // Option 2: One-time check with FutureBuilder
            Text(
              'Current Status (One-time)',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SubscriptionLimitDisplay(
              shopOwnerId: shopOwnerId,
              showDetailed: true,
            ),
            const SizedBox(height: 32),

            // Option 3: Custom validation example
            Text(
              'Add Product Validation',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildAddProductSection(context),
            const SizedBox(height: 32),

            // Option 4: Manual info display
            Text(
              'Manual Limit Info',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildManualLimitDisplay(),
          ],
        ),
      ),
    );

  Widget _buildAddProductSection(BuildContext context) => FutureBuilder<SubscriptionLimitInfo>(
      future: SubscriptionLimits.getLimitInfo(shopOwnerId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final limitInfo = snapshot.data;
        if (limitInfo == null) {
          return const Text('Unable to load subscription info');
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status: ${limitInfo.statusMessage}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: limitInfo.isSlotsAvailable
                  ? () => _showAddProductDialog(context, limitInfo)
                  : () => _showUpgradeDialog(context, limitInfo),
              child: Text(
                limitInfo.isSlotsAvailable
                    ? 'Add New Product'
                    : 'Upgrade Plan',
              ),
            ),
            if (!limitInfo.isSlotsAvailable) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  border: Border.all(color: Colors.red),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'You\'ve reached your ${limitInfo.planName} plan limit. '
                  'Upgrade to ${SubscriptionLimits.tierStandard} or '
                  '${SubscriptionLimits.tierPremium} to add more items.',
                  style: TextStyle(color: Colors.red[700]),
                ),
              ),
            ],
          ],
        );
      },
    );

  Widget _buildManualLimitDisplay() => FutureBuilder<SubscriptionLimitInfo>(
      future: SubscriptionLimits.getLimitInfo(shopOwnerId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        final limitInfo = snapshot.data;
        if (limitInfo == null) {
          return const Text('No data');
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _infoRow('Plan Name:', limitInfo.planName),
              _infoRow('Tier:', limitInfo.tier),
              _infoRow('Items Used:', limitInfo.totalItemsUsed.toString()),
              _infoRow('Max Limit:', limitInfo.formattedMaxLimit),
              if (limitInfo.slotsRemaining != null)
                _infoRow(
                  'Slots Remaining:',
                  limitInfo.slotsRemaining.toString(),
                ),
              _infoRow('Usage:', '${limitInfo.progressPercentage}%'),
              _infoRow(
                'Can Add More:',
                limitInfo.isSlotsAvailable ? 'Yes' : 'No',
              ),
            ],
          ),
        );
      },
    );

  Widget _infoRow(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );

  void _showAddProductDialog(
    BuildContext context,
    SubscriptionLimitInfo limitInfo,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Product'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Slots remaining: ${limitInfo.slotsRemaining}'),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Product Name',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Add product logic here
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Product added!')),
              );
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showUpgradeDialog(
    BuildContext context,
    SubscriptionLimitInfo limitInfo,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upgrade Required'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your current ${limitInfo.planName} plan is full.'),
            const SizedBox(height: 12),
            const Text('Upgrade options:'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Standard Plan',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('15 items • ₱99/month'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.amber),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Premium Plan',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('Unlimited items • ₱199/month'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Navigate to upgrade page
              Navigator.pop(context);
            },
            child: const Text('View Plans'),
          ),
        ],
      ),
    );
  }
}
