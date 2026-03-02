import 'package:flutter/material.dart';
import '../models/cart_item.dart';
import '../services/api_service.dart';

class CartProvider extends ChangeNotifier {
  final ApiService _api;
  List<CartItem> _items = [];
  bool _loading = false;
  String? _error;

  CartProvider(this._api);

  List<CartItem> get items => _items;
  bool get loading => _loading;
  String? get error => _error;
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  int get subtotal => _items.fold(0, (sum, item) => sum + (item.product?.price ?? 0) * item.quantity);

  Future<void> loadCart() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _items = await _api.getCart();
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    _loading = false;
    notifyListeners();
  }

  Future<bool> addToCart(int productId, String size, String color, {int quantity = 1}) async {
    try {
      await _api.addToCart(productId, size, color, quantity: quantity);
      await loadCart();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> updateQuantity(int id, int quantity) async {
    try {
      await _api.updateCartItem(id, quantity);
      await loadCart();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> removeItem(int id) async {
    try {
      await _api.removeCartItem(id);
      await loadCart();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> clearCart() async {
    try {
      await _api.clearCart();
      _items = [];
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
