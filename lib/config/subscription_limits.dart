import 'package:cloud_firestore/cloud_firestore.dart';

/// Subscription tier constants and limits for product listings
class SubscriptionLimits {
  // Subscription tier names
  static const String tierOrdinary = 'Ordinary';
  static const String tierStandard = 'Standard';
  static const String tierPremium = 'Premium';

  // Product listing limits per tier
  static const int ordinaryLimit = 5;
  static const int standardLimit = 15;
  static const int premiumLimit = -1; // -1 represents unlimited

  // Subscription prices
  static const String ordinaryPrice = '₱0';
  static const String standardPrice = '₱99';
  static const String premiumPrice = '₱199';

  // Commission fee rates (percentage of booking total for platform fee)
  static const double ordinaryCommissionRate = 0; // 0% for ordinary (no subscription)
  static const double standardCommissionRate = 0.05; // 5% for standard subscribers
  static const double premiumCommissionRate = 0.03; // 3% for premium subscribers

  /// Get the product limit for a subscription tier
  /// Returns -1 for unlimited (Premium tier)
  static int getLimitForTier(String? tierName) {
    switch (tierName) {
      case tierPremium:
        return premiumLimit; // Unlimited
      case tierStandard:
        return standardLimit; // 15 items
      case tierOrdinary:
      default:
        return ordinaryLimit; // 5 items
    }
  }

  /// Get the commission rate for a subscription tier
  /// Returns the percentage rate as decimal (e.g., 0.05 for 5%)
  static double getCommissionRateForTier(String? tierName) {
    switch (tierName) {
      case tierPremium:
        return premiumCommissionRate; // 3% for premium
      case tierStandard:
        return standardCommissionRate; // 5% for standard
      case tierOrdinary:
      default:
        return ordinaryCommissionRate; // 0% for ordinary (no commission)
    }
  }

  /// Calculate commission fee for a booking
  /// Returns the commission fee amount based on the tier
  static double calculateCommissionFee(String? tierName, double bookingAmount) {
    final rate = getCommissionRateForTier(tierName);
    return bookingAmount * rate;
  }

  /// Get the tier name for a plan name (from subscription document)
  static String getTierFromPlanName(String? planName) {
    if (planName == null) return tierOrdinary;
    
    final lowerPlan = planName.toLowerCase();
    if (lowerPlan.contains('premium')) {
      return tierPremium;
    } else if (lowerPlan.contains('standard')) {
      return tierStandard;
    } else {
      return tierOrdinary;
    }
  }

  /// Check if a tier has unlimited listings
  static bool isUnlimited(String? tierName) => getLimitForTier(tierName) == -1;

  /// Get formatted limit text
  static String getFormattedLimit(String? tierName) {
    final limit = getLimitForTier(tierName);
    if (limit == -1) {
      return 'Unlimited';
    }
    return limit.toString();
  }

