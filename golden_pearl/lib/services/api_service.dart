import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/product.dart';
import '../models/cart_item.dart';
import '../models/order.dart';

class ApiService {
  static String get baseUrl {
    if (kIsWeb) {
      final uri = Uri.base;
      return '${uri.scheme}://${uri.host}:${uri.port}';
    }
    return 'http://10.0.2.2:5000';
  }

  final http.Client _client = http.Client();
  String? _cookie;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_cookie != null) 'Cookie': _cookie!,
  };

  void _updateCookie(http.Response response) {
    final setCookie = response.headers['set-cookie'];
    if (setCookie != null) {
      _cookie = setCookie.split(';').first;
    }
  }

  Future<List<Product>> getProducts({String? category, String? search, bool? featured}) async {
    final params = <String, String>{};
    if (category != null) params['category'] = category;
    if (search != null) params['search'] = search;
    if (featured == true) params['featured'] = 'true';
    final uri = Uri.parse('$baseUrl/api/products').replace(queryParameters: params.isNotEmpty ? params : null);
    final response = await _client.get(uri, headers: _headers);
    _updateCookie(response);
    final List data = jsonDecode(response.body);
    return data.map((json) => Product.fromJson(json)).toList();
  }

  Future<Product> getProduct(int id) async {
    final response = await _client.get(Uri.parse('$baseUrl/api/products/$id'), headers: _headers);
    _updateCookie(response);
    return Product.fromJson(jsonDecode(response.body));
  }

  Future<List<CartItem>> getCart() async {
    final response = await _client.get(Uri.parse('$baseUrl/api/cart'), headers: _headers);
    _updateCookie(response);
    final List data = jsonDecode(response.body);
    return data.map((json) => CartItem.fromJson(json)).toList();
  }

  Future<void> addToCart(int productId, String size, String color, {int quantity = 1}) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/cart'),
      headers: _headers,
      body: jsonEncode({'productId': productId, 'size': size, 'color': color, 'quantity': quantity}),
    );
    _updateCookie(response);
  }

  Future<void> updateCartItem(int id, int quantity) async {
    final response = await _client.patch(
      Uri.parse('$baseUrl/api/cart/$id'),
      headers: _headers,
      body: jsonEncode({'quantity': quantity}),
    );
    _updateCookie(response);
  }

  Future<void> removeCartItem(int id) async {
    final response = await _client.delete(Uri.parse('$baseUrl/api/cart/$id'), headers: _headers);
    _updateCookie(response);
  }

  Future<void> clearCart() async {
    final response = await _client.delete(Uri.parse('$baseUrl/api/cart'), headers: _headers);
    _updateCookie(response);
  }

  Future<Order> createOrder(Map<String, dynamic> orderData) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/orders'),
      headers: _headers,
      body: jsonEncode(orderData),
    );
    _updateCookie(response);
    return Order.fromJson(jsonDecode(response.body));
  }

  Future<List<Order>> getOrders() async {
    final response = await _client.get(Uri.parse('$baseUrl/api/orders'), headers: _headers);
    _updateCookie(response);
    final List data = jsonDecode(response.body);
    return data.map((json) => Order.fromJson(json)).toList();
  }

  Future<Map<String, dynamic>?> validateDiscount(String code) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/discounts/validate'),
      headers: _headers,
      body: jsonEncode({'code': code}),
    );
    _updateCookie(response);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }
}
