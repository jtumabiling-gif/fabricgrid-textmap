import 'package:flutter/material.dart';

/// Widget to display subscription tier badge with icon
class SubscriptionBadge extends StatelessWidget {

  const SubscriptionBadge({
    super.key,
    required this.subscriptionTier,
    this.compact = false,
  });
  final String? subscriptionTier;
  final bool compact;

  /// Check if subscription is active (not None/null)
  bool _isSubscriptionActive() {
    final tier = subscriptionTier?.toLowerCase();
    return tier != null && tier.isNotEmpty && tier != 'none' && tier != 'ordinary';
  }

  Color _getBadgeColor() {
    switch (subscriptionTier?.toLowerCase()) {
      case 'premium':
        return const Color(0xFFFFD700); // Gold
      case 'standard':
        return const Color(0xFF1EDDAC); // Teal/Green
      default:
        return Colors.white30; // Gray for None/Ordinary
    }
  }

  IconData _getBadgeIcon() {
    switch (subscriptionTier?.toLowerCase()) {
      case 'premium':
        return Icons.star; // Star for Premium
      case 'standard':
        return Icons.check_circle; // Check circle for Standard
      default:
        return Icons.radio_button_unchecked; // Empty circle for None
    }
  }

  String _getBadgeLabel() {
    switch (subscriptionTier?.toLowerCase()) {
      case 'premium':
        return 'Premium';
      case 'standard':
        return 'Standard';
      default:
        return 'None';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show nothing if no active subscription
    if (!_isSubscriptionActive()) {
      return const SizedBox.shrink();
    }

    if (compact) {
      // Compact version - just icon, no box
      return Icon(
        _getBadgeIcon(),
        color: _getBadgeColor(),
        size: 24,
      );
    }

    // Full version with label
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getBadgeColor().withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getBadgeColor().withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getBadgeIcon(),
            color: _getBadgeColor(),
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            _getBadgeLabel(),
            style: TextStyle(
              color: _getBadgeColor(),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
