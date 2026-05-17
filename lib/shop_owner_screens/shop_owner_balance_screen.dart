import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';

class ShopBalanceScreen extends StatefulWidget {
  const ShopBalanceScreen({super.key});

  @override
  State<ShopBalanceScreen> createState() => _ShopBalanceScreenState();
}

class _ShopBalanceScreenState extends State<ShopBalanceScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchShopBalance();
  }

  Future<void> _fetchShopBalance() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw 'User not authenticated';
      }
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching shop balance: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading balance: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: const Color(0xFF0F1F2F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1F2F),
        elevation: 0,
        title: const Text(
          'My Balance',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1EDDAC)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBalanceCard(),
                  const SizedBox(height: 24),
                  _buildTransactionsSection(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );

  Widget _buildBalanceCard() {
    final currentUser = FirebaseAuth.instance.currentUser;
    
    return StreamBuilder<List<QuerySnapshot>>(
      stream: Rx.combineLatest2(
        FirebaseFirestore.instance
            .collection('bookings')
            .where('shopOwnerId', isEqualTo: currentUser?.uid)
            .where('status', isEqualTo: 'COMPLETED')
            .snapshots(),
        FirebaseFirestore.instance
            .collection('book_service')
            .where('shopOwnerId', isEqualTo: currentUser?.uid)
            .where('status', isEqualTo: 'COMPLETED')
            .snapshots(),
        (snapshot1, snapshot2) => [snapshot1, snapshot2],
      ),
      builder: (context, snapshot) {
        var totalEarned = 0.0;
        
        if (snapshot.hasData && snapshot.data != null) {
          // Process product bookings
          for (final doc in snapshot.data![0].docs) {
            final data = doc.data()! as Map<String, dynamic>;
            final totalPrice = (data['totalPrice'] ?? 0.0).toDouble();
            totalEarned += totalPrice;
          }
          // Process service bookings
          for (final doc in snapshot.data![1].docs) {
            final data = doc.data()! as Map<String, dynamic>;
            final totalPrice = (data['totalPrice'] ?? 0.0).toDouble();
            totalEarned += totalPrice;
          }
        }

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1EDDAC),
                const Color(0xFF1EDDAC).withOpacity(0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1EDDAC).withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Total Earned',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '₱${totalEarned.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Withdrawal feature coming soon!'),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black87,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    child: const Text('Withdraw'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTransactionsSection() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Center(
        child: Text(
          'User not authenticated',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Products Booked',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        StreamBuilder<List<QuerySnapshot>>(
          stream: Rx.combineLatest2(
            FirebaseFirestore.instance
                .collection('bookings')
                .where('shopOwnerId', isEqualTo: currentUser.uid)
                .where('status', isEqualTo: 'COMPLETED')
                .snapshots(),
            FirebaseFirestore.instance
                .collection('book_service')
                .where('shopOwnerId', isEqualTo: currentUser.uid)
                .where('status', isEqualTo: 'COMPLETED')
                .snapshots(),
            (snapshot1, snapshot2) => [snapshot1, snapshot2],
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF1EDDAC)),
              );
            }

            if (!snapshot.hasData) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'No bookings yet',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              );
            }

            // Combine product and service bookings
            final productDocs = snapshot.data![0].docs;
            final serviceDocs = snapshot.data![1].docs;
            final allDocs = [...productDocs, ...serviceDocs];

            if (allDocs.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'No bookings yet',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              );
            }

            // Sort documents by createdAt in Dart
            allDocs.sort((a, b) {
              final aCreatedAt = a['createdAt'] as Timestamp?;
              final bCreatedAt = b['createdAt'] as Timestamp?;
              if (aCreatedAt == null || bCreatedAt == null) return 0;
              return bCreatedAt.compareTo(aCreatedAt); // Descending order
            });

            final bookings = allDocs.asMap().entries.map((entry) {
              final index = entry.key + 1;
              final doc = entry.value;
              final data = doc.data()! as Map<String, dynamic>;
              final productName = data['productName'] ?? data['serviceName'] ?? 'Unknown';
              final totalPrice = (data['totalPrice'] ?? 0.0).toDouble();
              final status = data['status'] ?? 'PENDING';

              return _buildTransactionCard(
                index,
                productName,
                totalPrice,
                status,
              );
            }).toList();

            return Column(
              children: bookings,
            );
          },
        ),
      ],
    );
  }

  Widget _buildTransactionCard(
    int index,
    String productName,
    double price,
    String status,
  ) {
    // Determine badge color based on status
    Color statusColor;
    switch (status.toUpperCase()) {
      case 'COMPLETED':
        statusColor = const Color(0xFF1EDDAC);
        break;
      case 'CONFIRMED':
        statusColor = Colors.blue;
        break;
      default:
        statusColor = Colors.orange;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2B3F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          // Index badge
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: statusColor.withOpacity(0.4)),
            ),
            child: Center(
              child: Text(
                '$index',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Product info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Status: $status',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Price badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF1EDDAC).withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: const Color(0xFF1EDDAC).withOpacity(0.4),
              ),
            ),
            child: Text(
              '₱${price.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1EDDAC),
              ),
            ),
          ),
        ],
      ),
    );
  }
}