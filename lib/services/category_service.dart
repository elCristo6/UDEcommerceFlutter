import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/category_model.dart';

class CategoryService {
  final String _baseUrl = ApiConfig.baseUrl;

  Map<String, String> _headers(String token) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // 1. LEER TODAS (GET /api/categories)
  Future<List<CategoryModel>> fetchCategories() async {
    final uri = Uri.parse('$_baseUrl/categories');
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Error al cargar categorías');
    }

    final decoded = jsonDecode(response.body);

    // Ajusta la validación de 'success' según cómo lo envíe tu backend (algunos devuelven la lista directa)
    final List data = (decoded is Map && decoded.containsKey('data')) 
        ? decoded['data'] 
        : (decoded is List ? decoded : []);

    return data.map((item) => CategoryModel.fromJson(item)).toList();
  }

  // 2. CREAR CATEGORÍA (POST /api/categories)
  Future<bool> createCategory(String token, {required String name, required String description}) async {
    final uri = Uri.parse('$_baseUrl/categories');
    final response = await http.post(
      uri,
      headers: _headers(token),
      body: jsonEncode({
        'name': name,
        'description': description,
      }),
    );
    
    return response.statusCode == 200 || response.statusCode == 201;
  }

  // 3. ACTUALIZAR CATEGORÍA (PUT /api/categories/:id)
  Future<bool> updateCategory(String token, String id, {required String name, required String description}) async {
    final uri = Uri.parse('$_baseUrl/categories/$id');
    final response = await http.put(
      uri,
      headers: _headers(token),
      body: jsonEncode({
        'name': name,
        'description': description,
      }),
    );

    return response.statusCode == 200;
  }

  // 4. ELIMINAR CATEGORÍA (DELETE /api/categories/:id)
  Future<bool> deleteCategory(String token, String id) async {
    final uri = Uri.parse('$_baseUrl/categories/$id');
    final response = await http.delete(
      uri,
      headers: _headers(token),
    );

    // Permitimos 404 como éxito visual si la categoría ya fue eliminada por otro lado
    return response.statusCode == 200 || response.statusCode == 404;
  }
}