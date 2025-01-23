import 'package:flutter/material.dart';

import '../models/product_model.dart';
import '../services/product_service.dart';

class ProductProvider with ChangeNotifier {
  List<Product> _products = [];
  List<Product> _cart = [];
  List<Product> _selectedProducts = []; // Lista de productos seleccionados
  Map<Product, int> _quantities = {};
  List<Product> _filteredProducts = [];
  bool _isLoading = false;

  List<Product> get products => _products;
  List<Product> get cart => _cart;
  List<Product> get selectedProducts => _selectedProducts;
  List<Product> get filteredProducts => _filteredProducts;
  bool get isLoading => _isLoading;
  final ProductService _productService = ProductService();

  Map<Product, int> get quantities => _quantities;

  /// Limpia todo el carrito y reinicia cantidades
  void clearCart() {
    _cart.clear();
    _selectedProducts.clear();
    _quantities.clear();
    notifyListeners();
  }

  /// Traer productos desde el servicio
  void fetchProducts() async {
    _isLoading = true;
    notifyListeners();

    try {
      List<Product> newProducts = await _productService.getProducts();
      _products = newProducts;
      _filteredProducts = _products;
    } catch (error) {
      // Handle error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void filterProducts(String query) {
    if (query.isEmpty) {
      _filteredProducts = _products;
    } else {
      _filteredProducts = _products
          .where((product) =>
              product.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
    notifyListeners();
  }

  void addToCart(Product product) {
    if (!_cart.contains(product)) {
      _cart.add(product);
      _quantities[product] = 1; // Inicializa la cantidad en 1
    }
    notifyListeners();
  }

  void removeFromCart(Product product) {
    _cart.remove(product);
    _selectedProducts.remove(product); // También lo elimina de seleccionados
    _quantities.remove(product); // También elimina la cantidad
    notifyListeners();
  }

  void selectProduct(Product product) {
    if (!_selectedProducts.contains(product)) {
      _selectedProducts.add(product);
    }
    notifyListeners();
  }

  void selectAllProducts() {
    _selectedProducts = List.from(_cart);
    notifyListeners();
  }

  void deselectAllProducts() {
    _selectedProducts.clear();
    notifyListeners();
  }

  void deselectProduct(Product product) {
    _selectedProducts.remove(product);
    notifyListeners();
  }

  Future<void> addProduct(Product product) async {
    try {
      Product newProduct = await _productService.addProduct(product);
      _products.add(newProduct);
      notifyListeners();
    } catch (error) {
      // Handle error
    }
  }

  Future<void> updateProduct(Product product) async {
    try {
      Product updatedProduct = await _productService.updateProduct(product);
      int index = _products.indexWhere((prod) => prod.id == product.id);
      if (index != -1) {
        _products[index] = updatedProduct;
        notifyListeners();
      }
    } catch (error) {
      // Handle error
    }
  }

  void updateQuantity(Product product, int quantity) {
    _quantities[product] = quantity;
    notifyListeners();
  }

  double get selectedTotal {
    return _selectedProducts.fold(0.0, (sum, product) {
      final quantity =
          _quantities[product] ?? 1; // Obtiene la cantidad o 1 por defecto
      return sum +
          (product.price *
              quantity); // Suma el total para cada producto seleccionado
    });
  }

  void removeSelectedProducts() {
    for (var product in _selectedProducts) {
      _cart.remove(product);
      _quantities.remove(product);
    }
    _selectedProducts.clear();
    notifyListeners();
  }

  Future<void> deleteProduct(String id) async {
    try {
      await _productService.deleteProduct(id);
      _products.removeWhere((prod) => prod.id == id);
      notifyListeners();
    } catch (error) {
      // Handle error
    }
  }
}
