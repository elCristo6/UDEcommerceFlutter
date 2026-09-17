import 'package:flutter/material.dart';

import '../models/category_model.dart';
import '../services/category_service.dart';

class CategoryProvider extends ChangeNotifier {
  final CategoryService _categoryService = CategoryService();

  List<CategoryModel> _categories = [];
  bool _isLoading = false;
  String? _error;

  List<CategoryModel> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // LEER
  Future<void> fetchCategories() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _categories = await _categoryService.fetchCategories();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // CREAR
  Future<bool> createCategory(String token, {required String name, required String description}) async {
    try {
      final success = await _categoryService.createCategory(token, name: name, description: description);
      if (success) {
        await fetchCategories(); // Recarga la lista para traer el ID real generado en Mongo
      }
      return success;
    } catch (e) {
      debugPrint("Error creando categoría: $e");
      return false;
    }
  }

  // ACTUALIZAR
  Future<bool> updateCategory(String token, String id, {required String name, required String description}) async {
    try {
      final success = await _categoryService.updateCategory(token, id, name: name, description: description);
      if (success) {
        await fetchCategories(); // Refresca los cambios en la UI
      }
      return success;
    } catch (e) {
      debugPrint("Error actualizando categoría: $e");
      return false;
    }
  }

  // ELIMINAR
  Future<bool> deleteCategory(String token, String id) async {
    try {
      final success = await _categoryService.deleteCategory(token, id);
      if (success) {
        _categories.removeWhere((c) => c.id == id);
        notifyListeners(); // Actualiza el sidebar instantáneamente
      }
      return success;
    } catch (e) {
      debugPrint("Error eliminando categoría: $e");
      return false;
    }
  }
}