  /// Get realtime subscription plan for a shop owner
  static Future<String?> getShopOwnerPlan(String shopOwnerId) async {
    try {
      final subscription = await FirebaseFirestore.instance
          .collection('subscriptions')
          .where('shopOwnerId', isEqualTo: shopOwnerId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (subscription.docs.isNotEmpty) {
        return subscription.docs.first['planName'];
      }
      return null;
    } catch (e) {
      print('Error fetching shop owner plan: $e');
      return null;
    }
  }

  /// Get product count for a shop owner
  static Future<int> getProductCount(String shopOwnerId) async {
    try {
      final count = await FirebaseFirestore.instance
          .collection('products')
          .where('shopOwnerId', isEqualTo: shopOwnerId)
          .count()
          .get();
      return count.count ?? 0;
    } catch (e) {
      print('Error fetching product count: $e');
      return 0;
    }
  }

  /// Get service count for a shop owner
  static Future<int> getServiceCount(String shopOwnerId) async {
    try {
      final count = await FirebaseFirestore.instance
          .collection('services')
          .where('shopOwnerId', isEqualTo: shopOwnerId)
          .count()
          .get();
      return count.count ?? 0;
    } catch (e) {
      print('Error fetching service count: $e');
      return 0;
    }
  }

  /// Get total items count (products + services) for a shop owner
  static Future<int> getTotalItemsCount(String shopOwnerId) async {
    try {
      final productCount = await getProductCount(shopOwnerId);
      final serviceCount = await getServiceCount(shopOwnerId);
      return productCount + serviceCount;
    } catch (e) {
      print('Error fetching total items count: $e');
      return 0;
    }
  }

  /// Get subscription limit info including current usage
  static Future<SubscriptionLimitInfo> getLimitInfo(String shopOwnerId) async {
    try {
      final plan = await getShopOwnerPlan(shopOwnerId);
      final tier = getTierFromPlanName(plan);
      final totalItems = await getTotalItemsCount(shopOwnerId);
      final limit = getLimitForTier(tier);

      return SubscriptionLimitInfo(
        planName: plan ?? tierOrdinary,
        tier: tier,
        totalItemsUsed: totalItems,
        maxLimit: limit,
        isSlotsAvailable: limit == -1 || totalItems < limit,
        slotsRemaining: limit == -1 ? null : (limit - totalItems),
      );
    } catch (e) {
      print('Error getting limit info: $e');
      // Return default Ordinary tier info if error occurs
      return SubscriptionLimitInfo(
        planName: tierOrdinary,
        tier: tierOrdinary,
        totalItemsUsed: 0,
        maxLimit: ordinaryLimit,
        isSlotsAvailable: true,
        slotsRemaining: ordinaryLimit,
      );
    }
  }

  /// Stream subscription limit info (realtime updates)
  static Stream<SubscriptionLimitInfo> streamLimitInfo(String shopOwnerId) => FirebaseFirestore.instance
        .collection('subscriptions')
        .where('shopOwnerId', isEqualTo: shopOwnerId)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .asyncMap((subscriptionSnapshot) async {
      final plan = subscriptionSnapshot.docs.isNotEmpty
          ? subscriptionSnapshot.docs.first['planName']
          : null;
      final tier = getTierFromPlanName(plan);
      final totalItems = await getTotalItemsCount(shopOwnerId);
      final limit = getLimitForTier(tier);

      return SubscriptionLimitInfo(
        planName: plan ?? tierOrdinary,
        tier: tier,
        totalItemsUsed: totalItems,
        maxLimit: limit,
        isSlotsAvailable: limit == -1 || totalItems < limit,
        slotsRemaining: limit == -1 ? null : (limit - totalItems),
      );
    });
}

/// Model to hold subscription limit information
class SubscriptionLimitInfo { // null for unlimited

  SubscriptionLimitInfo({
    required this.planName,
    required this.tier,
    required this.totalItemsUsed,
    required this.maxLimit,
    required this.isSlotsAvailable,
    required this.slotsRemaining,
  });
  final String planName;
  final String tier;
  final int totalItemsUsed;
  final int maxLimit; // -1 for unlimited
  final bool isSlotsAvailable;
  final int? slotsRemaining;

  /// Get formatted tier name
  String get formattedTier => tier;

  /// Get formatted max limit
  String get formattedMaxLimit =>
      maxLimit == -1 ? 'Unlimited' : maxLimit.toString();

  /// Get progress percentage (0 to 100)
  int get progressPercentage {
    if (maxLimit == -1) return 0; // No progress for unlimited
    return ((totalItemsUsed / maxLimit) * 100).ceil();
  }

  /// Get status message
  String get statusMessage {
    if (maxLimit == -1) {
      return 'Unlimited items';
    }
    return '$totalItemsUsed / $maxLimit items used';
  }

  /// Get remaining message
  String get remainingMessage {
    if (maxLimit == -1) {
      return 'Unlimited slots available';
    }
    final remaining = slotsRemaining ?? 0;
    return '$remaining slot${remaining != 1 ? 's' : ''} remaining';
  }
}
