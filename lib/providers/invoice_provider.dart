import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../config/api_config.dart';
import '../models/cart_model.dart';
import '../models/invoice_model.dart';
import '../models/product_model.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/product_provider.dart';
import '../services/invoice_service.dart';
import '../services/pdfService.dart';

class InvoiceProvider with ChangeNotifier {
  final String _baseUrl = "${ApiConfig.baseUrl}/newBill";
  final InvoiceService _invoiceService = InvoiceService();

  // ========================= CAMPOS =========================
  User? _currentUser;

  String _medioPago = 'Efectivo';
  double _pagaCon = 0.0;
  double _cambio = 0.0;

  /// IDs de productos seleccionados en el carrito
  Set<String> _selectedProductIds = {};

  final List<Invoice> _invoices = [];
  List<Invoice> _todaysSales = [];

  double _subtotal = 0.0;

  // ========================= GETTERS =========================
  User? get currentUser => _currentUser;
  String get medioPago => _medioPago;
  double get pagaCon => _pagaCon;
  double get cambio => _cambio;
  List<Invoice> get invoices => _invoices;
  List<Invoice> get todaysSales => _todaysSales;
  double get totalVentasHoy => _todaysSales.fold<double>(
        0.0,
        (suma, factura) => suma + factura.totalAmount,
      );

  double totalHoyPorMedio(String medio) => _todaysSales.fold<double>(
        0.0,
        (suma, factura) => suma + factura.montoPorMedio(medio),
      );
  Set<String> get selectedProductIds => _selectedProductIds;
  double get subtotal => _subtotal;

  /// Solo para debug (retorna IDs)
  List<String> get selectedCartItems {
    return _selectedProductIds.toList();
  }

  // ========================= TOTALES =========================

  /// Actualiza subtotal y recalcula cambio
  void updateTotals(double value) {
    _subtotal = value;
    _cambio = _pagaCon - _subtotal;
    notifyListeners();
  }

  /// Se llama cuando cambias "Paga con" desde el CartSummary
  void setPagaCon(double value) {
    _pagaCon = value;
    _cambio = _pagaCon - _subtotal;
    notifyListeners();
  }

  /// Recalcula subtotal y cambio a partir del carrito actual
  /// usando SOLO los items cuyos IDs estén en _selectedProductIds
  void recalculateTotalsFromCart(
    Cart? cart, {
    required bool isAdmin,
  }) {
    if (cart == null) {
      _subtotal = 0.0;
      _cambio = _pagaCon - _subtotal;
      notifyListeners();
      return;
    }

    final selectedItems = cart.items
        .where((item) => _selectedProductIds.contains(item.product.id))
        .toList();

    final double total = selectedItems.fold<double>(0.0, (sum, item) {
      final double unitPrice = isAdmin
          ? (item.appliedPrice > 0
              ? item.appliedPrice.toDouble()
              : item.product.price)
          : item.product.price;
      return sum + unitPrice * item.quantity;
    });

    _subtotal = total;
    _cambio = _pagaCon - _subtotal;
    notifyListeners();
  }

  // ========================= SETTERS =========================
  void setCurrentUser(User user) {
    _currentUser = user;
    notifyListeners();
  }

  void setMedioPago(String medio) {
    _medioPago = medio;
    notifyListeners();
  }

  /// Actualizar selección de productos del carrito (vía ProductList)
  void setSelectedCartItems(List<CartItem> items) {
    _selectedProductIds = items.map((e) => e.product.id).toSet();
    notifyListeners();
  }

  // ============= COMPATIBILIDAD CON UI ANTIGUA (no borrar) =============
  void updateSubtotal(ProductProvider productProvider) {
    // En la UI nueva no se usa, se mantiene por compatibilidad
    notifyListeners();
  }

  // ========================= USUARIOS =========================
  Future<User?> fetchUserByPhone(String phone) async {
    try {
      final sanitized = phone.replaceAll(RegExp(r'[^0-9+]'), '');
      final url = Uri.parse("${ApiConfig.baseUrl}/users/phone/$sanitized");
      final resp = await http.get(url);

      if (resp.statusCode == 200) {
        final raw = jsonDecode(resp.body);

        final Map<String, dynamic>? map =
            (raw is Map<String, dynamic> && raw['data'] is Map<String, dynamic>)
                ? raw['data']
                : (raw is Map<String, dynamic> ? raw : null);

        if (map == null) return null;

        final user = User.fromJson(map);
        _currentUser = user;
        notifyListeners();
        return user;
      }
    } catch (e) {
      debugPrint("fetchUserByPhone error: $e");
    }
    return null;
  }

