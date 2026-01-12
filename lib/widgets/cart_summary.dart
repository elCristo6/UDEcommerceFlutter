/*

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

  String formatCurrency(int value) {
    return value.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  @override
  void dispose() {
    _pagaConController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final invoiceProvider = Provider.of<InvoiceProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    // Solo para validar si hay selección al dar "Continuar"
    final selectedItems =
        invoiceProvider.resolveSelectedItemsFromCart(cartProvider.cart);
    final subtotal = invoiceProvider.subtotal;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
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
            'COP ${formatCurrency(subtotal.toInt())}',
          ),

          const SizedBox(height: 10),

          // ==================== PAGA CON (SIN BORDE) ====================
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Paga con:'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                width: 130,
                child: TextField(
                  controller: _pagaConController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.right,
                  onChanged: (value) {
                    final pagaCon = double.tryParse(value) ?? 0.0;
                    // 🔥 Cambio se actualiza en vivo
                    invoiceProvider.setPagaCon(pagaCon);
                  },
                  decoration: const InputDecoration(
                    hintText: 'COP',
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
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
            'COP ${formatCurrency(invoiceProvider.cambio.toInt())}',
            isNegative: invoiceProvider.cambio < 0,
          ),

          const Divider(height: 30),

          // ==================== TOTAL ====================
          _buildSummaryRow(
            'TOTAL:',
            'COP ${formatCurrency(subtotal.toInt())}',
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
              _buildPaymentOption(invoiceProvider, 'Daviplata'),
              _buildPaymentOption(invoiceProvider, 'Bancolombia'),
            ],
          ),

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
              onPressed: () async {
                if (selectedItems.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('No hay productos seleccionados.'),
                    ),
                  );
                  return;
                }

                try {
                  if (_isFacturaSelected) {
                    await invoiceProvider.createInvoiceFromCart(context);
                  } else {
                    await invoiceProvider.generatePdfFromCart(context);
                  }

                  // 🔥 el provider ya limpia selección y totales
                  _pagaConController.clear();
                } catch (e) {
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
  // MÉTODOS PRIVADOS
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
*/

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

  String formatCurrency(int value) {
    return value.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  @override
  Widget build(BuildContext context) {
    final invoiceProvider = Provider.of<InvoiceProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context);

    // Resolvemos items seleccionados desde el provider (por si quieres validar)
    final selectedItems =
        invoiceProvider.resolveSelectedItemsFromCart(cartProvider.cart);

    final subtotal = invoiceProvider.subtotal;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
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
            'COP ${formatCurrency(subtotal.toInt())}',
          ),

          const SizedBox(height: 10),

          // ==================== PAGA CON ====================
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Paga con:'),
              SizedBox(
                width: 120,
                child: TextField(
                  controller: _pagaConController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.right,
                  onChanged: (value) {
                    final pagaCon = double.tryParse(value) ?? 0.0;
                    invoiceProvider.setPagaCon(pagaCon); // cambio en vivo
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
            'COP ${formatCurrency(invoiceProvider.cambio.toInt())}',
            isNegative: invoiceProvider.cambio < 0,
          ),

          const Divider(height: 30),

          // ==================== TOTAL ====================
          _buildSummaryRow(
            'TOTAL:',
            'COP ${formatCurrency(subtotal.toInt())}',
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
              _buildPaymentOption(invoiceProvider, 'Daviplata'),
              _buildPaymentOption(invoiceProvider, 'Bancolombia'),
            ],
          ),

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
              onPressed: () async {
                if (selectedItems.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('No hay productos seleccionados.'),
                    ),
                  );
                  return;
                }

                try {
                  if (_isFacturaSelected) {
                    await invoiceProvider.createInvoiceFromCart(context);
                  } else {
                    await invoiceProvider.generatePdfFromCart(context);
                  }

                  // El provider ya limpia selección y totales en clearSelections()
                  _pagaConController.clear();
                } catch (e) {
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
  // MÉTODOS PRIVADOS
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
