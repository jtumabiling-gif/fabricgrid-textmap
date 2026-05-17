import 'package:flutter/material.dart';
import '../config/subscription_limits.dart';

/// Widget to display subscription limits and usage info
class SubscriptionLimitDisplay extends StatelessWidget {

  const SubscriptionLimitDisplay({
    required this.shopOwnerId, super.key,
    this.showDetailed = true,
  });
  final String shopOwnerId;
  final bool showDetailed;

  @override
  Widget build(BuildContext context) => FutureBuilder<SubscriptionLimitInfo>(
      future: SubscriptionLimits.getLimitInfo(shopOwnerId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading subscription info: ${snapshot.error}'),
          );
        }

        final limitInfo = snapshot.data;
        if (limitInfo == null) {
          return const Center(
            child: Text('No subscription information available'),
          );
        }

        return _buildLimitDisplay(context, limitInfo);
      },
    );

  Widget _buildLimitDisplay(BuildContext context, SubscriptionLimitInfo info) => Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Subscription: ${info.planName}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getTierColor(info.tier),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    info.tier,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Items Used',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  info.statusMessage,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (info.maxLimit != -1)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: info.totalItemsUsed / info.maxLimit,
                  minHeight: 8,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    info.isSlotsAvailable ? Colors.green : Colors.red,
                  ),
                ),
              )
            else
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            const SizedBox(height: 8),
            Text(
              info.remainingMessage,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: info.isSlotsAvailable ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            if (showDetailed) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow(context, 'Plan', info.planName),
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      context,
                      'Current Items',
                      info.totalItemsUsed.toString(),
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      context,
                      'Maximum Limit',
                      info.formattedMaxLimit,
                    ),
                    if (info.slotsRemaining != null) ...[
                      const SizedBox(height: 8),
                      _buildDetailRow(
                        context,
                        'Slots Remaining',
                        info.slotsRemaining.toString(),
                      ),
                    ],
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      context,
                      'Usage',
                      '${info.progressPercentage}%',
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: info.isSlotsAvailable
                    ? Colors.green[50]
                    : Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: info.isSlotsAvailable ? Colors.green : Colors.red,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    info.isSlotsAvailable
                        ? Icons.check_circle
                        : Icons.error,
                    color: info.isSlotsAvailable ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      info.isSlotsAvailable
                          ? 'You can add more items'
                          : 'Upgrade your plan to add more items',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: info.isSlotsAvailable
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

  Widget _buildDetailRow(BuildContext context, String label, String value) => Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );

  Color _getTierColor(String tier) {
    switch (tier) {
      case SubscriptionLimits.tierPremium:
        return Colors.amber;
      case SubscriptionLimits.tierStandard:
        return Colors.blue;
      case SubscriptionLimits.tierOrdinary:
      default:
        return Colors.grey;
    }
  }
}

/// Streamable version for realtime updates
class StreamingSubscriptionLimitDisplay extends StatelessWidget {

  const StreamingSubscriptionLimitDisplay({
    required this.shopOwnerId, super.key,
    this.showDetailed = true,
  });
  final String shopOwnerId;
  final bool showDetailed;

  @override
  Widget build(BuildContext context) => StreamBuilder<SubscriptionLimitInfo>(
      stream: SubscriptionLimits.streamLimitInfo(shopOwnerId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading subscription info: ${snapshot.error}'),
          );
        }

        final limitInfo = snapshot.data;
        if (limitInfo == null) {
          return const Center(
            child: Text('No subscription information available'),
          );
        }

        return _buildLimitDisplay(context, limitInfo);
      },
    );

  Widget _buildLimitDisplay(BuildContext context, SubscriptionLimitInfo info) => Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Subscription: ${info.planName}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getTierColor(info.tier),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    info.tier,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Items Used',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  info.statusMessage,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (info.maxLimit != -1)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: info.totalItemsUsed / info.maxLimit,
                  minHeight: 8,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    info.isSlotsAvailable ? Colors.green : Colors.red,
                  ),
                ),
              )
            else
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            const SizedBox(height: 8),
            Text(
              info.remainingMessage,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: info.isSlotsAvailable ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            if (showDetailed) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow(context, 'Plan', info.planName),
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      context,
                      'Current Items',
                      info.totalItemsUsed.toString(),
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      context,
                      'Maximum Limit',
                      info.formattedMaxLimit,
                    ),
                    if (info.slotsRemaining != null) ...[
                      const SizedBox(height: 8),
                      _buildDetailRow(
                        context,
                        'Slots Remaining',
                        info.slotsRemaining.toString(),
                      ),
                    ],
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      context,
                      'Usage',
                      '${info.progressPercentage}%',
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: info.isSlotsAvailable
                    ? Colors.green[50]
                    : Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: info.isSlotsAvailable ? Colors.green : Colors.red,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    info.isSlotsAvailable
                        ? Icons.check_circle
                        : Icons.error,
                    color: info.isSlotsAvailable ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      info.isSlotsAvailable
                          ? 'You can add more items'
                          : 'Upgrade your plan to add more items',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: info.isSlotsAvailable
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

  Widget _buildDetailRow(BuildContext context, String label, String value) => Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );

  Color _getTierColor(String tier) {
    switch (tier) {
      case SubscriptionLimits.tierPremium:
        return Colors.amber;
      case SubscriptionLimits.tierStandard:
        return Colors.blue;
      case SubscriptionLimits.tierOrdinary:
      default:
        return Colors.grey;
    }
  }
}
