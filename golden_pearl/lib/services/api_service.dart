import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' as http_parser;
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import '../models/product.dart';
import '../models/cart_item.dart';
import '../models/order.dart';
import '_http_client_io.dart'
    if (dart.library.html) '_http_client_web.dart';

class ApiService {
  static const String _compileTimeUrl = String.fromEnvironment('API_URL', defaultValue: '');

  static const String _replitProductionUrl = 'https://092abce6-58f2-4c03-a2f8-b776b35aaa5a-00-3uf3y825evgo7.riker.replit.dev';

  static bool _baseUrlLogged = false;

  static String get baseUrl {
    final url = _resolveBaseUrl();
    if (!_baseUrlLogged) {
      _baseUrlLogged = true;
      if (kDebugMode) {
        // ignore: avoid_print
        print('[ApiService] baseUrl resolved to: $url');
      }
    }
    return url;
  }

  static String _resolveBaseUrl() {
    if (_compileTimeUrl.isNotEmpty) return _compileTimeUrl;

    if (kIsWeb) {
      final uri = Uri.base;
      final port = uri.hasPort ? ':${uri.port}' : '';
      return '${uri.scheme}://${uri.host}$port';
    }

    return _replitProductionUrl;
  }

  late final http.Client _client;
  String? _cookie;

