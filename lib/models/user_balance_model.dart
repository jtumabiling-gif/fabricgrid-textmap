class UserBalance {
  UserBalance({
    required this.uid,
    required this.fullName,
    this.balance = 0.0,
    this.totalEarnings = 0.0,
    this.totalSpent = 0.0,
    this.totalTransactions = 0,
    this.profileImageUrl,
    this.rating = 0.0,
    this.totalBookings = 0,
  });

  factory UserBalance.fromMap(Map<String, dynamic> map) => UserBalance(
    uid: map['uid'] ?? '',
    fullName: map['fullName'] ?? '',
    balance: (map['balance'] ?? 0.0).toDouble(),
    totalEarnings: (map['totalEarnings'] ?? 0.0).toDouble(),
    totalSpent: (map['totalSpent'] ?? 0.0).toDouble(),
    totalTransactions: map['totalTransactions'] ?? 0,
    profileImageUrl: map['profileImageUrl'],
    rating: (map['rating'] ?? 0.0).toDouble(),
    totalBookings: map['totalBookings'] ?? 0,
  );

  final String uid;
  final String fullName;
  final double balance;
  final double totalEarnings;
  final double totalSpent;
  final int totalTransactions;
  final String? profileImageUrl;
  final double rating;
  final int totalBookings;

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'fullName': fullName,
    'balance': balance,
    'totalEarnings': totalEarnings,
    'totalSpent': totalSpent,
    'totalTransactions': totalTransactions,
    'profileImageUrl': profileImageUrl,
    'rating': rating,
    'totalBookings': totalBookings,
  };
}
