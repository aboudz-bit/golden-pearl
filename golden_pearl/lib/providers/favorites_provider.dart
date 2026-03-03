import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';
import '../services/api_service.dart';

class FavoritesProvider extends ChangeNotifier {
  final ApiService _api;
  Set<int> _favoriteIds = {};
  List<Product> _favoriteProducts = [];
  bool _loaded = false;

  FavoritesProvider(this._api);

  Set<int> get favoriteIds => _favoriteIds;
  List<Product> get favoriteProducts => _favoriteProducts;
  bool get loaded => _loaded;

  bool isFavorite(int productId) => _favoriteIds.contains(productId);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList('favorites') ?? [];
    _favoriteIds = ids.map((e) => int.tryParse(e)).whereType<int>().toSet();
    _loaded = true;
    notifyListeners();
    await _loadProducts();
  }

  Future<void> toggleFavorite(int productId) async {
    if (_favoriteIds.contains(productId)) {
      _favoriteIds.remove(productId);
      _favoriteProducts.removeWhere((p) => p.id == productId);
    } else {
      _favoriteIds.add(productId);
      try {
        final product = await _api.getProduct(productId);
        _favoriteProducts.add(product);
      } catch (_) {}
    }
    notifyListeners();
    await _save();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorites', _favoriteIds.map((e) => e.toString()).toList());
  }

  Future<void> _loadProducts() async {
    final products = <Product>[];
    for (final id in _favoriteIds) {
      try {
        final product = await _api.getProduct(id);
        products.add(product);
      } catch (_) {}
    }
    _favoriteProducts = products;
    notifyListeners();
  }
}
