class Product {

  Product({
    required this.id,
    required this.productName,
    required this.description,
    required this.price,
    required this.category,
    required this.status,
    required this.stockQuantity,
    required this.sku,
    required this.location,
    required this.shopOwnerId,
    this.createdAt,
    this.updatedAt,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.isPremium = false,
    this.sellerTier,
    this.shopOwnerName,
  });

  factory Product.fromMap(Map<String, dynamic> map, String documentId) => Product(
      id: documentId,
      productName: map['productName'] ?? 'Product',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      category: map['category'] ?? 'General',
      status: map['status'] ?? 'AVAILABLE',
      stockQuantity: map['stockQuantity'] ?? 0,
      sku: map['sku'] ?? '',
      location: map['location'] ?? {},
      shopOwnerId: map['shopOwnerId'] ?? '',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as dynamic).toDate()
          : null,
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as dynamic).toDate()
          : null,
      rating: (map['rating'] ?? 0.0).toDouble(),
      reviewCount: map['reviewCount'] ?? 0,
      isPremium: map['isPremium'] ?? false,
      sellerTier: map['sellerTier'],
      shopOwnerName: map['shopOwnerName'],
    );
  final String id;
  final String productName;
  final String description;
  final double price;
  final String category;
  final String status;
  final int stockQuantity;
  final String sku;
  final Map<String, dynamic> location;
  final String shopOwnerId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final double rating;
  final int reviewCount;
  final bool isPremium;
  final String? sellerTier; // 'Premium', 'Standard', or null
  final String? shopOwnerName;

  Map<String, dynamic> toMap() => {
      'productName': productName,
      'description': description,
      'price': price,
      'category': category,
      'status': status,
      'stockQuantity': stockQuantity,
      'sku': sku,
      'location': location,
      'shopOwnerId': shopOwnerId,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'rating': rating,
      'reviewCount': reviewCount,
      'isPremium': isPremium,
      'sellerTier': sellerTier,
      'shopOwnerName': shopOwnerName,
    };
}
