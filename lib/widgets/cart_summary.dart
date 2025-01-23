import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/invoice_provider.dart';
import '../providers/product_provider.dart';

class CartSummary extends StatelessWidget {
  const CartSummary({Key? key}) : super(key: key);

  String formatCurrency(int value) {
    return value.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match match) => '${match[1]}.');
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
          const Text(
            'Resumen',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          _buildSummaryRow('Subtotal',
              'COP ${formatCurrency(productProvider.selectedTotal.toInt())}'),
          _buildSummaryRow('Gastos de envío', 'COP 0'),
          _buildSummaryRow(
            'Ahorro total',
            '- 0',
            isNegative: true,
          ),
          const Divider(thickness: 1, height: 20),
          _buildSummaryRow(
            'TOTAL:',
            'COP ${formatCurrency(productProvider.selectedTotal.toInt())}',
            isBold: true,
            isLarge: true,
          ),
          const SizedBox(height: 10),

          // Sección Paga con
          const Text(
            'Paga con:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildPaymentOption(
                context,
                invoiceProvider,
                'Efectivo',
              ),
              _buildPaymentOption(
                context,
                invoiceProvider,
                'Nequi',
              ),
              _buildPaymentOption(
                context,
                invoiceProvider,
                'Daviplata',
              ),
              _buildPaymentOption(
                context,
                invoiceProvider,
                'Bancolombia',
              ),
            ],
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Transform.scale(
                scale: 1,
                child: Checkbox(
                  value: productProvider.cart.length ==
                          productProvider.selectedProducts.length &&
                      productProvider.cart.isNotEmpty,
                  onChanged: (value) {
                    if (value == true) {
                      productProvider
                          .selectAllProducts(); // Selecciona todos los productos
                    } else {
                      productProvider
                          .deselectAllProducts(); // Deselecciona todos los productos
                    }
                  },
                  shape: const CircleBorder(),
                ),
              ),
              const Text(
                'Factura de venta',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(
                width: 150,
              ),
              Transform.scale(
                scale: 1,
                child: Checkbox(
                  value: productProvider.cart.length ==
                          productProvider.selectedProducts.length &&
                      productProvider.cart.isNotEmpty,
                  onChanged: (value) {
                    if (value == true) {
                      productProvider
                          .selectAllProducts(); // Selecciona todos los productos
                    } else {
                      productProvider
                          .deselectAllProducts(); // Deselecciona todos los productos
                    }
                  },
                  shape: const CircleBorder(),
                ),
              ),
              const Text(
                'Cotizacion',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          // Botón Continuar
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                final productProvider =
                    Provider.of<ProductProvider>(context, listen: false);
                productProvider.clearCart(); // Uso del context válido
                try {
                  await invoiceProvider.createInvoice();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Factura creada exitosamente')),
                  );
                } catch (error) {
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

  Widget _buildSummaryRow(String title, String value,
      {bool isBold = false, bool isLarge = false, bool isNegative = false}) {
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
      BuildContext context, InvoiceProvider invoiceProvider, String label) {
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
