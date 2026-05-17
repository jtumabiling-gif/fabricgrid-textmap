import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/booking_model.dart';
import '../services/review_service.dart';
import '../theme/app_theme.dart';

class ReviewSubmissionScreen extends StatefulWidget {

  const ReviewSubmissionScreen({
    required this.booking,
    super.key,
  });
  final Booking booking;

  @override
  State<ReviewSubmissionScreen> createState() => _ReviewSubmissionScreenState();
}

class _ReviewSubmissionScreenState extends State<ReviewSubmissionScreen> {
  int rating = 0;
  final TextEditingController reviewController = TextEditingController();
  final List<String> selectedTags = [];
  late ReviewService _reviewService;
  bool _isSubmitting = false;
  bool _hasReviewed = false;
  final List<String> availableTags = [
    'Professional',
    'Friendly',
    'On Time',
    'Clean',
    'Skilled',
    'Reliable',
    'Affordable',
  ];

  @override
  void initState() {
    super.initState();
    _reviewService = ReviewService();
    _checkIfReviewed();
  }

  Future<void> _checkIfReviewed() async {
    try {
      await _reviewService.initialize();
      final hasReviewed =
          await _reviewService.hasReviewedBooking(widget.booking.id);
      if (mounted) {
        setState(() => _hasReviewed = hasReviewed);
      }
    } catch (e) {
      // Error checking, but allow to proceed
      print('Error checking review status: $e');
    }
  }

  @override
  void dispose() {
    reviewController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _reviewService.initialize();
      await _reviewService.submitReview(
        bookingId: widget.booking.id,
        shopOwnerId: widget.booking.shopOwnerId,
        shopOwnerName: 'Shop Owner', // You may need to fetch this from user data
        productId: widget.booking.productId,
        productName: widget.booking.productName,
        rating: rating,
        reviewText: reviewController.text,
        tags: selectedTags,
      );

      if (mounted) {
        setState(() => _isSubmitting = false);
        Get.snackbar(
          'Success!',
          'Review submitted successfully!',
          backgroundColor: const Color(0xFF1EDDAC),
          colorText: Colors.black87,
          duration: const Duration(seconds: 2),
        );
        // Wait a moment then navigate back
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting review: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: const Color(0xFF0F1F2F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1F2F),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Write a Review', style: TextStyle(color: Colors.white)),
        elevation: 0,
        centerTitle: true,
      ),
      body: _hasReviewed
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 80,
                    color: AppTheme.primaryColor.withOpacity(0.7),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Already Reviewed',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      'Thank you for reviewing this booking. You can only submit one review per booking.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                    ),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Service Provider Info
            Card(
              color: const Color(0xFF1A2B3F),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Product: ${widget.booking.productName}',
                            style: AppTheme.headingMedium.copyWith(color: Colors.white),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Booking #${widget.booking.id.substring(0, 8).toUpperCase()}',
                            style: AppTheme.bodySmall.copyWith(color: Colors.white70),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${widget.booking.startDate.day}/${widget.booking.startDate.month}/${widget.booking.startDate.year}',
                            style: AppTheme.bodySmall.copyWith(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Rating Section
            const Text(
              'How was your experience?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (index) => GestureDetector(
                    onTap: () {
                      setState(() => rating = index + 1);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(
                        Icons.star,
                        size: 48,
                        color: index < rating ? Colors.amber : Colors.grey[300],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (rating > 0) ...[
              const SizedBox(height: 8),
              Center(
                child: Text(
                  _getRatingText(rating),
                  style: AppTheme.bodyLarge.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 32),
            // Tags Section
            const Text(
              'What was great?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: availableTags.map((tag) {
                final isSelected = selectedTags.contains(tag);
                return FilterChip(
                  label: Text(
                    tag,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                    ),
                  ),
                  selected: isSelected,
                  backgroundColor: const Color(0xFF1A2B3F),
                  selectedColor: const Color(0xFF1EDDAC),
                  side: BorderSide.none,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        selectedTags.add(tag);
                      } else {
                        selectedTags.remove(tag);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            // Review Text Section
            const Text(
              'Tell us more (optional)',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reviewController,
              maxLines: 5,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Share your experience...',
                hintStyle: TextStyle(color: Colors.white54),
                filled: true,
                fillColor: const Color(0xFF1A2B3F),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting
                    ? null
                    : rating > 0
                        ? _submitReview
                        : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1EDDAC),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  disabledBackgroundColor: Colors.grey[300],
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Submit Review',
                        style: AppTheme.buttonText,
                      ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Skip for now',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return 'Poor Experience';
      case 2:
        return 'Not Great';
      case 3:
        return 'Average';
      case 4:
        return 'Good';
      case 5:
        return 'Excellent!';
      default:
        return '';
    }
  }
}
