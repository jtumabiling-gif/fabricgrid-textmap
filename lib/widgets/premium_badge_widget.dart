import 'package:flutter/material.dart';

class PremiumBadgeWidget extends StatelessWidget {

  const PremiumBadgeWidget({
    super.key,
    this.isPremium,
    this.sellerTier,
    this.showDetails = false,
  });
  // Support both old boolean param and new string tier param
  final bool? isPremium;
  final String? sellerTier; // 'Premium', 'Standard', or null
  final bool showDetails;

  String get _tierDisplay {
    if (sellerTier != null) {
      return sellerTier!;
    }
    // Fallback to old boolean logic for backward compatibility
    if (isPremium == true) {
      return 'Premium';
    }
    return '';
  }

  bool get _shouldDisplay {
    if (sellerTier != null) {
      return sellerTier!.isNotEmpty;
    }
    return isPremium == true;
  }

  Color get _tierColor {
    switch (sellerTier) {
      case 'Premium':
        return const Color(0xFFFFD700); // Gold
      case 'Standard':
        return const Color(0xFF4A90E2); // Blue
      default:
        return const Color(0xFFFFD700); // Default to gold for backward compatibility
    }
  }

  Color get _tierGradientEnd {
    switch (sellerTier) {
      case 'Premium':
        return const Color(0xFFFFA500); // Orange
      case 'Standard':
        return const Color(0xFF2E5CC8); // Darker blue
      default:
        return const Color(0xFFFFA500);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_shouldDisplay) return const SizedBox.shrink();

    if (showDetails) {
      return _buildDetailedView();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_tierColor, _tierGradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: _tierColor.withOpacity(0.3),
            blurRadius: 4,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            sellerTier == 'Premium' ? Icons.verified : Icons.check_circle,
            size: 14,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            '$_tierDisplay Seller',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedView() => Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2B3F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _tierColor,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_tierColor, _tierGradientEnd],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      sellerTier == 'Premium' ? Icons.verified : Icons.check_circle,
                      size: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$_tierDisplay Seller',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '$_tierDisplay Seller Benefits',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          if (sellerTier == 'Premium') ...[
            _buildBenefitItem(
              icon: Icons.trending_up,
              title: 'High Search Positioning',
              subtitle: 'Top of list in search results',
            ),
            const SizedBox(height: 8),
            _buildBenefitItem(
              icon: Icons.border_color,
              title: 'Highlighted Border',
              subtitle: 'Stand out on marketplace',
            ),
            const SizedBox(height: 8),
            _buildBenefitItem(
              icon: Icons.star,
              title: 'Unlimited Featured Slots',
              subtitle: 'Feature all your products',
            ),
            const SizedBox(height: 8),
            _buildBenefitItem(
              icon: Icons.verified_user,
              title: 'Premium Seller Badge',
              subtitle: 'Build customer trust',
            ),
            const SizedBox(height: 8),
            _buildBenefitItem(
              icon: Icons.support_agent,
              title: 'Priority 24/7 Support',
              subtitle: 'Dedicated support team',
            ),
          ] else if (sellerTier == 'Standard') ...[
            _buildBenefitItem(
              icon: Icons.trending_up,
              title: 'Basic Search Positioning',
              subtitle: 'Listed in search results',
            ),
            const SizedBox(height: 8),
            _buildBenefitItem(
              icon: Icons.photo,
              title: 'Standard Photo Display',
              subtitle: 'Standard product display',
            ),
            const SizedBox(height: 8),
            _buildBenefitItem(
              icon: Icons.featured_play_list,
              title: 'Limited Featured Slots',
              subtitle: 'Feature some of your products',
            ),
            const SizedBox(height: 8),
            _buildBenefitItem(
              icon: Icons.verified_user,
              title: 'Standard Seller Badge',
              subtitle: 'Verified seller status',
            ),
            const SizedBox(height: 8),
            _buildBenefitItem(
              icon: Icons.email,
              title: 'Email Support',
              subtitle: 'Standard email support',
            ),
          ],
        ],
      ),
    );

  Widget _buildBenefitItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF1EDDAC)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ),
      ],
    );
}

class PremiumBorderWidget extends StatelessWidget {

  const PremiumBorderWidget({
    required this.isPremium, required this.child, super.key,
    this.borderWidth = 2.0,
  });
  final bool isPremium;
  final Widget child;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    if (!isPremium) return child;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: const Color(0xFF1EDDAC),
          width: borderWidth,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}
