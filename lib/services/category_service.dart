import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/category_model.dart';

class CategoryService {
  static const String _baseUrl = 'https://api.udelectronics.com/api';

  Future<List<CategoryModel>> fetchCategories() async {
    final uri = Uri.parse('$_baseUrl/categories');

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Error al cargar categorías');
    }

    final decoded = jsonDecode(response.body);

    if (decoded['success'] != true) {
      throw Exception('Respuesta inválida del servidor');
    }

    final List data = decoded['data'] ?? [];

    return data.map((item) => CategoryModel.fromJson(item)).toList();
  }
}