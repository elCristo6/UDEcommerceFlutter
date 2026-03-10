import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ud_store_flutter_app/main.dart';
import 'package:ud_store_flutter_app/providers/cart_provider.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _user;
  String? _token;
  String? _role;
  bool _isLoading = false;

  User? get user => _user;
  String? get token => _token;
  String? get role => _role;
  bool get isLoading => _isLoading;

  AuthProvider() {
    _loadUserFromPrefs(); // Cargar sesión al iniciar
  }

  Future<bool> login(String emailOrPhone, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _authService.login(emailOrPhone, password);
      _user = result['user'];
      _token = result['token'];
      _role = result['role'];

      await _saveToPrefs();
      // Cargar la cesta desde el backend
      final cartProvider = Provider.of<CartProvider>(
        navigatorKey.currentContext!,
        listen: false,
      );
      if (role == 'admin') {
        await cartProvider.initGuest(); // fuerza local
        // IMPORTANTE: NO llamar mergeGuestIntoAuth, NO llamar initAuth
      } else {
        await cartProvider.mergeGuestIntoAuth(_token!);
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  void logout() async {
    _user = null;
    _token = null;
    _role = null;

    // 🔥 Limpiar carrito al cerrar sesión
    final cartProvider = Provider.of<CartProvider>(
      navigatorKey.currentContext!,
      listen: false,
    );
    cartProvider.clearLocalCart();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
    await prefs.remove('token');
    await prefs.remove('role');

    notifyListeners();
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('user', jsonEncode(_user!.toJson()));
    prefs.setString('token', _token!);
    prefs.setString('role', _role!);
  }

  Future<void> _loadUserFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString('user');
    final token = prefs.getString('token');
    final role = prefs.getString('role');

    if (userString != null && token != null) {
      _user = User.fromJson(jsonDecode(userString));
      _token = token;
      _role = role;

      // Cargar la cesta al restaurar sesión
      final cartProvider = Provider.of<CartProvider>(
        navigatorKey.currentContext!,
        listen: false,
      );
      await cartProvider.loadCart(_token!);
      notifyListeners();
    }
  }
}
