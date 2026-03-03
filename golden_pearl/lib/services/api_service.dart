import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/browser_client.dart';
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

  late final http.Client _client;
  String? _cookie;

  ApiService() {
    if (kIsWeb) {
      final browserClient = BrowserClient();
      browserClient.withCredentials = true;
      _client = browserClient;
    } else {
      _client = http.Client();
    }
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (!kIsWeb && _cookie != null) 'Cookie': _cookie!,
  };

  void _updateCookie(http.Response response) {
    if (kIsWeb) return;
    final setCookie = response.headers['set-cookie'];
    if (setCookie != null) {
      _cookie = setCookie.split(';').first;
    }
  }

  void _checkResponse(http.Response response) {
    if (response.statusCode >= 400) {
      String msg;
      try {
        final body = jsonDecode(response.body);
        msg = body['message'] ?? 'Request failed';
      } catch (_) {
        msg = 'Request failed (${response.statusCode})';
      }
      throw Exception(msg);
    }
  }

  Future<Map<String, dynamic>?> login(String email, String password) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: _headers,
      body: jsonEncode({'email': email, 'password': password}),
    );
    _updateCookie(response);
    _checkResponse(response);
    final data = jsonDecode(response.body);
    return data['user'];
  }

  Future<Map<String, dynamic>?> register(String email, String password, String name, String? phone) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/auth/register'),
      headers: _headers,
      body: jsonEncode({'email': email, 'password': password, 'name': name, 'phone': phone}),
    );
    _updateCookie(response);
    _checkResponse(response);
    final data = jsonDecode(response.body);
    return data['user'];
  }

  Future<void> logout() async {
    final response = await _client.post(Uri.parse('$baseUrl/api/auth/logout'), headers: _headers);
    _updateCookie(response);
    _checkResponse(response);
  }

  Future<Map<String, dynamic>?> getMe() async {
    final response = await _client.get(Uri.parse('$baseUrl/api/auth/me'), headers: _headers);
    _updateCookie(response);
    _checkResponse(response);
    final data = jsonDecode(response.body);
    return data['user'];
  }

  Future<void> mergeCart() async {
    final response = await _client.post(Uri.parse('$baseUrl/api/auth/merge'), headers: _headers);
    _updateCookie(response);
  }

  Future<List<Product>> getProducts({String? category, String? search, bool? featured}) async {
    final params = <String, String>{};
    if (category != null) params['category'] = category;
    if (search != null) params['search'] = search;
    if (featured == true) params['featured'] = 'true';
    final uri = Uri.parse('$baseUrl/api/products').replace(queryParameters: params.isNotEmpty ? params : null);
    final response = await _client.get(uri, headers: _headers);
    _updateCookie(response);
    _checkResponse(response);
    final List data = jsonDecode(response.body);
    return data.map((json) => Product.fromJson(json)).toList();
  }

  Future<Product> getProduct(int id) async {
    final response = await _client.get(Uri.parse('$baseUrl/api/products/$id'), headers: _headers);
    _updateCookie(response);
    _checkResponse(response);
    return Product.fromJson(jsonDecode(response.body));
  }

  Future<List<CartItem>> getCart() async {
    final response = await _client.get(Uri.parse('$baseUrl/api/cart'), headers: _headers);
    _updateCookie(response);
    _checkResponse(response);
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
    _checkResponse(response);
  }

  Future<void> updateCartItem(int id, int quantity) async {
    final response = await _client.patch(
      Uri.parse('$baseUrl/api/cart/$id'),
      headers: _headers,
      body: jsonEncode({'quantity': quantity}),
    );
    _updateCookie(response);
    _checkResponse(response);
  }

  Future<void> removeCartItem(int id) async {
    final response = await _client.delete(Uri.parse('$baseUrl/api/cart/$id'), headers: _headers);
    _updateCookie(response);
    _checkResponse(response);
  }

  Future<void> clearCart() async {
    final response = await _client.delete(Uri.parse('$baseUrl/api/cart'), headers: _headers);
    _updateCookie(response);
    _checkResponse(response);
  }

  Future<Order> createOrder(Map<String, dynamic> orderData) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/orders'),
      headers: _headers,
      body: jsonEncode(orderData),
    );
    _updateCookie(response);
    _checkResponse(response);
    return Order.fromJson(jsonDecode(response.body));
  }

  Future<List<Order>> getOrders() async {
    final response = await _client.get(Uri.parse('$baseUrl/api/orders'), headers: _headers);
    _updateCookie(response);
    _checkResponse(response);
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

  Future<List<AppNotification>> getNotifications() async {
    final response = await _client.get(Uri.parse('$baseUrl/api/notifications'), headers: _headers);
    _updateCookie(response);
    _checkResponse(response);
    final List data = jsonDecode(response.body);
    return data.map((json) => AppNotification.fromJson(json)).toList();
  }

  Future<int> getUnreadNotificationCount() async {
    final response = await _client.get(Uri.parse('$baseUrl/api/notifications/unread-count'), headers: _headers);
    _updateCookie(response);
    _checkResponse(response);
    final data = jsonDecode(response.body);
    return (data['count'] as num?)?.toInt() ?? 0;
  }

  Future<void> markNotificationRead(int id) async {
    final response = await _client.patch(
      Uri.parse('$baseUrl/api/notifications/$id/read'),
      headers: _headers,
    );
    _updateCookie(response);
    _checkResponse(response);
  }

  Future<String?> getSetting(String key) async {
    final response = await _client.get(Uri.parse('$baseUrl/api/settings/$key'), headers: _headers);
    _updateCookie(response);
    _checkResponse(response);
    final data = jsonDecode(response.body);
    final value = data['value'];
    return (value != null && value.toString().isNotEmpty) ? value.toString() : null;
  }

  Future<void> trackPageView(String sessionId, String page, {int? productId}) async {
    try {
      await _client.post(
        Uri.parse('$baseUrl/api/analytics/pageview'),
        headers: _headers,
        body: jsonEncode({'sessionId': sessionId, 'page': page, 'productId': productId}),
      );
    } catch (_) {}
  }

  Future<List<Order>> getAllOrders() async {
    final response = await _client.get(Uri.parse('$baseUrl/api/admin/orders'), headers: _headers);
    _updateCookie(response);
    _checkResponse(response);
    final List data = jsonDecode(response.body);
    return data.map((json) => Order.fromJson(json)).toList();
  }

  Future<void> updateOrderStatus(int id, String status, {String? trackingNumber}) async {
    final body = <String, dynamic>{'status': status};
    if (trackingNumber != null) body['trackingNumber'] = trackingNumber;
    final response = await _client.patch(
      Uri.parse('$baseUrl/api/admin/orders/$id/status'),
      headers: _headers,
      body: jsonEncode(body),
    );
    _updateCookie(response);
    _checkResponse(response);
  }

  Future<List<Map<String, dynamic>>> getAllSettings() async {
    final response = await _client.get(Uri.parse('$baseUrl/api/admin/settings'), headers: _headers);
    _updateCookie(response);
    _checkResponse(response);
    final List data = jsonDecode(response.body);
    return data.cast<Map<String, dynamic>>();
  }

  Future<void> updateSetting(String key, String value) async {
    final response = await _client.put(
      Uri.parse('$baseUrl/api/admin/settings/$key'),
      headers: _headers,
      body: jsonEncode({'value': value}),
    );
    _updateCookie(response);
    _checkResponse(response);
  }

  Future<Map<String, dynamic>> getAnalytics() async {
    final response = await _client.get(Uri.parse('$baseUrl/api/admin/analytics'), headers: _headers);
    _updateCookie(response);
    _checkResponse(response);
    return jsonDecode(response.body);
  }

  Future<void> updateProductStock(int id, int stock) async {
    final response = await _client.patch(
      Uri.parse('$baseUrl/api/admin/products/$id/stock'),
      headers: _headers,
      body: jsonEncode({'stock': stock}),
    );
    _updateCookie(response);
    _checkResponse(response);
  }

  Future<Product> createProduct(Map<String, dynamic> productData) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/admin/products'),
      headers: _headers,
      body: jsonEncode(productData),
    );
    _updateCookie(response);
    _checkResponse(response);
    return Product.fromJson(jsonDecode(response.body));
  }

  Future<Product> updateProduct(int id, Map<String, dynamic> productData) async {
    final response = await _client.patch(
      Uri.parse('$baseUrl/api/admin/products/$id'),
      headers: _headers,
      body: jsonEncode(productData),
    );
    _updateCookie(response);
    _checkResponse(response);
    return Product.fromJson(jsonDecode(response.body));
  }

  Future<void> deleteProduct(int id) async {
    final response = await _client.delete(Uri.parse('$baseUrl/api/admin/products/$id'), headers: _headers);
    _updateCookie(response);
    _checkResponse(response);
  }

  Future<List<Map<String, dynamic>>> getAllDiscounts() async {
    final response = await _client.get(Uri.parse('$baseUrl/api/admin/discounts'), headers: _headers);
    _updateCookie(response);
    _checkResponse(response);
    final List data = jsonDecode(response.body);
    return data.cast<Map<String, dynamic>>();
  }

  Future<void> createDiscount(Map<String, dynamic> data) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/admin/discounts'),
      headers: _headers,
      body: jsonEncode(data),
    );
    _updateCookie(response);
    _checkResponse(response);
  }

  Future<void> deleteDiscount(int id) async {
    final response = await _client.delete(Uri.parse('$baseUrl/api/admin/discounts/$id'), headers: _headers);
    _updateCookie(response);
    _checkResponse(response);
  }
}