  Future<User?> fetchUserById(String userId) async {
    try {
      final resp =
          await http.get(Uri.parse("${ApiConfig.baseUrl}/users/id/$userId"));

      if (resp.statusCode == 200) {
        final raw = jsonDecode(resp.body);
        return User.fromJson(raw is Map<String, dynamic> ? raw : raw["data"]);
      }
    } catch (_) {}
    return null;
  }

  // ========================= VENTAS DEL DÍA =========================
  Future<void> fetchTodaysSales() async {
    try {
      final resp = await http.get(Uri.parse(_baseUrl));
      if (resp.statusCode != 200) return;

      final json = jsonDecode(resp.body);
      final List<dynamic> data = json["data"];

      final today = DateTime.now();
      final List<Invoice> parsed = [];

      for (final factura in data) {
        final invoice = Invoice.fromJson(factura);

        final sameDay = invoice.createdAt.year == today.year &&
            invoice.createdAt.month == today.month &&
            invoice.createdAt.day == today.day;

        if (!sameDay) continue;

        if (invoice.user != null) {
          parsed.add(invoice);
          continue;
        }

        if (invoice.userId != null && invoice.userId!.isNotEmpty) {
          final respUser = await http.get(
            Uri.parse("${ApiConfig.baseUrl}/users/id/${invoice.userId}"),
          );

          if (respUser.statusCode == 200) {
            final raw = jsonDecode(respUser.body);
            final user = User.fromJson(raw is Map ? raw : raw["data"]);
            parsed.add(invoice.copyWith(user: user));
            continue;
          }
        }

        parsed.add(invoice);
      }

      _todaysSales = parsed;
      notifyListeners();
    } catch (e) {
      debugPrint("fetchTodaysSales error: $e");
    }
  }

  // ========================= FACTURA LOCAL (UI antigua) =========================
  Invoice buildLocalInvoice(ProductProvider productProvider) {
    final selected = productProvider.selectedProducts.map((product) {
      final qty = productProvider.quantities[product] ?? 1;
      final applied = productProvider.modifiedPrices[product] ?? product.price;

      return Product(
        id: product.id,
        name: product.name,
        price: applied,
        description: product.description,
        stock: product.stock,
        category: product.category,
        images: List<String>.from(product.images),
        cachedImageBytes: product.cachedImageBytes,
        quantity: qty,
      );
    }).toList();

    return Invoice(
      id: "local",
      user: _currentUser,
      products: selected,
      totalAmount:
          selected.fold(0.0, (sum, p) => sum + (p.price * (p.quantity))),
      medioPago: _medioPago,
      pagaCon: _pagaCon,
      cambio: _cambio,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Future<void> generatePdfLocal(BuildContext context,
      {String docType = 'COTIZACIÓN'}) async {
    final productProvider =
        Provider.of<ProductProvider>(context, listen: false);

    if (productProvider.selectedProducts.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("No hay productos.")));
      return;
    }

    final invoice = buildLocalInvoice(productProvider);
    await PDFService().printInvoiceStyled(invoice, docType: docType);
  }

