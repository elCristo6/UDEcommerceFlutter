import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/invoice_provider.dart';

class CartSummary extends StatefulWidget {
  const CartSummary({super.key});

  @override
  State<CartSummary> createState() => _CartSummaryState();
}

class _CartSummaryState extends State<CartSummary> {
  bool _isFacturaSelected = true;
  bool _isCotizacionSelected = false;

  final TextEditingController _pagaConController = TextEditingController();
  final _transferenciaController = TextEditingController();
  String? _medioTransferencia;
  bool _guardandoFactura = false;
  String formatCurrency(int value) {
    return value.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  double? _parseMoney(String value) {
    final input = value.trim();
    final formatoValido = RegExp(r'^(?:[0-9]+|[0-9]{1,3}(?:\.[0-9]{3})+)$');
    if (!formatoValido.hasMatch(input)) return null;

    final pesos = int.tryParse(input.replaceAll('.', ''));
    if (pesos == null || pesos > 9007199254740991) return null;
    return pesos.toDouble();
  }

  @override
  void dispose() {
    _pagaConController.dispose();
    _transferenciaController.dispose();
    super.dispose();
  }

  // =========================
  // WhatsApp (solo guest)
  // =========================
  Future<void> _launchWhatsAppWithCart({
    required String phoneDigits, // solo números, ej: 573208576038
    required String message,
  }) async {
    final Uri url = Uri.parse(
      "https://wa.me/$phoneDigits?text=${Uri.encodeComponent(message)}",
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("No se pudo abrir WhatsApp.")),
    );
  }

