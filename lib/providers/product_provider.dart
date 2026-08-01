import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/product_model.dart';
import '../models/product_pdp_model.dart';
import '../providers/invoice_provider.dart';
import '../services/product_service.dart';

class ProductProvider with ChangeNotifier {
  ProductProvider() {
    fetchProducts();
    fetchTopSellingProducts();
    fetchLeastSellingProducts();
    fetchNewArrivalsProducts();
    fetchHighStockProducts();
    fetchLeastStockProducts();
    fetchLowStockProducts();
  }
  List<Product> _products = [];
  List<Product> _cart = [];
  List<Product> _selectedProducts = []; // Lista de productos seleccionados
  Map<Product, int> _quantities = {};
  Map<Product, double> _modifiedPrices = {};
  Map<Product, TextEditingController> _priceControllers =
      {}; // 🔹 Mapa para controladores

  List<Product> _filteredProducts = [];
  List<Product> _categoryProducts = [];
  List<Product> get categoryProducts => _categoryProducts;
  bool _isLoading = false;
  String? _productsError;
  String? get productsError => _productsError;
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
  List<Product> _newArrivalsProducts = [];
  List<Product> _highStockProducts = [];
  List<Product> _leastStockProducts = [];

  bool _loadingNewArrivals = false;
  bool _loadingHighStock = false;
  bool _loadingLeastStock = false;

  List<Product> get newArrivalsProducts => _newArrivalsProducts;
  List<Product> get highStockProducts => _highStockProducts;
  List<Product> get leastStockProducts => _leastStockProducts;

  bool get isLoadingNewArrivals => _loadingNewArrivals;
  bool get isLoadingHighStock => _loadingHighStock;
  bool get isLoadingLeastStock => _loadingLeastStock;
  List<Product> _lowStockProducts = [];
  bool _loadingLowStock = false;

  List<Product> get lowStockProducts => _lowStockProducts;
  bool get isLoadingLowStock => _loadingLowStock;

// Variables de estado para la vista de detalle unificado (PDP)
  ProductPdpData? _currentPdpProduct;
  bool _isLoadingPdp = false;

