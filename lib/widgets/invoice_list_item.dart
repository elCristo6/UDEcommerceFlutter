import 'package:flutter/material.dart';

import '../models/invoice_model.dart';
import '../services/pdfService.dart';

class InvoiceListItem extends StatelessWidget {
  final Invoice invoice;

  const InvoiceListItem({
    Key? key,
    required this.invoice,
  }) : super(key: key);

  // Función para formatear cantidades (ej. 50000 => "50.000")
  String _formatCurrency(num value) {
    final strVal = value.toStringAsFixed(0);
    return strVal.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (Match match) => '${match[1]}.',
    );
  }

  @override
  Widget build(BuildContext context) {
    // Extraer datos del invoice
    final String consecutivoText = invoice.consecutivo != null
        ? "Factura #${invoice.consecutivo}"
        : "Factura";
    final String cliente =
        invoice.user?.name != null ? invoice.user!.name : "Cliente";
    final String totalText = "\$${_formatCurrency(invoice.totalAmount)}";
    final String pagaConText = "\$${_formatCurrency(invoice.pagaCon)}";
    final String cambioText = "\$${_formatCurrency(invoice.cambio)}";
    final String medioPagoText = invoice.medioPago;

    // Lista de productos (los nombres, con un guión al inicio de cada uno)
    final String productosText =
        invoice.products.map((p) => "- ${p.name} x${p.quantity}").join("\n");
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ================== COLUMNA 1 ==================
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Número de factura (consecutivo)
                  Text(
                    consecutivoText,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Nombre del cliente en negrita
                  Text(
                    "Nombre: $cliente",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Total en negrita
                  Text(
                    "TOTAL: $totalText",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // ================== COLUMNA 2 ==================
            Expanded(
              flex: 3,
              child: Text(
                productosText,
                style: const TextStyle(fontSize: 14),
              ),
            ),

            // ================== COLUMNA 3 ==================
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Paga con: $pagaConText",
                    style: const TextStyle(fontSize: 14),
                  ),
                  Text(
                    "Cambio: $cambioText",
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),

            // ================== COLUMNA 4 (Íconos) ==================
            Expanded(
              flex: 1,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.print),
                    iconSize: 30.0,
                    onPressed: () async {
                      await PDFService().printInvoiceStyled(invoice,
                          docType: 'FACTURA DE VENTA');
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    iconSize: 30.0,
                    onPressed: () {
                      // Lógica para eliminar
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    iconSize: 30.0,
                    onPressed: () {
                      // Lógica para editar
                    },
                  ),
                ],
              ),
            ),

            // ================== COLUMNA 5 (Medio de pago) ==================
            Expanded(
              flex: 1,
              child: Center(
                child: Text(
                  medioPagoText,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
