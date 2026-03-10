import 'package:flutter/material.dart';

import '../models/cart_model.dart';
import '../models/local_cart_item_model.dart';
import '../models/product_model.dart';
import '../services/cart_service.dart';
import '../services/local_cart_storage.dart';

enum CartMode { guest, auth }

class CartProvider with ChangeNotifier {
  final CartService _cartService = CartService();
  final LocalCartStorage _localStorage = LocalCartStorage();
  bool _shouldUseRemoteCart({required String? token, required String? role}) {
    final hasToken = token != null && token.isNotEmpty;
    if (!hasToken) return false; // guest => local
    if (role == 'admin') return false; // admin => local
    return true; // user auth => remoto
  }

  // ========= Estado =========
  CartMode _mode = CartMode.guest;
  CartMode get mode => _mode;

  Cart? _cart; // remoto
  Cart? get cart => _cart;

  final Map<String, LocalCartItem> _localItems = {};
  List<LocalCartItem> get localItems => _localItems.values.toList();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // ===================== SELECCIÓN UNIFICADA (guest + auth) =====================
  final Set<String> _selectedIds = {};
  Set<String> get selectedIds => _selectedIds;

  bool isSelected(String productId) => _selectedIds.contains(productId);

  /// Si no hay nada seleccionado, asumimos "todo seleccionado" para el resumen.
  /// Cambia a false si quieres obligar a seleccionar.
  bool get assumeAllIfNoneSelected => false;
  // ===================== PRECIO EFECTIVO (REGLA CORRECTA) =====================
// Siempre usa product.price (precio real).
// Solo usa appliedPrice cuando es un override REAL (distinto al precio real).

  double _effectiveUnitPrice(CartItem it) {
    // Si appliedPrice viene > 0, se toma como el precio efectivo.
    // Si viene 0 o null/indefinido, se usa el precio real del producto.
    return (it.appliedPrice > 0)
        ? it.appliedPrice.toDouble()
        : it.product.price;
  }

  // ========= Computados para UI (UNIFICADOS) =========

  /// Total de unidades (suma de cantidades) - modo actual
  int get totalItems {
    if (_mode == CartMode.auth) {
      return _cart?.items.fold<int>(0, (s, it) => s + it.quantity) ?? 0;
    }
    return _localItems.values.fold<int>(0, (s, it) => s + it.quantity);
  }

  /// Total del carrito completo (no “selección”) - modo actual
  double get totalPrice {
    if (_mode == CartMode.auth) {
      return _cart?.items.fold<double>(
            0.0,
            (s, it) => s + (_effectiveUnitPrice(it) * it.quantity),
          ) ??
          0.0;
    }
    return _localItems.values.fold<double>(
      0.0,
      (s, it) => s + (it.price * it.quantity),
    );
  }

  // ===================== UI UNIFICADA =====================
  // Para que la UI (/cesta, resumen) no tenga que saber si es guest o auth.

  List<LocalCartItem> get uiItems {
    if (_mode == CartMode.auth) {
      final items = _cart?.items ?? [];
      return items.map((it) {
        final img = it.product.images.isNotEmpty ? it.product.images.first : '';
        final price = _effectiveUnitPrice(it);
        return LocalCartItem(
          productId: it.product.id,
          name: it.product.name,
          price: price,
          image: img,
          quantity: it.quantity,
        );
      }).toList();
    }
    return localItems;
  }

  /// Total de líneas (productos distintos)
  int get uiLinesCount => uiItems.length;

  /// Total de unidades (suma de cantidades)
  int get uiUnitsCount => uiItems.fold<int>(0, (s, it) => s + it.quantity);

  /// Subtotal total (sin selección)
  double get uiSubtotal => uiItems.fold<double>(
      0.0, (s, it) => s + (it.effectivePrice * it.quantity));

  // ===================== SELECCIÓN -> COMPUTADOS =====================