  String _buildWhatsAppCartMessage({
    required List<dynamic> selectedUiItems, // LocalCartItem (guest)
    required double subtotal,
    required String medioPago,
  }) {
    // selectedUiItems aquí realmente vienen de cartProvider.selectedUiItems (LocalCartItem)
    // No tipamos fuerte para no obligarte a importar el modelo aquí.
    // Si prefieres, lo tipamos a List<LocalCartItem> y listo.

    final buffer = StringBuffer();
    buffer.writeln(
        "Hola, estoy en UDElectronics.com y quiero hacer este pedido:");
    buffer.writeln("");

    for (final it in selectedUiItems) {
      // it.productId, it.name, it.quantity, it.price
      final String name = (it.name ?? '').toString();
      final int qty = (it.quantity ?? 0) as int;
      final double unit = (it.price ?? 0.0) as double;
      final double line = unit * qty;

      buffer.writeln("• $name");
      buffer.writeln("  Cantidad: $qty");
      buffer.writeln("  Unitario: COP ${formatCurrency(unit.toInt())}");
      buffer.writeln("  Subtotal: COP ${formatCurrency(line.toInt())}");
      buffer.writeln("");
    }

    buffer.writeln("TOTAL: COP ${formatCurrency(subtotal.toInt())}");
    if (medioPago.isNotEmpty) {
      buffer.writeln("Medio de pago: $medioPago");
    }
    buffer.writeln("");
    buffer.writeln("¿Me confirmas disponibilidad y costo de envío?");

    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final invoiceProvider = Provider.of<InvoiceProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    final String? tokenNullable = authProvider.token;
    final bool isAuth = tokenNullable != null && tokenNullable.isNotEmpty;
    final puedePagarMixto =
        isAuth && authProvider.role == 'admin' && _isFacturaSelected;
    final esMixto = puedePagarMixto && invoiceProvider.medioPago == 'Mixto';

    // =========================
    // Fuente unificada (guest + auth) para totales/selección
    // =========================
    final selectedUiItems = cartProvider.selectedUiItems;
    final subtotal = cartProvider.selectedSubtotal;
    final double totalCobrar = selectedUiItems.fold<double>(
      0.0,
      (sum, item) {
        if (item.isProjectProduct) {
          return sum +
              (item.projectDetails?.advancePayment ?? 0.0) * item.quantity;
        }

        return sum + item.effectivePrice * item.quantity;
      },
    );

    final efectivoIngresado = _parseMoney(_pagaConController.text);
    final transferenciaIngresada = _parseMoney(_transferenciaController.text);
    final pagaCon = efectivoIngresado ?? 0.0;
    final valorTransferido = transferenciaIngresada ?? 0.0;
    final transferenciaValida =
        valorTransferido > 0 && valorTransferido < totalCobrar;

    final efectivoPorCubrir = totalCobrar - (esMixto ? valorTransferido : 0.0);
    final saldo = pagaCon - efectivoPorCubrir;
    final mostrarCambioMixto =
        transferenciaValida && efectivoIngresado != null && saldo > 0;
    final double cambio = esMixto ? (mostrarCambioMixto ? saldo : 0.0) : saldo;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 2,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumen',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 16),

          // ==================== SUBTOTAL ====================
          _buildSummaryRow(
            'Subtotal',
            'COP ${formatCurrency(totalCobrar.toInt())}',
          ),

          const SizedBox(height: 10),

          // ==================== PAGA CON ====================
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(esMixto ? 'Efectivo recibido:' : 'Paga con:'),
              SizedBox(
                width: 120,
                child: TextField(
                  controller: _pagaConController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.right,
                  onChanged: (value) {
                    final recibido = _parseMoney(value) ?? 0.0;

                    invoiceProvider.setPagaCon(recibido);
                  },
                  decoration: const InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    hintText: 'COP',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ==================== CAMBIO ====================
          _buildSummaryRow(
            'Cambio:',
            'COP ${formatCurrency(cambio.toInt())}',
            isNegative: cambio < 0,
          ),

          const Divider(height: 30),

          // ==================== TOTAL ====================
          _buildSummaryRow(
            'TOTAL:',
            'COP ${formatCurrency(totalCobrar.toInt())}',
            isBold: true,
            isLarge: true,
          ),

          const SizedBox(height: 20),

          const Text(
            'Medio de pago:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 10),

          Wrap(
            spacing: 10,
            children: [
              _buildPaymentOption(invoiceProvider, 'Efectivo'),
              _buildPaymentOption(invoiceProvider, 'Nequi'),
              _buildPaymentOption(invoiceProvider, 'Bre-B'),
              _buildPaymentOption(invoiceProvider, 'Bancolombia'),
              if (puedePagarMixto)
                _buildPaymentOption(invoiceProvider, 'Mixto'),
            ],
          ),
          if (esMixto) ...[
            const SizedBox(height: 12),
            DropdownButton<String>(
              isExpanded: true,
              value: _medioTransferencia,
              hint: const Text('Medio de transferencia'),
              items: const [
                DropdownMenuItem(value: 'Nequi', child: Text('Nequi')),
                DropdownMenuItem(
                    value: 'Bancolombia', child: Text('Bancolombia')),
                DropdownMenuItem(value: 'Bre-B', child: Text('Llave')),
              ],
              onChanged: (medio) => setState(() => _medioTransferencia = medio),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _transferenciaController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Valor transferido',
                prefixText: 'COP ',
              ),
              onChanged: (_) => setState(() {}),
            ),
            if (valorTransferido > 0 && !transferenciaValida)
              const Text('La transferencia debe ser menor que el total.'),
            if (transferenciaValida && saldo < 0)
              Text('Faltan COP ${formatCurrency((-saldo).round())}'),
          ],
          const SizedBox(height: 20),

          // ==================== FACTURA / COTIZACIÓN ====================
          Row(
            children: [
              Checkbox(
                value: _isFacturaSelected,
                onChanged: (_) {
                  setState(() {
                    _isFacturaSelected = true;
                    _isCotizacionSelected = false;
                  });
                },
              ),
              const Text('Factura de venta'),
              const SizedBox(width: 20),
              Checkbox(
                value: _isCotizacionSelected,
                onChanged: (_) {
                  if (invoiceProvider.medioPago == 'Mixto') {
                    invoiceProvider.setMedioPago('Efectivo');
                    _transferenciaController.clear();
                    _medioTransferencia = null;
                  }
                  setState(() {
                    _isCotizacionSelected = true;
                    _isFacturaSelected = false;
                  });
                },
              ),
              const Text('Cotización'),
            ],
          ),

          const SizedBox(height: 20),

          // ==================== BOTÓN FINALIZAR ====================
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _guardandoFactura
                  ? null
                  : () async {
                      if (selectedUiItems.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('No hay productos seleccionados.')),
                        );
                        return;
                      }

                      // snapshot selección
                      final selectedIds = cartProvider.selectedIds.toList();

                      try {
                        final role = authProvider.role;
                        final token = authProvider.token ?? '';
                        final isAdmin = role == 'admin';
                        final isUserAuth = token.isNotEmpty && !isAdmin;
                        final isGuest = token.isEmpty;

                        // ====== ARMAR MENSAJE WHATSAPP (sirve para guest y user) ======
                        final message = _buildWhatsAppCartMessage(
                          selectedUiItems: selectedUiItems,
                          subtotal: subtotal,
                          medioPago: invoiceProvider.medioPago,
                        );

                        const phoneDigits = "573208576038";

                        // ============================================================
                        // 1) GUEST -> WhatsApp + limpia LOCAL
                        // ============================================================
                        if (isGuest) {
                          await _launchWhatsAppWithCart(
                            phoneDigits: phoneDigits,
                            message: message,
                          );

                          // borra lo comprado del local cart
                          for (final id in selectedIds) {
                            await cartProvider.removeLocal(id);
                          }
                          cartProvider.clearSelection();
                          _pagaConController.clear();
                          return;
                        }

                        // ============================================================
                        // 2) ADMIN -> Backend + PDF (o solo PDF) + limpia LOCAL
                        // ============================================================
                        if (isAdmin) {
                          if (_guardandoFactura) return;

                          if (_isFacturaSelected) {
                            final tieneProyecto = selectedUiItems
                                .any((item) => item.isProjectProduct);
                            final esEfectivo =
                                invoiceProvider.medioPago == 'Efectivo';
                            final requiereEfectivo =
                                esMixto || (esEfectivo && !tieneProyecto);
                            final efectivoInvalido = efectivoIngresado ==
                                    null &&
                                (requiereEfectivo ||
                                    _pagaConController.text.trim().isNotEmpty);

                            if (efectivoInvalido ||
                                (esMixto && transferenciaIngresada == null)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Revisa los importes. Escribe 50000 o 50.000.'),
                                ),
                              );
                              return;
                            }

                            if (esEfectivo &&
                                !tieneProyecto &&
                                pagaCon < totalCobrar) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'El efectivo recibido no cubre el total.'),
                                ),
                              );
                              return;
                            }
                          }

                          setState(() => _guardandoFactura = true);

                          try {
                            invoiceProvider.updateTotals(totalCobrar);
                            invoiceProvider.setPagaCon(pagaCon);

                            if (_isFacturaSelected) {
                              final guardada = await invoiceProvider
                                  .createInvoiceFromUiSelection(
                                context,
                                medioTransferencia:
                                    esMixto ? _medioTransferencia : null,
                                valorTransferido:
                                    esMixto ? valorTransferido : 0.0,
                              );

                              if (!guardada) return;
                            } else {
                              await invoiceProvider
                                  .generatePdfFromUiSelection(context);
                            }

                            for (final id in selectedIds) {
                              await cartProvider.removeLocal(id);
                            }
                            cartProvider.clearSelection();

                            if (mounted) {
                              _pagaConController.clear();
                              _transferenciaController.clear();
                              _medioTransferencia = null;
                            }
                          } finally {
                            if (mounted) {
                              setState(() => _guardandoFactura = false);
                            }
                          }

                          return;
                        }

                        // ============================================================
                        // 3) USER auth -> WhatsApp (NO backend) + (opcional limpiar remoto)
                        // ============================================================
                        if (isUserAuth) {
                          await _launchWhatsAppWithCart(
                            phoneDigits: phoneDigits,
                            message: message,
                          );

                          // ✅ RECOMENDADO: NO limpiar remoto, porque aún no se pagó
                          // Si IGUAL quieres limpiar después de enviar:
                          /*
      for (final id in selectedIds) {
        await cartProvider.removeItem(token, productId: id);
      }
      */

                          cartProvider.clearSelection();
                          _pagaConController.clear();
                          return;
                        }
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    },
              child: const Text('Continuar'),
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // MÉTODOS PRIVADOS UI (SIN CAMBIOS)
  // ================================================================

  Widget _buildSummaryRow(
    String title,
    String value, {
    bool isBold = false,
    bool isLarge = false,
    bool isNegative = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: isLarge ? 18 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isLarge ? 18 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isNegative ? Colors.red : Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentOption(InvoiceProvider provider, String label) {
    final isSelected = provider.medioPago == label;

    return GestureDetector(
      onTap: () => provider.setMedioPago(label),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey[700],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
