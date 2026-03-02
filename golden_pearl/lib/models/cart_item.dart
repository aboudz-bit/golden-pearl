import 'product.dart';

class CartItem {
  final int id;
  final String sessionId;
  final int productId;
  final int quantity;
  final String size;
  final String color;
  final Product? product;

  CartItem({
    required this.id,
    required this.sessionId,
    required this.productId,
    required this.quantity,
    required this.size,
    required this.color,
    this.product,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      sessionId: json['sessionId'] ?? '',
      productId: json['productId'] is int ? json['productId'] : int.parse(json['productId'].toString()),
      quantity: json['quantity'] ?? 1,
      size: json['size'] ?? '',
      color: json['color'] ?? '',
      product: json['product'] != null ? Product.fromJson(json['product']) : null,
    );
  }
}
