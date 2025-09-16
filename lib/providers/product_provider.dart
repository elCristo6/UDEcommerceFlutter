import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/product_model.dart';
import '../providers/invoice_provider.dart';
import '../services/product_service.dart';

class ProductProvider with ChangeNotifier {
  ProductProvider() {
    fetchProducts();
    fetchTopSellingProducts();
    fetchLeastSellingProducts();
  }
  List<Product> _products = [];
  List<Product> _cart = [];
  List<Product> _selectedProducts = []; // Lista de productos seleccionados
  Map<Product, int> _quantities = {};
  Map<Product, double> _modifiedPrices = {};
  Map<Product, TextEditingController> _priceControllers =
      {}; // 🔹 Mapa para controladores

  List<Product> _filteredProducts = [];
  bool _isLoading = false;
  bool _isFiltering = false;
  bool _hasFetchedProducts = false;
  final ProductService _service = ProductService();

  List<Product> get products => _products;
  List<Product> get cart => _cart;
  List<Product> get selectedProducts => _selectedProducts;
  List<Product> get filteredProducts =>
      _isFiltering ? _filteredProducts : _products;
  bool get isLoading => _isLoading;
  final ProductService _productService = ProductService();
  Map<Product, double> get modifiedPrices => _modifiedPrices;

  Map<Product, int> get quantities => _quantities;
  List<Product> _topSellingProducts = [];
  bool _loadingTopSelling = false;

  List<Product> get topSellingProducts => _topSellingProducts;
  bool get isLoadingTopSelling => _loadingTopSelling;
  List<Product> _leastSellingProducts = [];
  bool _loadingLeastSelling = false;

  List<Product> get leastSellingProducts => _leastSellingProducts;
  bool get isLoadingLeastSelling => _loadingLeastSelling;

  Future<void> fetchLeastSellingProducts() async {
    _loadingLeastSelling = true;
    notifyListeners();
    try {
      _leastSellingProducts = await _service.getLeastSellingProducts();
    } catch (e) {
      _leastSellingProducts = [];
    }
    _loadingLeastSelling = false;
    notifyListeners();
  }

  Future<void> fetchTopSellingProducts() async {
    _loadingTopSelling = true;
    notifyListeners();
    try {
      _topSellingProducts = await _service.fetchTopSellingProducts();
    } catch (e) {
      _topSellingProducts = [];
    }
    _loadingTopSelling = false;
    notifyListeners();
  }

  /// Sube todas las imágenes de una sola vez y refresca la lista.
  Future<void> uploadProductImages(
      String productId, List<Uint8List> images) async {
    // Generamos un nombre único para cada fichero
    final filenames = List<String>.generate(
      images.length,
      (i) => 'img_${DateTime.now().millisecondsSinceEpoch}_$i.png',
    );

    // 1) enviamos un solo request multipart con todas
    await _productService.uploadProductImagesBatch(
      productId,
      images,
      filenames,
    );

    // 2) refrescamos nuestra lista en memoria
    await fetchProducts(forceUpdate: true);
  }

  /// Limpia todo el carrito y reinicia cantidades
  void clearCart() {
    _cart.clear();
    _selectedProducts.clear();
    _quantities.clear();
    notifyListeners();
  }

  void updatePrice(Product product, double newPrice) {
    _modifiedPrices[product] = newPrice; // Guarda el nuevo precio
    notifyListeners(); // Notifica a todos los widgets
  }

  double getProductPrice(Product product) {
    return _modifiedPrices[product] ?? product.price;
  }

  TextEditingController getPriceController(Product product) {
    if (!_priceControllers.containsKey(product)) {
      _priceControllers[product] =
          TextEditingController(text: getProductPrice(product).toString());
    }
    return _priceControllers[product]!;
  }

  void clearControllers() {
    _priceControllers.clear(); //  Limpia los controladores cuando sea necesario
  }

  Future<void> fetchProducts({bool forceUpdate = false}) async {
    if (_isLoading || (_hasFetchedProducts && !forceUpdate)) return;
    _isLoading = true;
    notifyListeners();

    try {
      List<Product> newProducts = await _productService.getProducts();
      _products = newProducts;

      // Actualiza la lista filtrada con los productos nuevos
      _filteredProducts = _products;
      _hasFetchedProducts = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void filterProducts(String query) {
    if (query.isEmpty) {
      _isFiltering = false;
      _filteredProducts = _products;
    } else {
      _isFiltering = true; // Activa el estado de filtro
      _filteredProducts = _products
          .where((product) =>
              product.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
    notifyListeners();
  }

  void addToCart(Product product) {
    int index = _cart.indexWhere((p) => p.id == product.id);

    if (index != -1) {
      // Si el producto ya está en el carrito, solo aumenta la cantidad
      _quantities[product] = (_quantities[product] ?? 1) + 1;
    } else {
      // Si no está en el carrito, lo agrega con cantidad 1
      _cart.add(product);
      _quantities[product] = 1;
    }
    notifyListeners(); // Notifica a la UI que hubo cambios
  }

  void clearFilter() {
    _isFiltering = false; // Limpia el estado de filtro
    _filteredProducts = _products; // Restaura la lista completa
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

  void updateQuantity(
      Product product, int newQuantity, InvoiceProvider invoiceProvider) {
    if (newQuantity > 0 && newQuantity <= product.stock) {
      _quantities[product] = newQuantity;
      notifyListeners();

      // Notificar a InvoiceProvider para actualizar el subtotal
      invoiceProvider.updateSubtotal(this);
    }
  }

  double get selectedTotal {
    return _selectedProducts.fold(0.0, (sum, product) {
      final quantity =
          _quantities[product] ?? 1; // Obtiene la cantidad o 1 por defecto
      final price = _modifiedPrices[product] ?? product.price;
      return sum + (price * quantity);
    });
  }

  void removeSelectedProducts() {
    if (_selectedProducts.isEmpty) return;

    _cart.removeWhere((product) => _selectedProducts.contains(product));
    _quantities
        .removeWhere((product, _) => _selectedProducts.contains(product));

    _selectedProducts.clear(); // Limpia la lista de seleccionados
    notifyListeners(); // Asegura que la UI se actualice
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

  /// Elimina una URL de imagen tanto en el backend como en memoria
  Future<void> deleteProductImage(String productId, String imageUrl) async {
    // 1) pide al service que la borre
    final updated = await _service.deleteProductImage(productId, imageUrl);

    // 2) actualiza la lista local
    final idx = _products.indexWhere((p) => p.id == productId);
    if (idx != -1) {
      _products[idx] = updated;
      notifyListeners();
    }
  }
}
