import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api;
  Map<String, dynamic>? _currentUser;
  bool _loading = false;

  AuthProvider(this._api);

  Map<String, dynamic>? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?['role'] == 'admin';
  bool get loading => _loading;
  String get userName => _currentUser?['name'] ?? '';
  String get userEmail => _currentUser?['email'] ?? '';

  Future<void> checkAuth() async {
    try {
      _loading = true;
      notifyListeners();
      final user = await _api.getMe();
      _currentUser = user;
    } catch (_) {
      _currentUser = null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<String?> login(String email, String password) async {
    try {
      _loading = true;
      notifyListeners();
      final user = await _api.login(email, password);
      _currentUser = user;
      notifyListeners();
      return null;
    } catch (e) {
      _loading = false;
      notifyListeners();
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  Future<String?> register(String email, String password, String name, String? phone) async {
    try {
      _loading = true;
      notifyListeners();
      final user = await _api.register(email, password, name, phone);
      _currentUser = user;
      notifyListeners();
      return null;
    } catch (e) {
      _loading = false;
      notifyListeners();
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  Future<void> logout() async {
    try {
      await _api.logout();
    } catch (_) {}
    _currentUser = null;
    notifyListeners();
  }
}
