
class ShopOwnerProfile {

  ShopOwnerProfile({
    required this.uid,
    required this.email,
    required this.shopName,
    required this.latitude, required this.longitude, required this.createdAt, this.shopDescription,
    this.phone,
    this.address,
    this.shopImageUrl,
    this.ownerFullName,
    this.rating = 0.0,
    this.totalProducts = 0,
    this.totalBookings = 0,
    this.totalReservations = 0,
    this.totalRentals = 0,
    this.activeInventoryItems = 0,
    this.totalRevenue = 0.0,
    this.balance = 0.0,
    this.totalCommission = 0.0,
    this.updatedAt,
  });

  factory ShopOwnerProfile.fromMap(Map<String, dynamic> map) => ShopOwnerProfile(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      shopName: map['shopName'] ?? '',
      shopDescription: map['shopDescription'],
      phone: map['phone'],
      address: map['address'],
      shopImageUrl: map['shopImageUrl'],
      ownerFullName: map['ownerFullName'],
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      rating: (map['rating'] ?? 0.0).toDouble(),
      totalProducts: map['totalProducts'] ?? 0,
      totalBookings: map['totalBookings'] ?? 0,
      totalReservations: map['totalReservations'] ?? 0,
      totalRentals: map['totalRentals'] ?? 0,
      activeInventoryItems: map['activeInventoryItems'] ?? 0,
      totalRevenue: (map['totalRevenue'] ?? 0.0).toDouble(),
      balance: (map['balance'] ?? 0.0).toDouble(),
      totalCommission: (map['totalCommission'] ?? 0.0).toDouble(),
      createdAt: (map['createdAt'] as dynamic).toDate(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as dynamic).toDate()
          : null,
    );
  final String uid;
  final String email;
  final String shopName;
  final String? shopDescription;
  final String? phone;
  final String? address;
  final String? shopImageUrl;
  final String? ownerFullName;
  final double latitude;
  final double longitude;
  final double rating;
  final int totalProducts;
  final int totalBookings;
  final int totalReservations;
  final int totalRentals;
  final int activeInventoryItems;
  final double totalRevenue;
  final double balance;
  final double totalCommission;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toMap() => {
      'uid': uid,
      'email': email,
      'shopName': shopName,
      'shopDescription': shopDescription,
      'phone': phone,
      'address': address,
      'shopImageUrl': shopImageUrl,
      'ownerFullName': ownerFullName,
      'latitude': latitude,
      'longitude': longitude,
      'rating': rating,
      'totalProducts': totalProducts,
      'totalBookings': totalBookings,
      'totalReservations': totalReservations,
      'totalRentals': totalRentals,
      'activeInventoryItems': activeInventoryItems,
      'totalRevenue': totalRevenue,
      'balance': balance,
      'totalCommission': totalCommission,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };

  ShopOwnerProfile copyWith({
    String? uid,
    String? email,
    String? shopName,
    String? shopDescription,
    String? phone,
    String? address,
    String? shopImageUrl,
    String? ownerFullName,
    double? latitude,
    double? longitude,
    double? rating,
    int? totalProducts,
    int? totalBookings,
    int? totalReservations,
    int? totalRentals,
    int? activeInventoryItems,
    double? totalRevenue,
    double? balance,
    double? totalCommission,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => ShopOwnerProfile(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      shopName: shopName ?? this.shopName,
      shopDescription: shopDescription ?? this.shopDescription,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      shopImageUrl: shopImageUrl ?? this.shopImageUrl,
      ownerFullName: ownerFullName ?? this.ownerFullName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      rating: rating ?? this.rating,
      totalProducts: totalProducts ?? this.totalProducts,
      totalBookings: totalBookings ?? this.totalBookings,
      totalReservations: totalReservations ?? this.totalReservations,
      totalRentals: totalRentals ?? this.totalRentals,
      activeInventoryItems: activeInventoryItems ?? this.activeInventoryItems,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      balance: balance ?? this.balance,
      totalCommission: totalCommission ?? this.totalCommission,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
}