  // ========================= FACTURA DESDE UI ANTIGUA =========================
  Future<void> createInvoice(BuildContext context,
      {String docType = 'FACTURA DE COMPRA'}) async {
    final productProvider =
        Provider.of<ProductProvider>(context, listen: false);

    if (productProvider.selectedProducts.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("No hay productos.")));
      return;
    }

    Invoice invoice = buildLocalInvoice(productProvider);
    final consecutive = await _invoiceService.fetchNextConsecutive();

    final payload = {
      "name": invoice.user?.name ?? "",
      "phone": invoice.user?.phone ?? "",
      "email": invoice.user?.email ?? "",
      "cc": invoice.user?.nit ?? "",
      "products": invoice.products
          .map((p) => {
                "productId": p.id,
                "quantity": p.quantity,
                "appliedPrice": p.price
              })
          .toList(),
      "medioPago": invoice.medioPago,
      "pagaCon": invoice.pagaCon,
      "cambio": invoice.cambio,
      "totalAmount": invoice.totalAmount,
      "consecutivo": consecutive
    };

    try {
      final resp = await http.post(
        Uri.parse(_baseUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        await PDFService().printInvoiceStyled(invoice, docType: docType);
        productProvider.removeSelectedProducts();
      }
    } catch (e) {
      debugPrint("Error createInvoice: $e");
    }
  }

  // ========================= FACTURA DESDE CARRITO =========================
  Future<void> createInvoiceFromCart(BuildContext context,
      {String docType = 'FACTURA DE COMPRA'}) async {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final bool isAdmin = authProvider.role == 'admin';

    final cart = cartProvider.cart;
    final selectedItems = resolveSelectedItemsFromCart(cart);

    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No has seleccionado productos.")),
      );
      return;
    }

    final int consecutivo = await _invoiceService.fetchNextConsecutive();

    final payloadProducts = selectedItems.map((item) {
      final double unitPrice = isAdmin
          ? (item.appliedPrice > 0
              ? item.appliedPrice.toDouble()
              : item.product.price)
          : item.product.price;

      return {
        "productId": item.product.id,
        "quantity": item.quantity,
        "appliedPrice": unitPrice,
      };
    }).toList();

    final double totalAmount = payloadProducts.fold<double>(
      0,
      (sum, p) =>
          sum +
          (p["quantity"] as num).toDouble() *
              (p["appliedPrice"] as num).toDouble(),
    );

    final payload = {
      "name": _currentUser?.name ?? "Cliente",
      "phone": _currentUser?.phone ?? "",
      "email": _currentUser?.email ?? "",
      "cc": _currentUser?.nit ?? "",
      "products": payloadProducts,
      "medioPago": _medioPago,
      "pagaCon": _pagaCon,
      "cambio": _cambio,
      "totalAmount": totalAmount,
      "consecutivo": consecutivo
    };

    try {
      final resp = await http.post(
        Uri.parse(_baseUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final productsForInvoice = selectedItems.map((item) {
          final double unitPrice = isAdmin
              ? (item.appliedPrice > 0
                  ? item.appliedPrice.toDouble()
                  : item.product.price)
              : item.product.price;

          return Product(
            id: item.product.id,
            name: item.product.name,
            price: unitPrice,
            description: item.product.description,
            stock: item.product.stock,
            category: item.product.category,
            images: List<String>.from(item.product.images),
            cachedImageBytes: item.product.cachedImageBytes,
            quantity: item.quantity,
          );
        }).toList();

        final invoice = Invoice(
          id: "inv-$consecutivo",
          user: _currentUser,
          products: productsForInvoice,
          totalAmount: totalAmount,
          medioPago: _medioPago,
          pagaCon: _pagaCon,
          cambio: _cambio,
          consecutivo: consecutivo,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await PDFService().printInvoiceStyled(invoice, docType: docType);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Factura #$consecutivo creada correctamente")),
        );

        clearSelections();
      }
    } catch (e) {
      debugPrint("Error factura carrito: $e");
    }
  }

  // ========================= PDF DESDE CARRITO =========================
  Future<void> generatePdfFromCart(
    BuildContext context, {
    String docType = 'COTIZACIÓN',
  }) async {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final bool isAdmin = authProvider.role == 'admin';

    final cart = cartProvider.cart;
    final selectedItems = resolveSelectedItemsFromCart(cart);

    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("No hay productos.")));
      return;
    }

    final products = selectedItems.map((item) {
      final double unitPrice = isAdmin
          ? (item.appliedPrice > 0
              ? item.appliedPrice.toDouble()
              : item.product.price)
          : item.product.price;

      return Product(
        id: item.product.id,
        name: item.product.name,
        price: unitPrice,
        description: item.product.description,
        stock: item.product.stock,
        category: item.product.category,
        images: List<String>.from(item.product.images),
        cachedImageBytes: item.product.cachedImageBytes,
        quantity: item.quantity,
      );
    }).toList();

    final invoice = Invoice(
      id: "local-cart-pdf",
      user: _currentUser,
      products: products,
      totalAmount:
          products.fold(0.0, (sum, p) => sum + (p.price * (p.quantity))),
      medioPago: _medioPago,
      pagaCon: _pagaCon,
      cambio: _cambio,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await PDFService().printInvoiceStyled(invoice, docType: docType);
  }

  // ========================= SELECCIÓN DESDE CARRITO =========================

  /// Resolver la lista de CartItem seleccionados a partir del carrito actual
  List<CartItem> resolveSelectedItemsFromCart(Cart? cart) {
    if (cart == null) return [];
    if (_selectedProductIds.isEmpty) return [];
    return cart.items
        .where((item) => _selectedProductIds.contains(item.product.id))
        .toList();
  }

  Future<void> generatePdfFromUiSelection(
    BuildContext context, {
    String docType = 'COTIZACIÓN',
  }) async {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    final selected = cartProvider.selectedUiItems; // LocalCartItem list
    if (selected.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("No hay productos.")));
      return;
    }

    final invalidProjects = selected.where((item) {
      if (!item.isProjectProduct) return false;

      final details = item.projectDetails;

      if (details == null) return true;

      return details.advancePayment <= 0 ||
          details.advancePayment > item.commercialTotal;
    }).toList();

    if (invalidProjects.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'El abono debe ser mayor a cero y no puede superar '
            'el valor total del proyecto.',
          ),
        ),
      );
      return;
    }

    final products = selected.map((it) {
      return Product(
        id: it.productId,
        name: it.name,
        price: it
            .effectivePrice, // 👈 aquí ya va applied si el admin lo cambió en UI
        description:
            it.isProjectProduct ? (it.projectDetails?.description ?? '') : '',
        stock: 0,
        category: '',
        images: it.image.isNotEmpty ? [it.image] : [],
        quantity: it.quantity,
      );
    }).toList();

    final total = products.fold<double>(
      0.0,
      (sum, p) => sum + (p.price * (p.quantity)),
    );

    final invoice = Invoice(
      id: "ui-cart-pdf",
      user: _currentUser,
      products: products,
      totalAmount: total,
      medioPago: _medioPago,
      pagaCon: _pagaCon,
      cambio: _cambio,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await PDFService().printInvoiceStyled(
      invoice,
      docType: docType,
      projectItems: selected.where((it) => it.isProjectProduct).toList(),
    );
  }

  Future<bool> createInvoiceFromUiSelection(
    BuildContext context, {
    String docType = 'FACTURA DE COMPRA',
    String? medioTransferencia,
    double valorTransferido = 0.0,
  }) async {
    final authProvider = context.read<AuthProvider>();
    final cartProvider = context.read<CartProvider>();

    void mostrarMensaje(String mensaje) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensaje)),
      );
    }

    if (authProvider.role != 'admin') {
      mostrarMensaje('Solo el admin puede facturar.');
      return false;
    }

    final selected = cartProvider.selectedUiItems.toList();

    if (selected.isEmpty) {
      mostrarMensaje('No has seleccionado productos.');
      return false;
    }

    final cliente = _currentUser;
    final medioPago = _medioPago;
    final efectivoRecibido = _pagaCon;
    final esMixto = medioPago == 'Mixto';
    final projectItems =
        selected.where((item) => item.isProjectProduct).toList();
    final tieneProyecto = projectItems.isNotEmpty;

    var totalAmount = 0.0;
    final payloadProducts = <Map<String, dynamic>>[];

    for (final item in selected) {
      final precioCobrado = item.isProjectProduct
          ? (item.projectDetails?.advancePayment ?? 0.0)
          : item.effectivePrice;

      totalAmount += precioCobrado * item.quantity;

      payloadProducts.add({
        'productId': item.productId,
        'quantity': item.quantity,
        'appliedPrice': precioCobrado,
      });
    }

    var pagoRecibido = tieneProyecto ? totalAmount : efectivoRecibido;
    var cambioCalculado = !tieneProyecto && medioPago == 'Efectivo'
        ? (efectivoRecibido - totalAmount)
            .clamp(0.0, double.infinity)
            .toDouble()
        : 0.0;

    final pagos = <InvoicePayment>[];

    if (esMixto) {
      final transferencia = medioTransferencia;
      const mediosPermitidos = {'Nequi', 'Bancolombia', 'Bre-B'};

      if (transferencia == null || !mediosPermitidos.contains(transferencia)) {
        mostrarMensaje('Selecciona el medio de transferencia.');
        return false;
      }

      bool esMontoValido(double monto) =>
          monto.isFinite &&
          monto >= 0 &&
          monto <= 9007199254740991 &&
          monto == monto.truncateToDouble();

      final totalRecibido = efectivoRecibido + valorTransferido;

      if (!esMontoValido(totalAmount) ||
          !esMontoValido(efectivoRecibido) ||
          !esMontoValido(valorTransferido) ||
          !esMontoValido(totalRecibido)) {
        mostrarMensaje('Ingresa valores válidos en pesos enteros.');
        return false;
      }

      if (valorTransferido <= 0 || valorTransferido >= totalAmount) {
        mostrarMensaje(
            'La transferencia debe ser mayor a cero y menor al total.');
        return false;
      }

      final efectivoAplicado = totalAmount - valorTransferido;

      if (efectivoRecibido < efectivoAplicado) {
        mostrarMensaje('El efectivo recibido no cubre el saldo de la factura.');
        return false;
      }

      pagoRecibido = totalRecibido;
      cambioCalculado = efectivoRecibido - efectivoAplicado;

      pagos.addAll([
        InvoicePayment(medio: 'Efectivo', monto: efectivoAplicado),
        InvoicePayment(medio: transferencia, monto: valorTransferido),
      ]);
    }

    final payload = {
      'name': cliente?.name ?? 'Cliente',
      'phone': cliente?.phone ?? '',
      'email': cliente?.email ?? '',
      'cc': cliente?.nit ?? '',
      'products': payloadProducts,
      'medioPago': medioPago,
      'pagaCon': pagoRecibido,
      'cambio': cambioCalculado,
      'totalAmount': totalAmount,
      if (esMixto) 'pagos': pagos.map((pago) => pago.toJson()).toList(),
    };

    final http.Response respuesta;

    try {
      respuesta = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
    } catch (error) {
      debugPrint('Error al enviar la factura: $error');
      mostrarMensaje(
          'No se confirmó el guardado. Revisa Ventas Hoy antes de reintentar.');
      return false;
    }

    if (respuesta.statusCode < 200 || respuesta.statusCode >= 300) {
      debugPrint('POST newBill: ${respuesta.statusCode} ${respuesta.body}');
      mostrarMensaje('No se confirmó el guardado (${respuesta.statusCode}).');
      return false;
    }

    // A partir de aquí, el servidor ya confirmó que guardó la factura.
    try {
      final body = jsonDecode(respuesta.body) as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>;
      final consecutivo = (data['consecutivo'] as num).toInt();

      final productsForPdf = selected.map((item) {
        return Product(
          id: item.productId,
          name: item.name,
          price: item.effectivePrice,
          description: item.isProjectProduct
              ? (item.projectDetails?.description ?? '')
              : '',
          stock: 0,
          category: '',
          images: item.image.isNotEmpty ? [item.image] : [],
          quantity: item.quantity,
        );
      }).toList();

      final ahora = DateTime.now();
      final invoice = Invoice(
        id: data['_id']?.toString() ?? 'inv-$consecutivo',
        user: cliente,
        products: productsForPdf,
        totalAmount: totalAmount,
        medioPago: medioPago,
        pagaCon: pagoRecibido,
        cambio: cambioCalculado,
        pagos: pagos,
        consecutivo: consecutivo,
        createdAt: ahora,
        updatedAt: ahora,
      );

      await PDFService().printInvoiceStyled(
        invoice,
        docType: docType,
        projectItems: projectItems,
      );

      mostrarMensaje('Factura #$consecutivo guardada correctamente.');
    } catch (error) {
      debugPrint('Error al preparar o imprimir el PDF: $error');
      mostrarMensaje(
          'La factura se guardó, pero no se pudo generar o imprimir el PDF.');
    }

    clearSelections();
    return true;
  }

  // ========================= LIMPIEZA =========================
  void clearSelections() {
    _selectedProductIds.clear();
    clearAllData();
  }

  void clearAllData() {
    _currentUser = null;
    _medioPago = 'Efectivo';
    _pagaCon = 0.0;
    _subtotal = 0.0;
    _cambio = 0.0;
    notifyListeners();
  }
}
