// loan_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/loan_model.dart';

class LoanService {
  final String baseUrl;

  LoanService({required this.baseUrl});

  Map<String, String> _headers(String token) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }
  
  Future<bool> updateItemPrice(String token, {
    required String loanId,
    required String itemId,
    required double newPrice,
  }) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/loans/update-item-price'),
      headers: _headers(token),
      body: jsonEncode({
        'loanId': loanId,
        'itemId': itemId,
        'newPrice': newPrice,
      }),
    );
    return response.statusCode == 200;
  }

  Future<List<LoanClient>> getStoreClients(String token) async {
    final response = await http.get(Uri.parse('$baseUrl/users/stores'), headers: _headers(token));
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final List<dynamic> data = (decoded is Map && decoded.containsKey('data'))
          ? decoded['data']
          : (decoded is List ? decoded : []);
      return data.map((item) => LoanClient.fromJson(item)).toList();
    }
    throw Exception('Error al obtener locales comerciales');
  }

  Future<bool> createLoanBatch(String token, {
    required String clientId,
    required List<Map<String, dynamic>> items,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/loans/add-items'),
      headers: _headers(token),
      body: jsonEncode({'clientId': clientId, 'items': items}),
    );
    return response.statusCode == 200 || response.statusCode == 201;
  }

  Future<bool> returnItem(String token, {
    required String loanId,
    required String itemId,
    required int qty,
  }) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/loans/return-item'),
      headers: _headers(token),
      body: jsonEncode({'loanId': loanId, 'itemId': itemId, 'qty': qty}),
    );
    return response.statusCode == 200;
  }

  Future<List<LoanModel>> getActiveLoans(String token) async {
    final response = await http.get(Uri.parse('$baseUrl/loans/active-all'), headers: _headers(token));
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final List<dynamic> data = decoded['data'] ?? [];
      return data.map((item) => LoanModel.fromJson(item)).toList();
    }
    throw Exception('Error al obtener préstamos activos');
  }

  // ✅ LIMPIO Y DIRECTO: Ya no pide customItems, el backend lo resuelve solo.
  Future<bool> finalizeLoan(String token, {
    required String loanId,
    required String medioPago,
    required double pagaCon,
    required List<String> selectedItemIds,
  }) async {
    final Map<String, dynamic> body = {
      'medioPago': medioPago,
      'pagaCon': pagaCon,
      'selectedItemIds': selectedItemIds,
    };

    final response = await http.post(
      Uri.parse('$baseUrl/loans/finalize/$loanId'),
      headers: _headers(token),
      body: jsonEncode(body),
    );
    
    return response.statusCode == 200 || response.statusCode == 201;
  }

// 6. Registrar un nuevo Cliente/Local con rol 'store' (POST /api/users/register)
  Future<bool> createStore(String token, {
    required String name,
    required String phone,
    required String detalles,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/users/register');
      final bodyData = {
        'name': name,
        'phone': phone,
        'detalles': detalles,
        'role': 'store',
        'email': '$phone@udelectronics.com',
        'password': phone,
        'nit': detalles,
      };

      // 🔥 ESPIAMOS QUÉ ESTÁ HACIENDO FLUTTER 🔥
      print('--- DEBUG FLUTTER POST ---');
      print('URL destino: $url');
      print('Cuerpo JSON: ${jsonEncode(bodyData)}');
      print('--------------------------');

      final response = await http.post(
        url,
        headers: _headers(token),
        body: jsonEncode(bodyData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        print('❌ Error del backend: ${response.statusCode}');
        print('❌ Detalle: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Excepción de red en Flutter: $e');
      return false;
    }
  }

// Eliminar un Local por ID
  Future<bool> deleteStore(String token, String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/users/id/$id'),
        headers: _headers(token),
      );
      
      if (response.statusCode == 200) {
        return true; 
      } else if (response.statusCode == 404) {
        // ✅ MEJORA: Si ya no existe en la BD, le decimos a Flutter que lo quite de la pantalla igual
        print('⚠️ El local ya había sido eliminado de la base de datos.');
        return true; 
      } else {
        print('❌ Error al eliminar local: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Excepción al eliminar local: $e');
      return false;
    }
  }
}