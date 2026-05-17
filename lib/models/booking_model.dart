
class Booking {

  Booking({
    required this.id,
    required this.userId,
    required this.shopOwnerId,
    required this.productId,
    required this.productName,
    required this.productPrice,
    required this.bookingType,
    required this.bookingDate,
    required this.startDate,
    required this.quantity,
    required this.totalPrice,
    required this.status,
    required this.paymentStatus,
    required this.createdAt,
    this.userName,
    this.endDate,
    this.notes,
    this.updatedAt,
    this.userConfirmed = false,
    this.commissionFee = 0.0,
    this.subscriptionTier = 'Ordinary',
    this.isUserListing = false,
  });

  factory Booking.fromMap(Map<String, dynamic> map, String documentId) => Booking(
      id: documentId,
      userId: map['userId'] ?? '',
      userName: map['userName'],
      shopOwnerId: map['shopOwnerId'] ?? '',
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      productPrice: (map['productPrice'] ?? 0.0).toDouble(),
      bookingType: map['bookingType'] ?? 'BOOK',
      bookingDate: map['bookingDate'] != null
          ? (map['bookingDate'] as dynamic).toDate()
          : DateTime.now(),
      startDate: map['startDate'] != null
          ? (map['startDate'] as dynamic).toDate()
          : DateTime.now(),
      endDate: map['endDate'] != null
          ? (map['endDate'] as dynamic).toDate()
          : null,
      quantity: map['quantity'] ?? 1,
      totalPrice: (map['totalPrice'] ?? 0.0).toDouble(),
      status: map['status'] ?? 'PENDING',
      paymentStatus: map['paymentStatus'] ?? 'PENDING',
      notes: map['notes'],
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as dynamic).toDate()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as dynamic).toDate()
          : null,
      userConfirmed: map['userConfirmed'] ?? false,
      commissionFee: (map['commissionFee'] ?? 0.0).toDouble(),
      subscriptionTier: map['subscriptionTier'] ?? 'Ordinary',
      isUserListing: map['isUserListing'] ?? false,
    );
  final String id;
  final String userId;
  final String? userName;
  final String shopOwnerId;
  final String productId;
  final String productName;
  final double productPrice;
  final String bookingType; // 'BOOK', 'RESERVE', 'RENT'
  final DateTime bookingDate;
  final DateTime startDate;
  final DateTime? endDate;
  final int quantity;
  final double totalPrice;
  final String status; // 'PENDING', 'CONFIRMED', 'CANCELLED', 'COMPLETED'
  final String paymentStatus; // 'PENDING', 'PAID', 'REFUNDED'
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool userConfirmed; // Whether user has confirmed the booking
  final double commissionFee; // Commission fee for subscribed shop owners
  final String subscriptionTier; // Subscription tier of shop owner
  final bool isUserListing; // Whether product is a user-created listing or shop owner product

  Map<String, dynamic> toMap() => {
      'userId': userId,
      'userName': userName,
      'shopOwnerId': shopOwnerId,
      'productId': productId,
      'productName': productName,
      'productPrice': productPrice,
      'bookingType': bookingType,
      'bookingDate': bookingDate,
      'startDate': startDate,
      'endDate': endDate,
      'quantity': quantity,
      'totalPrice': totalPrice,
      'status': status,
      'paymentStatus': paymentStatus,
      'notes': notes,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'userConfirmed': userConfirmed,
      'commissionFee': commissionFee,
      'subscriptionTier': subscriptionTier,
      'isUserListing': isUserListing,
    };

  // Copy with method for updates
  Booking copyWith({
    String? id,
    String? userId,
    String? userName,
    String? shopOwnerId,
    String? productId,
    String? productName,
    double? productPrice,
    String? bookingType,
    DateTime? bookingDate,
    DateTime? startDate,
    DateTime? endDate,
    int? quantity,
    double? totalPrice,
    String? status,
    String? paymentStatus,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? userConfirmed,
    double? commissionFee,
    String? subscriptionTier,
    bool? isUserListing,
  }) => Booking(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      shopOwnerId: shopOwnerId ?? this.shopOwnerId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productPrice: productPrice ?? this.productPrice,
      bookingType: bookingType ?? this.bookingType,
      bookingDate: bookingDate ?? this.bookingDate,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      quantity: quantity ?? this.quantity,
      totalPrice: totalPrice ?? this.totalPrice,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userConfirmed: userConfirmed ?? this.userConfirmed,
      commissionFee: commissionFee ?? this.commissionFee,
      subscriptionTier: subscriptionTier ?? this.subscriptionTier,
      isUserListing: isUserListing ?? this.isUserListing,
    );
}