  /// Items seleccionados (unificado). Si no hay selección y assumeAllIfNoneSelected=true,
  /// se toma todo el carrito.
  List<LocalCartItem> get selectedUiItems {
    final items = uiItems;

    // Si no hay selección, NO hay nada para checkout => vacío.
    if (_selectedIds.isEmpty) return [];

    return items.where((it) => _selectedIds.contains(it.productId)).toList();
  }

  Future<void> setLocalAppliedPrice(String productId, double applied) async {
    final it = _localItems[productId];
    if (it == null) return;

    _localItems[productId] = it.copyWith(appliedPrice: applied);
    await _persistLocal();
    notifyListeners();
  }

  Future<void> clearLocalAppliedPrice(String productId) async {
    final it = _localItems[productId];
    if (it == null) return;

    _localItems[productId] = it.copyWith(clearAppliedPrice: true);
    await _persistLocal();
    notifyListeners();
  }

  /// Subtotal solo de seleccionados (esto alimenta CartSummary)
  double get selectedSubtotal {
    if (_selectedIds.isEmpty) return 0.0;
    return selectedUiItems.fold<double>(
      0.0,
      (s, it) => s + (it.effectivePrice * it.quantity),
    );
  }

  int get selectedUnits =>
      selectedUiItems.fold<int>(0, (s, it) => s + it.quantity);

  bool get allSelected {
    final items = uiItems; // tu lista unificada (guest + auth)
    if (items.isEmpty) return false;
    // Si no hay selección, NO es "todo seleccionado"
    if (_selectedIds.isEmpty) return false;
    // Solo true cuando está seleccionado cada item del carrito
    return _selectedIds.length == items.length;
  }

  void toggleSelection(String productId, bool selected) {
    if (selected) {
      _selectedIds.add(productId);
    } else {
      _selectedIds.remove(productId);
    }
    notifyListeners();
  }

  void selectAll() {
    _selectedIds
      ..clear()
      ..addAll(uiItems.map((e) => e.productId));
    notifyListeners();
  }

  void clearSelection() {
    _selectedIds.clear();
    notifyListeners();
  }

  /// Limpia selección de IDs que ya no existan en el carrito
  void _sanitizeSelection() {
    final valid = uiItems.map((e) => e.productId).toSet();
    _selectedIds.removeWhere((id) => !valid.contains(id));
  }

  // ========= Inicialización =========

  /// Llamar al iniciar la app (modo guest). Carga carrito local.
  Future<void> initGuest() async {
    _mode = CartMode.guest;
    _isLoading = true;
    notifyListeners();

    final items = await _localStorage.read();
    _localItems.clear();
    for (final it in items) {
      _localItems[it.productId] = it;
    }

    _sanitizeSelection();

    _isLoading = false;
    notifyListeners();
  }

  /// Llamar cuando ya hay token (modo auth). Carga carrito remoto.
  Future<void> initAuth(String token) async {
    _mode = CartMode.auth;
    await loadCart(token);
  }

  // ========= Remoto (TU CÓDIGO ACTUAL) =========

