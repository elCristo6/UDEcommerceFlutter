import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/invoice_provider.dart';
import '../providers/product_provider.dart';

class CartSummary extends StatefulWidget {
  const CartSummary({super.key});

  @override
  State<CartSummary> createState() => _CartSummaryState();
}

class _CartSummaryState extends State<CartSummary> {
  // Por defecto se selecciona "Factura de venta"
  bool _isFacturaSelected = true;
  bool _isCotizacionSelected = false;

  String formatCurrency(int value) {
    return value.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (Match match) => '${match[1]}.',
        );
  }

  bool isWeb() {
    return identical(0, 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final invoiceProvider = Provider.of<InvoiceProvider>(context);

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ======== Título "Resumen" ========
          const Text(
            'Resumen',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),

          // ======== Subtotal ========
          _buildSummaryRow(
            'Subtotal',
            'COP ${formatCurrency(productProvider.selectedTotal.toInt())}',
          ),

          // ======== Paga con ========
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Paga con:',
                  style: TextStyle(fontSize: 14, color: Colors.black),
                ),
                SizedBox(
                  width: 100,
                  child: TextField(
                    textAlign: TextAlign.right,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 14),
                    onChanged: (value) {
                      final double pagaCon = double.tryParse(value) ?? 0.0;
                      invoiceProvider.setPagaCon(pagaCon, context);
                    },
                    decoration: const InputDecoration(
                      hintText: 'COP',
                      hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 4.0,
                      ),
                      border: OutlineInputBorder(
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ======== Cambio ========
          _buildSummaryRow(
            'Cambio:',
            'COP ${formatCurrency(invoiceProvider.cambio.toInt())}',
            isNegative: invoiceProvider.cambio < 0,
          ),

          const Divider(thickness: 1, height: 20),

          // ======== TOTAL ========
          _buildSummaryRow(
            'TOTAL:',
            'COP ${formatCurrency(productProvider.selectedTotal.toInt())}',
            isBold: true,
            isLarge: true,
          ),
          const SizedBox(height: 10),

          // ======== Medio de pago ========
          const Text(
            'Medio de pago:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 9,
            runSpacing: 10,
            children: [
              _buildPaymentOption(context, invoiceProvider, 'Efectivo'),
              _buildPaymentOption(context, invoiceProvider, 'Nequi'),
              _buildPaymentOption(context, invoiceProvider, 'Daviplata'),
              _buildPaymentOption(context, invoiceProvider, 'Bancolombia'),
            ],
          ),
          const SizedBox(height: 20),

          // =====================================================
          //            CHECKBOXES Factura o Cotización
          // =====================================================
          Row(
            children: [
              // Checkbox para FACTURA
              Checkbox(
                value: _isFacturaSelected,
                onChanged: (bool? newValue) {
                  setState(() {
                    _isFacturaSelected = true;
                    _isCotizacionSelected = false;
                  });
                },
              ),
              const Text(
                'Factura de venta',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(width: 20),

              // Checkbox para COTIZACIÓN
              Checkbox(
                value: _isCotizacionSelected,
                onChanged: (bool? newValue) {
                  setState(() {
                    _isCotizacionSelected = true;
                    _isFacturaSelected = false;
                  });
                },
              ),
              const Text(
                'Cotización',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),

          // ======== Botón Continuar ========
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                if (productProvider.selectedProducts.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Por favor selecciona al menos un producto.'),
                    ),
                  );
                  return;
                }

                try {
                  if (_isFacturaSelected) {
                    // FACTURA
                    await invoiceProvider.createInvoice(context,
                        docType: 'FACTURA DE COMPRA');
                  } else {
                    // COTIZACIÓN
                    await invoiceProvider.generatePdfLocal(context,
                        docType: 'COTIZACIÓN');
                  }
                } catch (error) {
                  // ignore: use_build_context_synchronously
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $error')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14.0),
              ),
              child: const Text(
                'Continuar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  //                 MÉTODOS PRIVADOS
  // =====================================================
  Widget _buildSummaryRow(
    String title,
    String value, {
    bool isBold = false,
    bool isLarge = false,
    bool isNegative = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: isLarge ? 18 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: Colors.black,
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
      ),
    );
  }

  Widget _buildPaymentOption(
    BuildContext context,
    InvoiceProvider invoiceProvider,
    String label,
  ) {
    final isSelected = invoiceProvider.medioPago == label;

    return GestureDetector(
      onTap: () {
        invoiceProvider.setMedioPago(label);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey[800],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
