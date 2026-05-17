import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../services/shop_owner_service.dart';
import '../services/subscription_service.dart';
import 'shop_owner_payment_method_screen.dart';

class ShopOwnerSubscriptionScreen extends StatefulWidget {
  const ShopOwnerSubscriptionScreen({super.key});

  @override
  State<ShopOwnerSubscriptionScreen> createState() =>
      _ShopOwnerSubscriptionScreenState();
}

class _ShopOwnerSubscriptionScreenState
    extends State<ShopOwnerSubscriptionScreen> {
  DocumentSnapshot? _currentSubscription;
  Map<String, dynamic>? _shopOwnerData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSubscriptionData();
  }

  Future<void> _fetchSubscriptionData() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        // Initialize services
        final shopOwnerService = ShopOwnerService();
        final subscriptionService = SubscriptionService();
        
        await shopOwnerService.initialize();
        await subscriptionService.initialize();
        
        // Fetch shop owner profile data directly from Firestore
        final shopOwnerDoc = await FirebaseFirestore.instance
            .collection('shop_owners')
            .doc(userId)
            .get();
        
        if (shopOwnerDoc.exists) {
          _shopOwnerData = shopOwnerDoc.data();
        }
        
        // Also try to fetch subscription from subscriptions collection
        final subscription =
            await subscriptionService.getActiveSubscription(userId);
        
        if (mounted) {
          setState(() {
            _currentSubscription = subscription;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error fetching subscription data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFF0F1F2F),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0F1F2F),
          elevation: 0,
          leading: Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Center(
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: Get.back,
              ),
            ),
          ),
          title: const Text(
            'Subscription Plans',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          children: [
            // Current Subscription Info - Display if subscribed (from subscriptions collection OR shop owner profile)
            if (_currentSubscription != null || (_shopOwnerData != null && _shopOwnerData!['currentPlan'] != null)) ...[
              _buildCurrentSubscriptionCard(),
              const SizedBox(height: 32),
            ] else if (!_isLoading) ...[
              // No subscription message
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2B3F),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Color(0xFF1EDDAC),
                      size: 32,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'No Active Subscription',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Subscribe to a plan to unlock premium features',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
            // Available Plans Header
            const Text(
              'Available Plans',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            // Premium Plan Card (Recommended)
            _buildPlanCard(
              name: 'Premium',
              price: '₱199',
              period: '/ month',
              commission: '10%',
              commissionLabel: '10% commission fee',
              description: 'High search positioning',
              visibility: 'Highlighted border on marketplace',
              features: [
                'High search positioning (Top of list)',
                'Highlighted border on marketplace',
                'Unlimited featured product slots',
                '"Premium Seller" trust badge',
                'Priority 24/7 support',
              ],
              buttonText: 'Upgrade to Premium',
              isPopular: true,
            ),
            const SizedBox(height: 20),
            // Standard Plan Card
            _buildPlanCard(
              name: 'Standard',
              price: '₱99',
              period: '/ month',
              commission: '15%',
              commissionLabel: '15% commission fee',
              description: 'Basic search positioning',
              visibility: 'Standard photo display',
              features: [
                'Basic search positioning',
                'Standard photo display',
                'Limited featured product slots',
                'Standard seller profile',
                'Email support',
              ],
              buttonText: 'Select Plan',
              isPopular: false,
            ),
            const SizedBox(height: 32),
            // FAQ Section
            const Text(
              'Frequently Asked Questions',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            _buildFAQItem(
              question: 'How does the commission-based pricing work?',
              answer:
                  'Our pricing is based on commission rates. Standard (15%) and Premium (10%) plans determine the percentage we take from each sale. The Premium plan offers better marketplace visibility and lower commission.',
            ),
            _buildFAQItem(
              question: 'What does "High search positioning" mean?',
              answer:
                  'Premium members get their products featured at the top of search results and marketplace listings, while Standard members appear in normal order. Premium also gets a highlighted border to stand out.',
            ),
            _buildFAQItem(
              question: 'Can I change my plan anytime?',
              answer:
                  'Yes, you can upgrade or downgrade your plan anytime. Upgrades take effect immediately with the new commission rate applied to new sales. Downgrades take effect at the end of your current period.',
            ),
            _buildFAQItem(
              question: 'What is the "Premium Seller" badge?',
              answer:
                  'The Premium Seller badge appears on your profile and products, building trust with customers and indicating you are a verified premium seller.',
            ),
            _buildFAQItem(
              question: 'Are there any setup fees or hidden charges?',
              answer:
                  'No hidden fees! The monthly subscription includes all features. Commission is only charged on successful sales beyond the monthly subscription fee.',
            ),
            const SizedBox(height: 32),
          ],
        ),
      );
  Widget _buildCurrentSubscriptionCard() {
    // Try to get data from subscriptions collection first, then fallback to shop owner profile
    var planName = 'N/A';
    var price = 'N/A';
    double commission = 0;
    DateTime? startDate;
    DateTime? endDate;
    
    if (_currentSubscription != null) {
      final rawData = _currentSubscription!.data();
      if (rawData != null) {
        final data = rawData as Map<String, dynamic>;
        planName = data['planName'] as String? ?? 'N/A';
        price = data['price'] as String? ?? 'N/A';
        commission = data['commission'] as double? ?? 0;
        endDate = (data['subscriptionStartDate'] as Timestamp?)?.toDate();
        startDate = (data['subscriptionEndDate'] as Timestamp?)?.toDate();
      }
    } else if (_shopOwnerData != null) {
      // Fallback to shop owner profile data
      planName = _shopOwnerData!['currentPlan'] as String? ?? 'N/A';
      final commissionRate = _shopOwnerData!['commissionRate'];
      if (commissionRate is double) {
        commission = commissionRate;
      } else if (commissionRate is int) {
        commission = commissionRate.toDouble();
      }
      endDate = (_shopOwnerData!['subscriptionStartDate'] as Timestamp?)?.toDate();
      startDate = (_shopOwnerData!['subscriptionEndDate'] as Timestamp?)?.toDate();
      
      // Determine price from plan name
      if (planName.toLowerCase().contains('premium')) {
        price = '₱199 / month';
      } else if (planName.toLowerCase().contains('standard')) {
        price = '₱99 / month';
      }
    } else {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2B3F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1EDDAC), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Current Subscription',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    planName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    price,
                    style: const TextStyle(
                      color: Color(0xFF1EDDAC),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Commission: ${commission.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1EDDAC).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Active',
                  style: TextStyle(
                    color: Color(0xFF1EDDAC),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white12),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Start Date',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    startDate != null
                        ? '${startDate.day}/${startDate.month}/${startDate.year}'
                        : 'N/A',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Expiration Date',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    endDate != null
                        ? '${endDate.day}/${endDate.month}/${endDate.year}'
                        : 'N/A',
                    style: const TextStyle(
                      color: Color(0xFFFFB84D),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard({
    required String name,
    required String price,
    required String period,
    required String commission,
    required String commissionLabel,
    required String description,
    required String visibility,
    required List<String> features,
    required String buttonText,
    bool isPopular = false,
  }) =>
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2B3F),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (isPopular)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1EDDAC).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF1EDDAC),
                        width: 1.5,
                      ),
                    ),
                    child: const Text(
                      'Recommended',
                      style: TextStyle(
                        color: Color(0xFF1EDDAC),
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // Price Display
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: price,
                    style: const TextStyle(
                      color: Color(0xFF1EDDAC),
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  TextSpan(
                    text: period,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Commission Highlight Box
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                color: isPopular
                    ? const Color(0xFF1EDDAC).withOpacity(0.2)
                    : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isPopular
                      ? const Color(0xFF1EDDAC).withOpacity(0.5)
                      : Colors.white.withOpacity(0.1),
                ),
              ),
              child: Text(
                commissionLabel,
                style: TextStyle(
                  color: isPopular ? const Color(0xFF1EDDAC) : Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            const SizedBox(height: 14),
            // Description
            Text(
              description,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              visibility,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 18),
            Divider(
              color: Colors.white.withOpacity(0.1),
              height: 1,
            ),
            const SizedBox(height: 18),
            // Features List
            ...features
                .asMap()
                .entries
                .map((entry) {
                  final isLast = entry.key == features.length - 1;
                  return Padding(
                    padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFF1EDDAC),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            entry.value,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              height: 1.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                })
                ,
            const SizedBox(height: 22),
            // CTA Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isPopular
                      ? const Color(0xFF1EDDAC)
                      : Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: isPopular
                      ? null
                      : const BorderSide(
                          color: Color(0xFF1EDDAC),
                          width: 2,
                        ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: isPopular ? 2 : 0,
                ),
                onPressed: () => _navigateToPaymentMethod(context, name, price, commission),
                child: Text(
                  buttonText,
                  style: TextStyle(
                    color: isPopular
                        ? const Color(0xFF0F1F2F)
                        : const Color(0xFF1EDDAC),
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildFAQItem({
    required String question,
    required String answer,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Theme(
          data: Theme.of(context).copyWith(
            dividerColor: Colors.transparent,
          ),
          child: ExpansionTile(
            backgroundColor: Colors.transparent,
            collapsedBackgroundColor: Colors.transparent,
            tilePadding: EdgeInsets.zero,
            title: Text(
              question,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 12, 0, 0),
                child: Text(
                  answer,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.6,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  void _navigateToPaymentMethod(BuildContext context, String planName, String price, String commission) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ShopOwnerPaymentMethodScreen(
          planName: planName,
          price: price,
          commission: commission,
          period: '/ month',
        ),
      ),
    );
  }
}
