import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/cart_model.dart';

class CartService {
  Future<Cart?> fetchCart(String token) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/cart'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return Cart.fromJson(jsonDecode(response.body));
    } else {
      return null;
    }
  }

  Future<void> addToCart(String token,
      {required String productId,
      required int quantity,
      required int appliedPrice}) async {
    await http.post(
      Uri.parse('${ApiConfig.baseUrl}/cart/add'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'productId': productId,
        'quantity': quantity,
        'appliedPrice': appliedPrice,
      }),
    );
  }

  Future<void> removeFromCart(
    String token, {
    required String productId,
  }) async {
    await http.post(
      Uri.parse('${ApiConfig.baseUrl}/cart/remove'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'productId': productId,
      }),
    );
  }

  Future<void> clearCart(String token) async {
    await http.post(
      Uri.parse('${ApiConfig.baseUrl}/cart/clear'),
      headers: {'Authorization': 'Bearer $token'},
    );
  }
}
