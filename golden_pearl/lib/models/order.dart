class Order {
  final int id;
  final String sessionId;
  final dynamic items;
  final int subtotal;
  final int shipping;
  final int discount;
  final int total;
  final String status;
  final String deliveryMethod;
  final String customerName;
  final String? customerEmail;
  final String customerPhone;
  final String shippingAddress;
  final String shippingCity;
  final String shippingCountry;
  final String? trackingNumber;
  final String? discountCode;
  final String? notes;
  final String? createdAt;

  Order({
    required this.id,
    required this.sessionId,
    required this.items,
    required this.subtotal,
    required this.shipping,
    required this.discount,
    required this.total,
    required this.status,
    this.deliveryMethod = 'delivery',
    required this.customerName,
    this.customerEmail,
    required this.customerPhone,
    required this.shippingAddress,
    required this.shippingCity,
    required this.shippingCountry,
    this.trackingNumber,
    this.discountCode,
    this.notes,
    this.createdAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      sessionId: json['sessionId'] ?? '',
      items: json['items'],
      subtotal: (json['subtotal'] as num).toInt(),
      shipping: (json['shipping'] as num?)?.toInt() ?? 0,
      discount: (json['discount'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num).toInt(),
      status: json['status'] ?? 'pending',
      deliveryMethod: json['deliveryMethod'] ?? 'delivery',
      customerName: json['customerName'] ?? '',
      customerEmail: json['customerEmail'],
      customerPhone: json['customerPhone'] ?? '',
      shippingAddress: json['shippingAddress'] ?? '',
      shippingCity: json['shippingCity'] ?? '',
      shippingCountry: json['shippingCountry'] ?? '',
      trackingNumber: json['trackingNumber'],
      discountCode: json['discountCode'],
      notes: json['notes'],
      createdAt: json['createdAt'],
    );
  }
}

class AppNotification {
  final int id;
  final String userId;
  final int? orderId;
  final String title;
  final String message;
  final bool read;
  final String? createdAt;

  AppNotification({
    required this.id,
    required this.userId,
    this.orderId,
    required this.title,
    required this.message,
    required this.read,
    this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'],
      userId: json['userId'] ?? '',
      orderId: json['orderId'],
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      read: json['read'] ?? false,
      createdAt: json['createdAt'],
    );
  }
}
