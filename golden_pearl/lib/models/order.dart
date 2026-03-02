class Order {
  final int id;
  final String sessionId;
  final dynamic items;
  final int subtotal;
  final int shipping;
  final int discount;
  final int total;
  final String status;
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
      status: json['status'] ?? 'processing',
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