  ProductPdpData? get currentPdpProduct => _currentPdpProduct;
  bool get isLoadingPdp => _isLoadingPdp;
  String? _selectedCategoryId;
String? _selectedCategoryName;
bool _isLoadingCategory = false;
String? _categoryFilterError;

String? get selectedCategoryId =>
    _selectedCategoryId;

String? get selectedCategoryName =>
    _selectedCategoryName;

bool get isLoadingCategory =>
    _isLoadingCategory;

String? get categoryFilterError =>
    _categoryFilterError;

bool get isFilteringByCategory =>
    _selectedCategoryId != null;

Future<void> filterProductsByCategory({
  required String categoryId,
  required String categoryName,
}) async {
  if (categoryId.trim().isEmpty) return;

  _selectedCategoryId = categoryId;
  _selectedCategoryName = categoryName;
  _isLoadingCategory = true;
  _categoryFilterError = null;
  _isFiltering = true;

  notifyListeners();

  try {
    final products =
        await _productService.getProductsByCategory(
      categoryId,
    );

    _categoryProducts = List<Product>.from(products);
    _filteredProducts = List<Product>.from(products);
  } catch (error, stackTrace) {
    _categoryFilterError = error.toString();
    _categoryProducts = [];
    _filteredProducts = [];

    debugPrint(
      'Error filtrando productos por categoría: $error',
    );

    debugPrintStack(
      stackTrace: stackTrace,
    );
  } finally {
    _isLoadingCategory = false;
    notifyListeners();
  }
}

void clearCategoryFilter() {
  _selectedCategoryId = null;
  _selectedCategoryName = null;
  _categoryFilterError = null;
  _isLoadingCategory = false;

  _categoryProducts = [];

  _isFiltering = false;
  _filteredProducts =
      List<Product>.from(_products);

  notifyListeners();
}
  // Método reactivo para solicitar los datos CRO del backend antes de pintar el UI
  Future<void> fetchProductDetailBySlug(String slug) async {
    _isLoadingPdp = true;
    _currentPdpProduct = null; // Limpieza previa para evitar flashes de info vieja
    notifyListeners();

    try {
      _currentPdpProduct = await _service.getProductDetailBySlug(slug);
    } catch (e) {
      debugPrint("Error cargando el PDP en Provider: $e");
      _currentPdpProduct = null;
    } finally {
      _isLoadingPdp = false;
      notifyListeners();
    }
  }

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
Future<void> fetchProducts({
  bool forceUpdate = false,
}) async {
  if (_isLoading) return;

  if (_hasFetchedProducts &&
      !forceUpdate &&
      _products.isNotEmpty) {
    return;
  }

  _isLoading = true;
  _productsError = null;
  notifyListeners();

  try {
    final newProducts =
        await _productService.getProducts();

    _products =
        List<Product>.from(newProducts);

    _filteredProducts =
        List<Product>.from(newProducts);

    _hasFetchedProducts = true;
  } catch (error, stackTrace) {
    _productsError = error.toString();

    debugPrint(
      'Error cargando productos: $error',
    );

    debugPrintStack(
      stackTrace: stackTrace,
    );

    if (_products.isEmpty) {
      _hasFetchedProducts = false;
    }
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}

void filterProducts(String query) {
  final normalizedQuery = query.trim().toLowerCase();

  // La búsqueda global elimina cualquier filtro de categoría activo.
  _selectedCategoryId = null;
  _selectedCategoryName = null;
  _categoryFilterError = null;
  _categoryProducts = [];

  if (normalizedQuery.isEmpty) {
    _isFiltering = false;
    _filteredProducts = List<Product>.from(_products);
    notifyListeners();
    return;
  }

  _isFiltering = true;

  _filteredProducts = _products.where((product) {
    final name = product.name.trim().toLowerCase();
    final description =
        product.description.trim().toLowerCase();
    final legacyCategory =
        product.category.trim().toLowerCase();

    return name.contains(normalizedQuery) ||
        description.contains(normalizedQuery) ||
        legacyCategory.contains(normalizedQuery);
  }).toList();

  notifyListeners();
}

void clearSearch() {
  _isFiltering = false;

  _selectedCategoryId = null;
  _selectedCategoryName = null;
  _categoryFilterError = null;
  _categoryProducts = [];

  _filteredProducts = List<Product>.from(_products);

  notifyListeners();
}

 void clearFilter() {
    clearSearch();
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

 Future<Product> updateProduct(
  Product product, {
  List<Uint8List> newImages = const [],
}) async {
  try {
    final updatedProduct =
        await _productService.updateProduct(
      product,
      newImages: newImages,
    );

    final index = _products.indexWhere(
      (item) => item.id == updatedProduct.id,
    );

    if (index >= 0) {
      _products[index] = updatedProduct;
    } else {
      _products.add(updatedProduct);
    }

    _filteredProducts =
        List<Product>.from(_products);

    notifyListeners();

    return updatedProduct;
  } catch (error) {
    debugPrint(
      'Error actualizando producto: $error',
    );

    rethrow;
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
Future<void> deleteProduct(
  String id,
) async {
  try {
    await _productService.deleteProduct(id);

    _products.removeWhere(
      (product) => product.id == id,
    );

    _filteredProducts.removeWhere(
      (product) => product.id == id,
    );

    _categoryProducts.removeWhere(
      (product) => product.id == id,
    );

    notifyListeners();
  } catch (error) {
    debugPrint(
      'Error eliminando producto: $error',
    );

    rethrow;
  }
}

  Future<Product> deleteProductImage(
  String productId,
  String imageUrl,
) async {
  try {
    final updated =
        await _productService.deleteProductImage(
      productId,
      imageUrl,
    );

    final index = _products.indexWhere(
      (product) => product.id == productId,
    );

    if (index >= 0) {
      _products[index] = updated;
    }

    final filteredIndex =
        _filteredProducts.indexWhere(
      (product) => product.id == productId,
    );

    if (filteredIndex >= 0) {
      _filteredProducts[filteredIndex] =
          updated;
    }

    notifyListeners();

    return updated;
  } catch (error) {
    debugPrint(
      'Error eliminando imagen: $error',
    );

    rethrow;
  }
}

  Future<void> fetchNewArrivalsProducts({int limit = 100}) async {
    _loadingNewArrivals = true;
    notifyListeners();

    try {
      _newArrivalsProducts =
          await _service.fetchNewArrivalsProducts(limit: limit);
    } catch (e) {
      _newArrivalsProducts = [];
    }

    _loadingNewArrivals = false;
    notifyListeners();
  }

  Future<void> fetchHighStockProducts({int limit = 100}) async {
    _loadingHighStock = true;
    notifyListeners();

    try {
      _highStockProducts = await _service.fetchHighStockProducts(limit: limit);
    } catch (e) {
      _highStockProducts = [];
    }

    _loadingHighStock = false;
    notifyListeners();
  }

  Future<void> fetchLeastStockProducts({int limit = 100}) async {
    _loadingLeastStock = true;
    notifyListeners();

    try {
      _leastStockProducts =
          await _service.fetchLeastStockProducts(limit: limit);
    } catch (e) {
      _leastStockProducts = [];
    }

    _loadingLeastStock = false;
    notifyListeners();
  }

  Future<void> fetchInventoryDashboard() async {
    await Future.wait([
      fetchProducts(forceUpdate: true),
      fetchTopSellingProducts(),
      fetchLeastSellingProducts(),
      fetchNewArrivalsProducts(),
      fetchHighStockProducts(),
      fetchLeastStockProducts(),
      fetchLowStockProducts(),
    ]);
  }

  Future<void> fetchLowStockProducts({int limit = 100}) async {
    _loadingLowStock = true;
    notifyListeners();

    try {
      _lowStockProducts = await _service.fetchLowStockProducts(limit: limit);
    } catch (e) {
      _lowStockProducts = [];
    }

    _loadingLowStock = false;
    notifyListeners();
  }
}