  ApiService() {
    _client = createPlatformHttpClient();
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

  Future<void> deleteAccount() async {
    final response = await _client.delete(Uri.parse('$baseUrl/api/auth/account'), headers: _headers);
    _updateCookie(response);
    _checkResponse(response);
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

  Future<List<Order>> getAllOrders({
    String? deliveryMethod,
    String? status,
    String? q,
    String? dateFrom,
    String? dateTo,
    String? sort,
  }) async {
    final params = <String, String>{};
    if (deliveryMethod != null && deliveryMethod != 'all') params['deliveryMethod'] = deliveryMethod;
    if (status != null && status != 'all') params['status'] = status;
    if (q != null && q.isNotEmpty) params['q'] = q;
    if (dateFrom != null) params['dateFrom'] = dateFrom;
    if (dateTo != null) params['dateTo'] = dateTo;
    if (sort != null && sort != 'newest') params['sort'] = sort;
    final uri = Uri.parse('$baseUrl/api/admin/orders').replace(queryParameters: params.isNotEmpty ? params : null);
    final response = await _client.get(uri, headers: _headers);
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

  Future<Map<String, dynamic>?> getHeroOverlay() async {
    final value = await getSetting('heroOverlay');
    if (value == null || value.isEmpty) return null;
    try {
      return jsonDecode(value) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveHeroOverlay(Map<String, dynamic> overlay) async {
    await updateSetting('heroOverlay', jsonEncode(overlay));
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

  Future<void> updateDiscount(int id, Map<String, dynamic> data) async {
    final response = await _client.patch(
      Uri.parse('$baseUrl/api/admin/discounts/$id'),
      headers: _headers,
      body: jsonEncode(data),
    );
    _updateCookie(response);
    _checkResponse(response);
  }

  String _mimeFromFilename(String filename) {
    final ext = filename.toLowerCase().split('.').last;
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'heic':
      case 'heif':
        return 'image/heic';
      case 'mp4':
        return 'video/mp4';
      default:
        return 'application/octet-stream';
    }
  }

  Future<Map<String, dynamic>> uploadFile(List<int> bytes, String filename) async {
    final uri = Uri.parse('$baseUrl/api/admin/upload');
    final request = http.MultipartRequest('POST', uri);
    if (!kIsWeb && _cookie != null) {
      request.headers['Cookie'] = _cookie!;
    }
    final mime = _mimeFromFilename(filename);
    final mediaParts = mime.split('/');
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: filename,
      contentType: http_parser.MediaType(mediaParts[0], mediaParts.length > 1 ? mediaParts[1] : 'octet-stream'),
    ));
    final streamedResponse = await _client.send(request);
    final response = await http.Response.fromStream(streamedResponse);
    _updateCookie(response);
    _checkResponse(response);
    return jsonDecode(response.body);
  }

  Future<void> deleteUpload(String url) async {
    final response = await _client.delete(
      Uri.parse('$baseUrl/api/admin/upload'),
      headers: _headers,
      body: jsonEncode({'url': url}),
    );
    _updateCookie(response);
    _checkResponse(response);
  }

  Future<List<Map<String, dynamic>>> getBanners() async {
    final response = await _client.get(Uri.parse('$baseUrl/api/admin/banners'), headers: _headers);
    _updateCookie(response);
    _checkResponse(response);
    final List data = jsonDecode(response.body);
    return data.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getPublicBanners() async {
    final response = await _client.get(Uri.parse('$baseUrl/api/banners'), headers: _headers);
    _updateCookie(response);
    _checkResponse(response);
    final List data = jsonDecode(response.body);
    return data.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> createBanner(Map<String, dynamic> data) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/admin/banners'),
      headers: _headers,
      body: jsonEncode(data),
    );
    _updateCookie(response);
    _checkResponse(response);
    return jsonDecode(response.body);
  }

  Future<void> updateBanner(int id, Map<String, dynamic> data) async {
    final response = await _client.patch(
      Uri.parse('$baseUrl/api/admin/banners/$id'),
      headers: _headers,
      body: jsonEncode(data),
    );
    _updateCookie(response);
    _checkResponse(response);
  }

  Future<void> deleteBanner(int id) async {
    final response = await _client.delete(Uri.parse('$baseUrl/api/admin/banners/$id'), headers: _headers);
    _updateCookie(response);
    _checkResponse(response);
  }

  Future<void> reorderBanners(List<Map<String, dynamic>> items) async {
    final response = await _client.patch(
      Uri.parse('$baseUrl/api/admin/banners/reorder'),
      headers: _headers,
      body: jsonEncode({'items': items}),
    );
    _updateCookie(response);
    _checkResponse(response);
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    final response = await _client.get(Uri.parse('$baseUrl/api/admin/categories'), headers: _headers);
    _updateCookie(response);
    _checkResponse(response);
    final List data = jsonDecode(response.body);
    return data.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getPublicCategories() async {
    final response = await _client.get(Uri.parse('$baseUrl/api/categories'), headers: _headers);
    _updateCookie(response);
    _checkResponse(response);
    final List data = jsonDecode(response.body);
    return data.cast<Map<String, dynamic>>();
  }

  Future<void> updateCategory(int id, Map<String, dynamic> data) async {
    final response = await _client.patch(
      Uri.parse('$baseUrl/api/admin/categories/$id'),
      headers: _headers,
      body: jsonEncode(data),
    );
    _updateCookie(response);
    _checkResponse(response);
  }

  Future<void> reorderCategories(List<Map<String, dynamic>> items) async {
    final response = await _client.patch(
      Uri.parse('$baseUrl/api/admin/categories/reorder'),
      headers: _headers,
      body: jsonEncode({'items': items}),
    );
    _updateCookie(response);
    _checkResponse(response);
  }

  Future<void> reorderProducts(List<Map<String, dynamic>> items) async {
    final response = await _client.patch(
      Uri.parse('$baseUrl/api/admin/products/reorder'),
      headers: _headers,
      body: jsonEncode({'items': items}),
    );
    _updateCookie(response);
    _checkResponse(response);
  }

  Future<void> sendNotification(String title, String message, {int? productId}) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/admin/notifications/send'),
      headers: _headers,
      body: jsonEncode({'title': title, 'message': message, 'productId': productId}),
    );
    _updateCookie(response);
    _checkResponse(response);
  }

  Future<List<Map<String, dynamic>>> getAdminNotifications() async {
    final response = await _client.get(Uri.parse('$baseUrl/api/admin/notifications'), headers: _headers);
    _updateCookie(response);
    _checkResponse(response);
    final List data = jsonDecode(response.body);
    return data.cast<Map<String, dynamic>>();
  }

  Future<void> deleteNotificationGroup(String title, String message) async {
    final request = http.Request('DELETE', Uri.parse('$baseUrl/api/admin/notifications'));
    request.headers.addAll(_headers);
    request.body = jsonEncode({'title': title, 'message': message});
    final streamed = await _client.send(request);
    final response = await http.Response.fromStream(streamed);
    _updateCookie(response);
    _checkResponse(response);
  }

  Future<Map<String, dynamic>> getCustomers({String? search, String? sort, String? hasOrders, String? hasCart, String? highSpenders, String? abandonedCart, int page = 1, int limit = 20}) async {
    final params = <String, String>{'page': '$page', 'limit': '$limit'};
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (sort != null) params['sort'] = sort;
    if (hasOrders != null) params['hasOrders'] = hasOrders;
    if (hasCart != null) params['hasCart'] = hasCart;
    if (highSpenders != null) params['highSpenders'] = highSpenders;
    if (abandonedCart != null) params['abandonedCart'] = abandonedCart;
    final uri = Uri.parse('$baseUrl/api/admin/customers').replace(queryParameters: params);
    final response = await _client.get(uri, headers: _headers);
    _updateCookie(response);
    _checkResponse(response);
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getCustomerDetail(int id) async {
    final response = await _client.get(Uri.parse('$baseUrl/api/admin/customers/$id'), headers: _headers);
    _updateCookie(response);
    _checkResponse(response);
    return jsonDecode(response.body);
  }

  String getCustomersExportUrl({String? search, String? sort, String? hasOrders, String? hasCart, String? highSpenders, String? abandonedCart}) {
    final params = <String, String>{};
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (sort != null) params['sort'] = sort;
    if (hasOrders != null) params['hasOrders'] = hasOrders;
    if (hasCart != null) params['hasCart'] = hasCart;
    if (highSpenders != null) params['highSpenders'] = highSpenders;
    if (abandonedCart != null) params['abandonedCart'] = abandonedCart;
    final uri = Uri.parse('$baseUrl/api/admin/customers/export').replace(queryParameters: params);
    return uri.toString();
  }

  String getCustomerExportUrl(int id) {
    return '$baseUrl/api/admin/customers/$id/export';
  }

  Future<List<Map<String, dynamic>>> getStaffUsers() async {
    final response = await _client.get(Uri.parse('$baseUrl/api/admin/staff'), headers: _headers);
    _updateCookie(response);
    _checkResponse(response);
    final List data = jsonDecode(response.body);
    return data.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> createStaffUser(Map<String, dynamic> data) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/admin/staff'),
      headers: _headers,
      body: jsonEncode(data),
    );
    _updateCookie(response);
    _checkResponse(response);
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> updateStaffUser(int id, Map<String, dynamic> data) async {
    final response = await _client.patch(
      Uri.parse('$baseUrl/api/admin/staff/$id'),
      headers: _headers,
      body: jsonEncode(data),
    );
    _updateCookie(response);
    _checkResponse(response);
    return jsonDecode(response.body);
  }

  Future<void> updateStaffPermissions(int id, Map<String, dynamic> permissions) async {
    final response = await _client.patch(
      Uri.parse('$baseUrl/api/admin/staff/$id/permissions'),
      headers: _headers,
      body: jsonEncode({'permissions': permissions}),
    );
    _updateCookie(response);
    _checkResponse(response);
  }

  Future<void> deleteStaffUser(int id) async {
    final response = await _client.delete(Uri.parse('$baseUrl/api/admin/staff/$id'), headers: _headers);
    _updateCookie(response);
    _checkResponse(response);
  }

  Future<Map<String, dynamic>> sendCartNotification(int customerId, {required String messageAr, String? messageEn}) async {
    final body = <String, dynamic>{'messageAr': messageAr, 'channel': 'in_app'};
    if (messageEn != null && messageEn.isNotEmpty) body['messageEn'] = messageEn;
    final response = await _client.post(
      Uri.parse('$baseUrl/api/admin/customers/$customerId/notify-cart'),
      headers: _headers,
      body: jsonEncode(body),
    );
    _updateCookie(response);
    _checkResponse(response);
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> createProductDiscount({
    required int productId,
    required String type,
    required int value,
    required String startsAt,
    required String endsAt,
    String? label,
  }) async {
    final body = <String, dynamic>{
      'productIds': [productId],
      'type': type,
      'value': value,
      'startsAt': startsAt,
      'endsAt': endsAt,
    };
    if (label != null && label.isNotEmpty) body['label'] = label;
    final response = await _client.post(
      Uri.parse('$baseUrl/api/admin/product-discounts'),
      headers: _headers,
      body: jsonEncode(body),
    );
    _updateCookie(response);
    _checkResponse(response);
    return jsonDecode(response.body);
  }

  Future<void> removeProductDiscount(int productId) async {
    final response = await _client.delete(
      Uri.parse('$baseUrl/api/admin/product-discounts'),
      headers: {..._headers},
      body: jsonEncode({'productIds': [productId]}),
    );
    _updateCookie(response);
    _checkResponse(response);
  }

  Future<List<dynamic>> listProductDiscounts() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/api/admin/product-discounts'),
      headers: _headers,
    );
    _updateCookie(response);
    _checkResponse(response);
    return jsonDecode(response.body) as List<dynamic>;
  }

  Future<Map<String, dynamic>?> getProductDiscount(int productId) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/api/admin/product-discounts/$productId'),
      headers: _headers,
    );
    _updateCookie(response);
    _checkResponse(response);
    final data = jsonDecode(response.body);
    return data;
  }
}
