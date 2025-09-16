import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../config/api_config.dart';
import '../models/invoice_model.dart'; // Modelo de factura
import '../models/product_model.dart';
import '../models/user_model.dart'; // Modelo de usuario
import '../providers/product_provider.dart'; // Proveedor de productos
import '../services/invoice_service.dart';
import '../services/pdfService.dart';

class InvoiceProvider with ChangeNotifier {
  final String _baseUrl = "${ApiConfig.baseUrl}/newBill";
  final InvoiceService _invoiceService = InvoiceService();

  // ================== CAMPOS ==================
  User? _currentUser;
  String _medioPago = 'Efectivo';
  double _pagaCon = 0.0;
  double _cambio = 0.0;

  // Lista para almacenar facturas creadas (opcional)
  final List<Invoice> _invoices = [];
  List<Invoice> _todaysSales = [];

  // ================== GETTERS ==================
  User? get currentUser => _currentUser;
  String get medioPago => _medioPago;
  double get pagaCon => _pagaCon;
  double get cambio => _cambio;
  List<Invoice> get invoices => _invoices;
  List<Invoice> get todaysSales => _todaysSales;

  // ================== SETTERS ==================
  void setCurrentUser(User user) {
    _currentUser = user;
    notifyListeners();
  }

  void setMedioPago(String medio) {
    _medioPago = medio;
    notifyListeners();
  }

  void setPagaCon(double amount, BuildContext context) {
    final productProvider =
        Provider.of<ProductProvider>(context, listen: false);
    _pagaCon = amount;
    _cambio = _pagaCon - selectedTotal(productProvider);
    notifyListeners();
  }

  // ================== MÉTODOS AUXILIARES ==================
  /// Calcula el total basándose en los productos seleccionados y sus precios/cantidades.
  double selectedTotal(ProductProvider productProvider) {
    return productProvider.selectedProducts.fold(0.0, (sum, product) {
      final quantity = productProvider.quantities[product] ?? 1;
      final price = productProvider.modifiedPrices[product] ?? product.price;
      return sum + (price * quantity);
    });
  }

  /// Notifica cambios de subtotal para actualizar la UI
  void updateSubtotal(ProductProvider productProvider) {
    notifyListeners();
  }

