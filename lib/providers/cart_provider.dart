import 'package:flutter/material.dart';

import '../models/cart_model.dart';
import '../services/cart_service.dart';

class CartProvider with ChangeNotifier {
  final CartService _cartService = CartService();
  Cart? _cart;

  Cart? get cart => _cart;

  Future<void> loadCart(String token) async {
    _cart = await _cartService.fetchCart(token);
    notifyListeners();
  }

  Future<void> addItem(
    String token, {
    required String productId,
    required int quantity,
    required int appliedPrice,
  }) async {
    await _cartService.addToCart(
      token,
      productId: productId,
      quantity: quantity,
      appliedPrice: appliedPrice,
    );
    await loadCart(token);
  }

  Future<void> removeItem(
    String token, {
    required String productId,
  }) async {
    await _cartService.removeFromCart(token, productId: productId);
    await loadCart(token);
  }

  Future<void> clear(String token) async {
    await _cartService.clearCart(token);
    await loadCart(token);
  }

  /// -----------------------------------------------------------------------
  /// 🚀 **updateUserCartQuantities**
  /// Reconstruye el carrito en el backend según cantidades nuevas del usuario
  /// -----------------------------------------------------------------------
  Future<void> updateUserCartQuantities(
    String token, {
    required List<CartItem> items,
  }) async {
    // 1. Limpiar carrito en backend
    await _cartService.clearCart(token);

    // 2. Agregar de nuevo cada producto con su cantidad actualizada
    for (final item in items) {
      await _cartService.addToCart(
        token,
        productId: item.product.id,
        quantity: item.quantity,
        appliedPrice: item.appliedPrice,
      );
    }

    // 3. Recargar carrito
    await loadCart(token);
  }

  void clearLocalCart() {
    _cart = Cart.empty();
    notifyListeners();
  }
}
