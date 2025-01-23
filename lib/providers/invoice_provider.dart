/*import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/invoice_model.dart';
import '../models/product_model.dart';
import '../models/user_model.dart';

class InvoiceProvider with ChangeNotifier {
  final String _baseUrl = "http://34.226.208.66:3001/api/newBill";
  List<Invoice> _invoices = [];
  Invoice? _currentInvoice;
  User? _currentUser;
  List<Product> _selectedProducts = [];
  String _userName = '';
  String _userCC = '';
  double _pagaCon = 0.0;
  double _cambio = 0.0;
  String _medioPago = 'Efectivo';

  List<Invoice> get invoices => _invoices;
  Invoice? get currentInvoice => _currentInvoice;
  User? get currentUser => _currentUser;
  List<Product> get selectedProducts => _selectedProducts;
  String get userName => _userName;
  String get userCC => _userCC;
  double get pagaCon => _pagaCon;
  double get cambio => _cambio;
  String get medioPago => _medioPago;

  // Métodos para configurar usuario y sus datos
  void setUser(User user) {
    _currentUser = user;
    notifyListeners();
  }

  void setUserName(String name) {
    _userName = name;
    notifyListeners();
  }

  void setUserCC(String cc) {
    _userCC = cc;
    notifyListeners();
  }

  void setPagaCon(double amount) {
    _pagaCon = amount;
    _cambio = _pagaCon - selectedTotal;
    notifyListeners();
  }

  void setMedioPago(String medio) {
    _medioPago = medio;
    notifyListeners();
  }

  // Métodos para manejar productos seleccionados
  void addProduct(Product product) {
    if (!_selectedProducts.contains(product)) {
      _selectedProducts.add(product);
    }
    notifyListeners();
  }

  void removeProduct(Product product) {
    _selectedProducts.remove(product);
    notifyListeners();
  }

  void clearProducts() {
    _selectedProducts.clear();
    notifyListeners();
  }

  // Calcular el total de productos seleccionados
  double get selectedTotal {
    return _selectedProducts.fold(
      0.0,
      (sum, product) =>
          sum + (product.price * (product.stock)), // Basado en el stock
    );
  }

  // Crear una factura y enviarla al servidor
  Future<void> createInvoice() async {
    if (_selectedProducts.isEmpty) {
      throw Exception("No hay productos seleccionados.");
    }

    final invoiceData = {
      "userName": _userName.isEmpty ? null : _userName, // Opcional
      "userPhone": currentUser?.phone ?? '',
      "userEmail": currentUser?.email ?? '',
      "userCC": _userCC.isEmpty ? null : _userCC, // Opcional
      "userDetalles": "",
      "products": _selectedProducts
          .map((product) => {
                "product": product.id,
                "quantity": product.stock,
              })
          .toList(),
      "servicio": [],
      "impresiones": [],
      "medioPago": _medioPago,
      "cambio": _cambio,
      "pagaCon": _pagaCon,
      "totalAmount": selectedTotal,
      "consecutivo": _invoices.length + 1,
    };

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(invoiceData),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final newInvoice = Invoice.fromJson(responseData);
        _invoices.add(newInvoice);
        clearProducts();
        notifyListeners();
      } else {
        throw Exception("Error al crear la factura: ${response.body}");
      }
    } catch (error) {
      throw Exception("Error al conectar con el servidor: $error");
    }
  }
}
*/

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/product_model.dart';
import '../providers/product_provider.dart';

class InvoiceProvider with ChangeNotifier {
  final String _baseUrl = "http://34.226.208.66:3001/api/newBill";
  List<Product> _selectedProducts = [];
  String _userName = '';
  String _userCC = '';
  String _userPhone = '';
  String _userEmail = '';
  String _medioPago = 'Efectivo';
  double _pagaCon = 0.0;
  double _cambio = 0.0;

  // Getters

  List<Product> get selectedProducts => _selectedProducts;
  String get userName => _userName;
  String get userCC => _userCC;
  String get userPhone => _userPhone;
  String get userEmail => _userEmail;
  String get medioPago => _medioPago;
  double get pagaCon => _pagaCon;
  double get cambio => _cambio;

  // Métodos para configurar usuario y sus datos
  void setUserName(String name) {
    _userName = name;
    notifyListeners();
  }

  void setUserCC(String cc) {
    _userCC = cc;
    notifyListeners();
  }

  void setUserPhone(String phone) {
    _userPhone = phone;
    notifyListeners();
  }

  void setUserEmail(String email) {
    _userEmail = email;
    notifyListeners();
  }

  void setMedioPago(String medio) {
    _medioPago = medio;
    notifyListeners();
  }

  void setPagaCon(double amount) {
    _pagaCon = amount;
    _cambio = _pagaCon - selectedTotal;
    notifyListeners();
  }

  // Manejo de productos seleccionados
  void addProduct(Product product) {
    if (!_selectedProducts.contains(product)) {
      _selectedProducts.add(product);
    }
    notifyListeners();
  }

  void removeProduct(Product product) {
    _selectedProducts.remove(product);
    notifyListeners();
  }

  void clearProducts() {
    _selectedProducts.clear();
    notifyListeners();
  }

  // Calcular el total
  double get selectedTotal {
    return _selectedProducts.fold(0.0, (sum, product) {
      final quantity = ProductProvider().quantities[product] ?? 1;
      return sum + (product.price * quantity);
    });
  }

  Future<void> createInvoice() async {
    if (_selectedProducts.isEmpty) {
      throw Exception("No hay productos seleccionados.");
    }

    // Calcular el total basado en las cantidades seleccionadas
    double totalAmount = _selectedProducts.fold(0.0, (sum, product) {
      final quantity = ProductProvider().quantities[product] ?? 1;
      return sum + (product.price * quantity);
    });

    final invoiceData = {
      "name": _userName.isEmpty ? "Cliente" : _userName,
      "phone": _userPhone.isEmpty ? "No proporcionado" : _userPhone,
      "email": _userEmail.isEmpty ? "No proporcionado" : _userEmail,
      "cc": _userCC.isEmpty ? "No proporcionado" : _userCC,
      "detalles": "Esta es una compra generada por la aplicación",
      "products": _selectedProducts.map((product) {
        final quantity = ProductProvider().quantities[product] ?? 1;
        return {"productId": product.id, "quantity": quantity};
      }).toList(),
      "pagaCon": _pagaCon,
      "medioPago": _medioPago,
      "cambio": _pagaCon - totalAmount,
      "totalAmount": totalAmount.toInt(),
    };

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(invoiceData),
      );

      if (response.statusCode == 200) {
        clearAllData(); // Limpia datos en InvoiceProvider
        notifyListeners();
      } else {
        throw Exception("Error al crear la factura: ${response.body}");
      }
    } catch (error) {
      throw Exception("Error al conectar con el servidor: $error");
    }
  }

  void clearAllData() {
    _selectedProducts.clear();
    _userName = '';
    _userCC = '';
    _userPhone = '';
    _userEmail = '';
    _medioPago = 'Efectivo';
    _pagaCon = 0.0;
    _cambio = 0.0;
    ProductProvider().clearCart(); // Limpia el carrito
    notifyListeners();
  }
}