  // ================== FACTURA LOCAL (SIN SERVIDOR) ==================
  /// Construye un objeto Invoice en local con todos los datos que el usuario ingresó.
  Invoice buildLocalInvoice(ProductProvider productProvider) {
    // Construye la lista de productos con nombre, cantidad y precio actualizados
    final List<Product> selectedProds =
        productProvider.selectedProducts.map((product) {
      final quantity = productProvider.quantities[product] ?? 1;
      final price = productProvider.modifiedPrices[product] ?? product.price;
      return Product(
        id: product.id,
        name: product.name,
        price: price,
        description: product.description,
        stock: product.stock,
        category: product.category,
        images: List<String>.from(product.images),
        cachedImageBytes: product.cachedImageBytes,
        quantity: quantity,
      );
    }).toList();

    // Crea la factura local con todos los datos del usuario y productos seleccionados
    return Invoice(
      id: 'local-invoice', // O un ID ficticio/único
      user: _currentUser, // Datos completos del cliente
      userId: null, // Si no tienes ID local, pon null
      products: selectedProds,
      totalAmount: selectedTotal(productProvider),
      medioPago: _medioPago,
      pagaCon: _pagaCon,
      cambio: _cambio,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

// En invoice_provider.dart
  Future<User?> fetchUserByPhone(String phone) async {
    try {
      final sanitized = phone.replaceAll(RegExp(r'[^0-9+]'), '');
      final url = Uri.parse("${ApiConfig.baseUrl}/users/phone/$sanitized");
      final resp = await http.get(url);

      if (resp.statusCode == 200) {
        final raw = jsonDecode(resp.body);

        // Tu API puede responder como { ...usuario } o { "data": { ...usuario } }
        final Map<String, dynamic>? map =
            (raw is Map<String, dynamic> && raw['data'] is Map<String, dynamic>)
                ? (raw['data'] as Map<String, dynamic>)
                : (raw is Map<String, dynamic> ? raw : null);

        if (map == null) return null;

        // Mapea campos al modelo User (observa que tu User.fromJson espera phoneNumber/cc también)
        final user = User.fromJson(map);
        // Sincroniza nombres de clave si tu backend usa 'cc' en lugar de 'nit' (ya lo manejas en User.fromJson)
        setCurrentUser(user);
        return user;
      }

      debugPrint("fetchUserByPhone ${resp.statusCode}: ${resp.body}");
      return null;
    } catch (e) {
      debugPrint("Error fetchUserByPhone: $e");
      return null;
    }
  }

  Future<User?> fetchUserById(String userId) async {
    final response =
        await http.get(Uri.parse("${ApiConfig.baseUrl}/users/id/$userId"));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return User.fromJson(data);
    } else {
      debugPrint("Error fetching user: ${response.statusCode}");
      return null;
    }
  }

  User? _parseUserFromBody(String body) {
    final decoded = jsonDecode(body);

    if (decoded is Map<String, dynamic>) {
      // Si viene envuelto en 'data', úsalo; si no, usa el propio mapa
      final Map<String, dynamic>? raw =
          decoded['data'] is Map<String, dynamic> ? decoded['data'] : decoded;
      if (raw != null) {
        return User.fromJson(raw);
      }
    }
    return null;
  }

  Future<void> fetchTodaysSales() async {
    try {
      final response = await http.get(Uri.parse(_baseUrl));
      if (response.statusCode != 200) {
        throw Exception("Error al obtener ventas: ${response.statusCode}");
      }

      final jsonResponse = jsonDecode(response.body);
      final List<dynamic> data = jsonResponse['data'];
      final today = DateTime.now();

      final List<Invoice> loadedSales = [];

      for (final facturaJson in data) {
        final invoice = Invoice.fromJson(facturaJson);

        final isToday = invoice.createdAt.year == today.year &&
            invoice.createdAt.month == today.month &&
            invoice.createdAt.day == today.day;

        if (!isToday) continue;

        // Si ya viene con user completo:
        if (invoice.user != null) {
          loadedSales.add(invoice);
          continue;
        }

        // Si viene con userId, intentamos enriquecerlo
        if (invoice.userId != null && invoice.userId!.isNotEmpty) {
          try {
            final userResp = await http.get(
              Uri.parse("${ApiConfig.baseUrl}/users/id/${invoice.userId}"),
            );

            if (userResp.statusCode == 200) {
              final user = _parseUserFromBody(userResp.body);
              if (user != null) {
                loadedSales.add(invoice.copyWith(user: user));
              } else {
                // No hay 'data' pero tampoco objeto válido => agregamos como llegó
                loadedSales.add(invoice);
              }
            } else {
              loadedSales.add(invoice);
            }
          } catch (_) {
            loadedSales.add(invoice);
          }
        } else {
          loadedSales.add(invoice);
        }
      }

      _todaysSales = loadedSales;
      notifyListeners();
    } catch (e) {
      throw Exception("Error en fetchTodaysSales: $e");
    }
  }

  /// Genera el PDF usando la factura local (sin hacer petición al servidor).
  /// Ideal para COTIZACIONES o pruebas offline.

  Future<void> generatePdfLocal(BuildContext context,
      {String docType = 'COTIZACIÓN'}) async {
    final productProvider =
        Provider.of<ProductProvider>(context, listen: false);

    // Verifica que haya productos seleccionados
    if (productProvider.selectedProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No hay productos seleccionados."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Construye la factura local
    final Invoice localInvoice = buildLocalInvoice(productProvider);

    // Genera el PDF directamente con los datos locales
    final pdfService = PDFService();
    await pdfService.printInvoiceStyled(localInvoice, docType: docType);

    // Si quieres limpiar la selección de productos tras generar el PDF, descomenta:
    // productProvider.removeSelectedProducts();
  }

  Future<void> createInvoice(BuildContext context,
      {String docType = 'FACTURA DE COMPRA'}) async {
    final productProvider =
        Provider.of<ProductProvider>(context, listen: false);

    if (productProvider.selectedProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No hay productos seleccionados para facturar."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 1) Construimos el invoice local con todos los datos
    Invoice localInvoice = buildLocalInvoice(productProvider);

    // 2) Obtenemos el consecutivo desde el servidor
    final int nextConsec = await _invoiceService.fetchNextConsecutive();

    // 3) Creamos un nuevo Invoice basado en el local, pero fijando el consecutivo
    localInvoice = Invoice(
      id: localInvoice.id,
      user: localInvoice.user,
      userId: localInvoice.userId,
      products: localInvoice.products,
      totalAmount: localInvoice.totalAmount,
      medioPago: localInvoice.medioPago,
      pagaCon: localInvoice.pagaCon,
      cambio: localInvoice.cambio,
      consecutivo: nextConsec,
      createdAt: localInvoice.createdAt,
      updatedAt: localInvoice.updatedAt,
    );

    // 4) Armamos el payload para el servidor (incluyendo el consecutivo)
    final invoiceData = {
      "name": localInvoice.user?.name ?? "Cliente",
      "phone": localInvoice.user?.phone ?? "No proporcionado",
      "email": localInvoice.user?.email ?? "No proporcionado",
      "cc": localInvoice.user?.nit ?? "No proporcionado",
      "detalles": "Factura generada desde Flutter",
      "products": localInvoice.products
          .map((p) => {
                "productId": p.id,
                "quantity": p.quantity,
                "appliedPrice": p.price,
              })
          .toList(),
      "pagaCon": localInvoice.pagaCon,
      "medioPago": localInvoice.medioPago,
      "cambio": localInvoice.cambio,
      "totalAmount": localInvoice.totalAmount,
      "consecutivo": localInvoice.consecutivo,
    };

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(invoiceData),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = jsonDecode(response.body);
        final invoiceServer = Invoice.fromJson(body['data']);
        _invoices.add(invoiceServer);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              body['message'] ??
                  "Factura #${localInvoice.consecutivo} creada exitosamente",
            ),
            backgroundColor: Colors.green,
          ),
        );

        // refrescar stock, etc.
        await productProvider.fetchProducts(forceUpdate: true);
        // 5) Generar PDF usando nuestro localInvoice (con todos los datos)
        await PDFService().printInvoiceStyled(
          localInvoice,
          docType: docType,
        );

        productProvider.removeSelectedProducts();
      } else {
        final err = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al crear la factura: ${err['message']}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error al conectar con el servidor: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ================== LIMPIAR DATOS ==================
  /// Limpia todos los datos de la factura
  void clearAllData() {
    _currentUser = null;
    _medioPago = 'Efectivo';
    _pagaCon = 0.0;
    _cambio = 0.0;
    notifyListeners();
  }
}
