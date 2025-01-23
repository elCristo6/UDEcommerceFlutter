/*import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/invoice_model.dart';

class InvoiceService {
  final String _baseUrl = 'http://34.226.208.66:3001/api/newBill';

  // Crear una nueva factura
  Future<Invoice> createInvoice(Invoice invoice) async {
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(invoice.toJson()),
    );

    if (response.statusCode == 201) {
      return Invoice.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Error al crear la factura');
    }
  }

  // Obtener todas las facturas
  Future<List<Invoice>> getInvoices() async {
    final response = await http.get(Uri.parse(_baseUrl));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Invoice.fromJson(json)).toList();
    } else {
      throw Exception('Error al obtener las facturas');
    }
  }
}
*/
