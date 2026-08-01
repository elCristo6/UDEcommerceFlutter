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
  }) async {
    final Map<String, dynamic> body = {
      'medioPago': medioPago,
      'pagaCon': pagaCon,
    };

    final response = await http.post(
      Uri.parse('$baseUrl/loans/finalize/$loanId'),
      headers: _headers(token),
      body: jsonEncode(body),
    );
    
    return response.statusCode == 200 || response.statusCode == 201;
  }
}