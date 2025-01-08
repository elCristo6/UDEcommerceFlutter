import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/product_model.dart';

class ProductService {
  static const String baseUrl = ApiConfig.baseUrl;

  Future<Product> addProduct(Product product) async {
    final response = await http.post(
      Uri.parse('$baseUrl/products'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(product.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Product.fromJson(jsonDecode(response.body));
    } else {
      final responseData = jsonDecode(response.body);
      throw Exception(responseData['message'] ?? 'Failed to add product');
    }
  }

  Future<List<Product>> getProducts() async {
    final response = await http.get(Uri.parse('$baseUrl/products'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      if (responseData['success'] == true) {
        List<dynamic> data = responseData['data'];
        return data.map((dynamic item) => Product.fromJson(item)).toList();
      } else {
        throw Exception(responseData['message'] ?? 'Failed to load products');
      }
    } else {
      throw Exception('Failed to load products');
    }
  }

  Future<Product> getProductById(String id) async {
    final response = await http.get(Uri.parse('$baseUrl/products/$id'));

    if (response.statusCode == 200) {
      return Product.fromJson(jsonDecode(response.body));
    } else {
      final responseData = jsonDecode(response.body);
      throw Exception(responseData['message'] ?? 'Failed to load product');
    }
  }

  Future<Product> updateProduct(Product product) async {
    final response = await http.put(
      Uri.parse('$baseUrl/products/${product.id}'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(product.toJson()),
    );

    if (response.statusCode == 200) {
      return Product.fromJson(jsonDecode(response.body));
    } else {
      final responseData = jsonDecode(response.body);
      throw Exception(responseData['message'] ?? 'Failed to update product');
    }
  }

  Future<void> deleteProduct(String id) async {
    final response = await http.delete(Uri.parse('$baseUrl/products/$id'));

    if (response.statusCode == 200) {
      return;
    } else {
      final responseData = jsonDecode(response.body);
      throw Exception(responseData['message'] ?? 'Failed to delete product');
    }
  }
}
