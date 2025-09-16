// lib/services/invoice_service.dart

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class InvoiceService {
  /// Llama a GET /newBill/next-consecutivo
  Future<int> fetchNextConsecutive() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/newBill/next-consecutivo');
    final resp = await http.get(uri, headers: {
      'Cache-Control': 'no-cache',
    });

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final body = jsonDecode(resp.body) as Map<String, dynamic>;
      // El servidor te devuelve { "nextFactura": 4528 }
      return (body['nextFactura'] as num).toInt();
    }

    throw Exception('Error al obtener consecutivo: ${resp.statusCode}');
  }
}
