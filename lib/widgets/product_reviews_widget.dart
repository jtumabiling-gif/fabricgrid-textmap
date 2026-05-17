import 'package:flutter/material.dart';
import '../models/review_model.dart';
import '../services/review_service.dart';
import '../theme/app_theme.dart';

class ProductReviewsWidget extends StatefulWidget {

  const ProductReviewsWidget({
    required this.productId,
    required this.shopOwnerId,
    this.showRatingSummary = false,
    super.key,
  });
  final String productId;
  final String shopOwnerId;
  final bool showRatingSummary;

  @override
  State<ProductReviewsWidget> createState() => _ProductReviewsWidgetState();
}

class _ProductReviewsWidgetState extends State<ProductReviewsWidget> {
  late ReviewService _reviewService;
  List<Review> _reviews = [];
  bool _isLoading = true;
  double _averageRating = 0;

  @override
  void initState() {
    super.initState();
    _reviewService = ReviewService();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    try {
      await _reviewService.initialize();
      final reviews = await _reviewService.getProductReviews(widget.productId);
      final avgRating = await _reviewService.getAverageRating(widget.shopOwnerId);

      if (mounted) {
        setState(() {
          _reviews = reviews;
          _averageRating = avgRating;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        print('Error loading reviews: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rating Summary (only if showRatingSummary is true)
        if (widget.showRatingSummary)
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primaryColor.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Overall Rating',
                      style: AppTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          _averageRating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildRatingStars(_averageRating, size: 18),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_reviews.length} ${_reviews.length == 1 ? 'review' : 'reviews'}',
                      style: AppTheme.bodySmall.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        // Reviews List
        if (_reviews.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Text(
                'No reviews yet',
                style: AppTheme.bodyMedium.copyWith(
                  color: Colors.grey[400],
                ),
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Customer Reviews',
                  style: AppTheme.headingMedium,
                ),
                const SizedBox(height: 12),
                ..._reviews.take(5).map(_buildReviewItem),
                if (_reviews.length > 5)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Center(
                      child: TextButton(
                        onPressed: () {},
                        child: const Text('View all reviews'),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildReviewItem(Review review) => Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.userName,
                        style: AppTheme.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatDate(review.createdAt),
                        style: AppTheme.bodySmall.copyWith(
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                _buildRatingStars(review.rating.toDouble(), size: 14),
              ],
            ),
            if (review.tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: review.tags.map((tag) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      tag,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )).toList(),
              ),
            ],
            if (review.reviewText.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                review.reviewText,
                style: AppTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );

  Widget _buildRatingStars(double rating, {double size = 16}) => Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (index) => Icon(
          Icons.star,
          size: size,
          color: index < rating.toInt() ? Colors.amber : Colors.grey[300],
        ),
      ),
    );

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} weeks ago';
    } else {
      return '${(difference.inDays / 30).floor()} months ago';
    }
  }
}
