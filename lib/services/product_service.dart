import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' show MediaType;

import '../config/api_config.dart';
import '../models/product_model.dart';
import '../models/product_pdp_model.dart';
class ProductService {
// Para escritura (crear, actualizar, eliminar)
  static const String backendUrl = ApiConfig.baseUrl;

// Para lectura de imágenes (mostrar en la UI)
  static const String imageUrl = ApiConfig.baseUrl;

  /// Sube N imágenes en un solo PUT /products/:id y devuelve la lista completa de URLs.
  Future<List<String>> uploadProductImagesBatch(
    String productId,
    List<Uint8List> images,
    List<String> filenames,
  ) async {
    final uri = Uri.parse('$backendUrl/products/$productId');
    final req = http.MultipartRequest('PUT', uri);

    // añadimos cada imagen al mismo campo 'images'
    for (var i = 0; i < images.length; i++) {
      req.files.add(http.MultipartFile.fromBytes(
        'images',
        images[i],
        filename: filenames[i],
        contentType: MediaType('image', _extensionFrom(filenames[i])),
      ));
    }

    final streamed = await req.send();
    final resp = await http.Response.fromStream(streamed);

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final body = jsonDecode(resp.body) as Map<String, dynamic>;
      if (body['success'] == true) {
        final data = body['data'] as Map<String, dynamic>;
        return List<String>.from(data['images'] ?? []);
      }
      throw Exception(body['error'] ?? 'Error en respuesta del servidor');
    }
    throw Exception('Error al subir imágenes: ${resp.statusCode}');
  }

  /// Helper para sacar la extensión y pasar el contentType correcto
  String _extensionFrom(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'jpeg';
      case 'png':
        return 'png';
      case 'gif':
        return 'gif';
      default:
        return 'octet-stream';
    }
  }

  Future<Product> addProduct(Product product) async {
    final response = await http.post(
      Uri.parse('$backendUrl/products'),
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
    final response = await http.get(Uri.parse('$imageUrl/products'));

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
    final response = await http.get(Uri.parse('$imageUrl/products/$id'));

    if (response.statusCode == 200) {
      return Product.fromJson(jsonDecode(response.body));
    } else {
      final responseData = jsonDecode(response.body);
      throw Exception(responseData['message'] ?? 'Failed to load product');
    }
  }

  Future<Product> updateProduct(Product product) async {
    final response = await http.put(
      Uri.parse('$backendUrl/products/${product.id}'),
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
    final response = await http.delete(Uri.parse('$backendUrl/products/$id'));

    if (response.statusCode == 200) {
      return;
    } else {
      final responseData = jsonDecode(response.body);
      throw Exception(responseData['message'] ?? 'Failed to delete product');
    }
  }

  /// Borra una imagen de un producto en el servidor
  Future<Product> deleteProductImage(String productId, String imageUrl) async {
    final uri = Uri.parse('$backendUrl/products/$productId/images');
    final response = await http.delete(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'imageUrl': imageUrl}),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['success'] == true) {
        return Product.fromJson(body['data'] as Map<String, dynamic>);
      } else {
        throw Exception(body['error'] ?? 'Error borrando imagen');
      }
    } else {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }
  }

  Future<List<Product>> fetchTopSellingProducts({int limit = 20}) async {
    final uri = Uri.parse('${backendUrl}/products/top-selling?limit=$limit');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] is List) {
        return (data['data'] as List).map((e) => Product.fromJson(e)).toList();
      } else {
        throw Exception('Respuesta inválida del servidor');
      }
    } else {
      throw Exception('Error al obtener productos más vendidos');
    }
  }

  Future<List<Product>> getLeastSellingProducts({int limit = 20}) async {
    final response = await http.get(
      Uri.parse('${backendUrl}/products/least-selling?limit=$limit'),
      //Uri.parse('${backendUrl}/products/low-stock?limit=$limit'),
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final List<dynamic> data = body['data'];
      return data.map((item) => Product.fromJson(item)).toList();
    } else {
      throw Exception('Error al cargar productos menos vendidos');
    }
  }

  Future<List<Product>> fetchLeastSellingProducts({int limit = 20}) async {
    final uri = Uri.parse('$backendUrl/products/least-selling?limit=$limit');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);

      if (body['success'] == true && body['data'] is List) {
        return (body['data'] as List)
            .map((item) => Product.fromJson(item))
            .toList();
      }

      throw Exception('Respuesta inválida en productos menos vendidos');
    }

    throw Exception('Error al obtener productos menos vendidos');
  }

  Future<List<Product>> fetchNewArrivalsProducts({int limit = 100}) async {
    final uri = Uri.parse('$backendUrl/products/new-arrivals?limit=$limit');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);

      if (body['success'] == true && body['data'] is List) {
        return (body['data'] as List)
            .map((item) => Product.fromJson(item))
            .toList();
      }

      throw Exception('Respuesta inválida en productos nuevos');
    }

    throw Exception('Error al obtener productos nuevos');
  }

  Future<List<Product>> fetchHighStockProducts({int limit = 100}) async {
    final uri = Uri.parse('$backendUrl/products/high-stock?limit=$limit');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);

      if (body['success'] == true && body['data'] is List) {
        return (body['data'] as List)
            .map((item) => Product.fromJson(item))
            .toList();
      }

      throw Exception('Respuesta inválida en productos con alto stock');
    }

    throw Exception('Error al obtener productos con alto stock');
  }

  Future<List<Product>> fetchLeastStockProducts({int limit = 100}) async {
    final uri = Uri.parse('$backendUrl/products/least-stock?limit=$limit');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);

      if (body['success'] == true && body['data'] is List) {
        return (body['data'] as List)
            .map((item) => Product.fromJson(item))
            .toList();
      }

      throw Exception('Respuesta inválida en productos con menor stock');
    }

    throw Exception('Error al obtener productos con menor stock');
  }

  Future<List<Product>> fetchLowStockProducts({int limit = 100}) async {
    final uri = Uri.parse('$backendUrl/products/low-stock?limit=$limit');

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);

      if (body['success'] == true && body['data'] is List) {
        return (body['data'] as List)
            .map((item) => Product.fromJson(item))
            .toList();
      }

      throw Exception('Respuesta inválida en low stock');
    }

    throw Exception('Error al obtener productos low stock');
  }
  // =========================================================================
  // NUEVO: Obtener detalle optimizado para PDP usando el Slug del producto
  // =========================================================================
  Future<ProductPdpData> getProductDetailBySlug(String slug) async {
    final response = await http.get(Uri.parse('$backendUrl/products/pdp/$slug'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      if (responseData['success'] == true) {
        // Mapeamos usando la nueva respuesta jerárquica de conversión
        return ProductPdpResponse.fromJson(responseData).data;
      } else {
        throw Exception(responseData['message'] ?? 'Error al obtener detalles del PDP');
      }
    } else {
      throw Exception('Fallo en la comunicación con el servidor: Código ${response.statusCode}');
    }
  }
}
