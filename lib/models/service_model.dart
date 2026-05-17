class Service {

  Service({
    required this.id,
    required this.shopOwnerId,
    required this.serviceName,
    required this.category,
    required this.price,
    required this.description,
    required this.estimatedTime,
    required this.expressDelivery,
    required this.homePickup,
    required this.materialIncluded,
    required this.status,
    required this.createdAt,
    required this.location,
    this.imageUrl,
    this.imageUrls = const [],
    this.updatedAt,
    this.shopOwnerName,
    this.isPremium = false,
    this.sellerTier,
    this.shopOwnerRating = 0.0,
  });

  factory Service.fromMap(Map<String, dynamic> map, String documentId) => Service(
      id: documentId,
      shopOwnerId: map['shopOwnerId'] ?? '',
      serviceName: map['serviceName'] ?? '',
      category: map['category'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      description: map['description'] ?? '',
      estimatedTime: map['estimatedTime'] ?? '',
      expressDelivery: map['expressDelivery'] ?? false,
      homePickup: map['homePickup'] ?? false,
      materialIncluded: map['materialIncluded'] ?? false,
      status: map['status'] ?? 'ACTIVE',
      imageUrl: map['imageUrl'],
      imageUrls: (map['imageUrls'] as List<dynamic>?)?.cast<String>() ?? [],
      location: map['location'] ?? {},
      createdAt: (map['createdAt'] as dynamic).toDate(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as dynamic).toDate()
          : null,
      shopOwnerName: map['shopOwnerName'],
      isPremium: map['isPremium'] ?? false,
      sellerTier: map['sellerTier'],
      shopOwnerRating: (map['shopOwnerRating'] ?? 0.0).toDouble(),
    );
  final String id;
  final String shopOwnerId;
  final String serviceName;
  final String category;
  final double price;
  final String description;
  final String estimatedTime;
  final bool expressDelivery;
  final bool homePickup;
  final bool materialIncluded;
  final String status; // 'ACTIVE', 'INACTIVE'
  final String? imageUrl;
  final List<String> imageUrls;
  final Map<String, dynamic> location;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? shopOwnerName;
  final bool isPremium;
  final String? sellerTier; // 'Premium', 'Standard', or null
  final double shopOwnerRating;

  Map<String, dynamic> toMap() => {
      'shopOwnerId': shopOwnerId,
      'serviceName': serviceName,
      'category': category,
      'price': price,
      'description': description,
      'estimatedTime': estimatedTime,
      'expressDelivery': expressDelivery,
      'homePickup': homePickup,
      'materialIncluded': materialIncluded,
      'status': status,
      'imageUrl': imageUrl,
      'imageUrls': imageUrls,
      'location': location,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'shopOwnerName': shopOwnerName,
      'isPremium': isPremium,
      'sellerTier': sellerTier,
      'shopOwnerRating': shopOwnerRating,
    };
}