  Future<void> loadCart(String token) async {
    _isLoading = true;
    notifyListeners();
    try {
      _cart = await _cartService.fetchCart(token);
      _sanitizeSelection();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
    // loadCart ya sanea selección
  }

  Future<void> clearRemote(String token) async {
    await _cartService.clearCart(token);
    await loadCart(token);
    // loadCart ya sanea selección
  }

  /// Reconstruye carrito remoto según cantidades nuevas del usuario
  Future<void> updateUserCartQuantities(
    String token, {
    required List<CartItem> items,
  }) async {
    await _cartService.clearCart(token);

    for (final item in items) {
      await _cartService.addToCart(
        token,
        productId: item.product.id,
        quantity: item.quantity,
        appliedPrice: item.appliedPrice,
      );
    }

    await loadCart(token);
  }

  // ========= Local =========

  Future<void> _persistLocal() async {
    await _localStorage.write(localItems);
  }

  Future<void> addLocal(Product product, {int quantity = 1}) async {
    final id = product.id;
    final img = product.images.isNotEmpty ? product.images.first : '';

    if (_localItems.containsKey(id)) {
      _localItems[id]!.quantity += quantity;
    } else {
      _localItems[id] = LocalCartItem(
        productId: id,
        name: product.name,
        price: product.price,
        image: img,
        quantity: quantity,
      );
    }

    await _persistLocal();
    _sanitizeSelection();
    notifyListeners();
  }

  Future<void> removeLocal(String productId) async {
    _localItems.remove(productId);
    await _persistLocal();
    _sanitizeSelection();
    notifyListeners();
  }

  Future<void> clearLocal() async {
    _localItems.clear();
    await _localStorage.clear();
    _sanitizeSelection();
    notifyListeners();
  }

  Future<void> increaseLocal(String productId) async {
    final it = _localItems[productId];
    if (it == null) return;
    it.quantity += 1;
    await _persistLocal();
    // no hace falta sanear, pero no hace daño
    _sanitizeSelection();
    notifyListeners();
  }

  Future<void> decreaseLocal(String productId) async {
    final it = _localItems[productId];
    if (it == null) return;

    it.quantity -= 1;
    if (it.quantity <= 0) {
      _localItems.remove(productId);
    }

    await _persistLocal();
    _sanitizeSelection();
    notifyListeners();
  }

  Future<void> setLocalQuantity(String productId, int quantity) async {
    final it = _localItems[productId];
    if (it == null) return;

    if (quantity <= 0) {
      _localItems.remove(productId);
    } else {
      it.quantity = quantity;
    }

    await _persistLocal();
    _sanitizeSelection();
    notifyListeners();
  }

  // ========= API ÚNICA PARA LA UI =========

  /// La UI llama esto sin preocuparse por auth/guest.
  /// - Si token != null: remoto
  /// - Si token == null: local
  Future<void> addProduct(
    Product product, {
    int quantity = 1,
    String? token,
    String? role, // 👈 NUEVO
    int? appliedPrice,
  }) async {
    final useRemote = _shouldUseRemoteCart(token: token, role: role);

    if (useRemote) {
      _mode = CartMode.auth;
      await addItem(
        token!,
        productId: product.id,
        quantity: quantity,
        appliedPrice: appliedPrice ?? 0,
      );
      return;
    }

    // local para guest o admin
    _mode = CartMode.guest;
    await addLocal(product, quantity: quantity);
  }

  /// Limpia el carrito dependiendo del modo / token
  Future<void> clear({String? token, String? role}) async {
    clearSelection(); // importante: al limpiar, resetea selección

    final useRemote = _shouldUseRemoteCart(token: token, role: role);

    if (useRemote) {
      _mode = CartMode.auth;
      await clearRemote(token!);
    } else {
      _mode = CartMode.guest;
      await clearLocal();
    }
  }

  /// ========= Merge guest -> auth al loguear =========
  /// Llamar una sola vez justo después del login exitoso.
  Future<void> mergeGuestIntoAuth(String token) async {
    if (_localItems.isEmpty) {
      await initAuth(token);
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      // 1) Por cada item local, lo subimos al backend
      for (final it in _localItems.values) {
        await _cartService.addToCart(
          token,
          productId: it.productId,
          quantity: it.quantity,
          appliedPrice: 0,
        );
      }

      // 2) Recargamos remoto
      _cart = await _cartService.fetchCart(token);

      // 3) Limpiamos local
      _localItems.clear();
      await _localStorage.clear();

      // 4) Cambiamos modo
      _mode = CartMode.auth;

      _sanitizeSelection();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Compatibilidad con tu método existente (puedes eliminarlo luego)
  void clearLocalCart() {
    _cart = Cart.empty();
    _sanitizeSelection();
    notifyListeners();
  }

  // En CartProvider (al final)
  void sanitizeSelection() {
    _sanitizeSelection();
    notifyListeners();
  }
}
