import 'package:flutter/material.dart';

import '../models/product_model.dart';
import '../services/product_service.dart';

class ProductProvider with ChangeNotifier {
  List<Product> _products = [];
  bool _isLoading = false;

  List<Product> get products => _products;
  bool get isLoading => _isLoading;

  final ProductService _productService = ProductService();

  void fetchProducts() async {
    _isLoading = true;
    notifyListeners();

    try {
      List<Product> newProducts = await _productService.getProducts();
      _products = newProducts;
    } catch (error) {
      // print(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addProduct(Product product) async {
    try {
      Product newProduct = await _productService.addProduct(product);
      _products.add(newProduct);
      notifyListeners();
    } catch (error) {
      //print(error);
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
      //print(error);
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      await _productService.deleteProduct(id);
      _products.removeWhere((prod) => prod.id == id);
      notifyListeners();
    } catch (error) {
      // print(error);
    }
  }
}
