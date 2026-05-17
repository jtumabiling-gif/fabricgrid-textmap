class Review {
  Review({
    required this.id,
    required this.bookingId,
    required this.userId,
    required this.userName,
    required this.shopOwnerId,
    required this.shopOwnerName,
    required this.productId,
    required this.productName,
    required this.rating,
    required this.reviewText,
    required this.tags,
    required this.createdAt,
    this.updatedAt,
  });

  factory Review.fromMap(Map<String, dynamic> map, String documentId) => Review(
    id: documentId,
    bookingId: map['bookingId'] ?? '',
    userId: map['userId'] ?? '',
    userName: map['userName'] ?? '',
    shopOwnerId: map['shopOwnerId'] ?? '',
    shopOwnerName: map['shopOwnerName'] ?? '',
    productId: map['productId'] ?? '',
    productName: map['productName'] ?? '',
    rating: map['rating'] ?? 0,
    reviewText: map['reviewText'] ?? '',
    tags: List<String>.from(map['tags'] ?? []),
    createdAt: (map['createdAt'] as dynamic).toDate(),
    updatedAt: map['updatedAt'] != null
        ? (map['updatedAt'] as dynamic).toDate()
        : null,
  );

  final String id;
  final String bookingId;
  final String userId;
  final String userName;
  final String shopOwnerId;
  final String shopOwnerName;
  final String productId;
  final String productName;
  final int rating;
  final String reviewText;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toMap() => {
    'bookingId': bookingId,
    'userId': userId,
    'userName': userName,
    'shopOwnerId': shopOwnerId,
    'shopOwnerName': shopOwnerName,
    'productId': productId,
    'productName': productName,
    'rating': rating,
    'reviewText': reviewText,
    'tags': tags,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };

  Review copyWith({
    String? id,
    String? bookingId,
    String? userId,
    String? userName,
    String? shopOwnerId,
    String? shopOwnerName,
    String? productId,
    String? productName,
    int? rating,
    String? reviewText,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Review(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      shopOwnerId: shopOwnerId ?? this.shopOwnerId,
      shopOwnerName: shopOwnerName ?? this.shopOwnerName,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      rating: rating ?? this.rating,
      reviewText: reviewText ?? this.reviewText,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
}
