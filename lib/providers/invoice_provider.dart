import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../models/invoice_model.dart'; // Modelo de factura
import '../models/product_model.dart';
import '../models/user_model.dart'; // Modelo de usuario
import '../providers/product_provider.dart'; // Proveedor de productos
import '../services/pdfService.dart';

class InvoiceProvider with ChangeNotifier {
  final String _baseUrl = "http://34.226.208.66:3001/api/newBill";

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
        imageUrl: product.imageUrl,
        stock: product.stock,
        category: product.category,
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

  /// Método para obtener las ventas de hoy.
  /// Se asume que el endpoint devuelve un JSON con:
  /// { "success": true, "data": [ { ... factura1 ... }, { ... factura2 ... }, ... ] }
  Future<void> fetchTodaysSales() async {
    try {
      final response = await http.get(Uri.parse(_baseUrl));
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        // Se asume que el array de facturas viene en "data"
        final List<dynamic> data = jsonResponse['data'];
        // Puedes aplicar un filtro por fecha si el servidor retorna todas las ventas
        // y necesitas solo las de hoy. Por ejemplo:
        final today = DateTime.now();
        _todaysSales =
            data.map((json) => Invoice.fromJson(json)).where((invoice) {
          // Aquí suponemos que invoice.createdAt es DateTime y filtramos por día
          return invoice.createdAt.year == today.year &&
              invoice.createdAt.month == today.month &&
              invoice.createdAt.day == today.day;
        }).toList();
        notifyListeners();
      } else {
        throw Exception("Error al obtener ventas: ${response.statusCode}");
      }
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

  // ================== FACTURA CON ENVÍO AL SERVIDOR ==================
  /// Envía la factura al servidor y luego imprime el PDF usando los datos LOCALES
  /// (para asegurarnos de que no falte nada).
  Future<void> createInvoice(BuildContext context,
      {String docType = 'FACTURA DE VENTA'}) async {
    final productProvider =
        Provider.of<ProductProvider>(context, listen: false);

    // Verifica que haya productos seleccionados
    if (productProvider.selectedProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No hay productos seleccionados para facturar."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Construye la lista de productos a enviar al servidor
    final List<Map<String, dynamic>> productList =
        productProvider.selectedProducts.map((product) {
      final quantity = productProvider.quantities[product] ?? 1;
      final price = productProvider.modifiedPrices[product] ?? product.price;
      return {
        "productId": product.id,
        "name": product.name,
        "quantity": quantity,
        "price": price,
      };
    }).toList();

    // Datos a enviar en la petición
    final invoiceData = {
      "name": _currentUser?.name ?? "Cliente",
      "phone": _currentUser?.phone ?? "No proporcionado",
      "email": _currentUser?.email ?? "No proporcionado",
      "cc": _currentUser?.nit ?? "No proporcionado",
      "detalles": "Factura generada desde Flutter",
      "products": productList
          .map((p) => {
                "productId": p["productId"],
                "quantity": p["quantity"],
              })
          .toList(),
      "pagaCon": _pagaCon,
      "medioPago": _medioPago,
      "cambio": _cambio,
      "totalAmount": selectedTotal(productProvider),
    };

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(invoiceData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);

        // Opcional: podemos leer lo que devuelva el servidor
        //           (por si queremos mostrar un ID en consola)
        final invoiceServer = Invoice.fromJson(responseData['data']);
        _invoices.add(invoiceServer);

        // Notifica éxito en la UI
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(responseData['message'] ?? "Factura creada exitosamente"),
            backgroundColor: Colors.green,
          ),
        );

        print("Factura generada en el servidor:");
        print(invoiceServer.toJson());

        // Actualiza los productos y su lista filtrada (por si cambió stock)
        await productProvider.fetchProducts(forceUpdate: true);

        // AHORA generamos el PDF usando NUESTROS DATOS LOCALES
        // para asegurarnos de que no falte nada.
        final pdfService = PDFService();
        final localInvoice = buildLocalInvoice(productProvider);
        await pdfService.printInvoiceStyled(localInvoice, docType: docType);

        // Limpia los productos seleccionados en el carrito
        productProvider.removeSelectedProducts();
      } else {
        final responseData = jsonDecode(response.body);
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text("Error al crear la factura: ${responseData['message']}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (error) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error al conectar con el servidor: $error"),
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
