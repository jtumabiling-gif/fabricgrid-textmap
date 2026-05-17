
class UserProfile {

  UserProfile({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.userType, required this.createdAt, this.phone,
    this.address,
    this.profileImageUrl,
    this.rating = 0.0,
    this.totalBookings = 0,
    this.totalReservations = 0,
    this.totalRentals = 0,
    this.updatedAt,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) => UserProfile(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      fullName: map['fullName'] ?? '',
      phone: map['phone'],
      address: map['address'],
      profileImageUrl: map['profileImageUrl'],
      userType: map['userType'] ?? 'USER',
      rating: (map['rating'] ?? 0.0).toDouble(),
      totalBookings: map['totalBookings'] ?? 0,
      totalReservations: map['totalReservations'] ?? 0,
      totalRentals: map['totalRentals'] ?? 0,
      createdAt: (map['createdAt'] as dynamic).toDate(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as dynamic).toDate()
          : null,
    );
  final String uid;
  final String email;
  final String fullName;
  final String? phone;
  final String? address;
  final String? profileImageUrl;
  final String userType; // 'USER', 'SHOP_OWNER'
  final double rating;
  final int totalBookings;
  final int totalReservations;
  final int totalRentals;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toMap() => {
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'phone': phone,
      'address': address,
      'profileImageUrl': profileImageUrl,
      'userType': userType,
      'rating': rating,
      'totalBookings': totalBookings,
      'totalReservations': totalReservations,
      'totalRentals': totalRentals,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };

  UserProfile copyWith({
    String? uid,
    String? email,
    String? fullName,
    String? phone,
    String? address,
    String? profileImageUrl,
    String? userType,
    double? rating,
    int? totalBookings,
    int? totalReservations,
    int? totalRentals,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => UserProfile(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      userType: userType ?? this.userType,
      rating: rating ?? this.rating,
      totalBookings: totalBookings ?? this.totalBookings,
      totalReservations: totalReservations ?? this.totalReservations,
      totalRentals: totalRentals ?? this.totalRentals,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
}
