import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/invoice_provider.dart';

class SalesFooter extends StatelessWidget {
  const SalesFooter({Key? key}) : super(key: key);

  /// Formatea el entero con puntos de miles. Ejemplo: 50000 -> "50.000"
  String _formatCurrency(int value) {
    final strVal = value.toString();
    return strVal.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (Match match) => '${match[1]}.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<InvoiceProvider>(
      builder: (context, invoiceProvider, child) {
        // Lista de ventas de hoy
        final todaysSales = invoiceProvider.todaysSales;

        // Calcula el total del día sumando el totalAmount de cada factura
        final double totalDia = todaysSales.fold(
          0.0,
          (prev, invoice) => prev + invoice.totalAmount,
        );

        // Totales por medio de pago:
        final double efectivoTotal = todaysSales
            .where((invoice) => invoice.medioPago.toLowerCase() == 'efectivo')
            .fold(0.0, (prev, invoice) => prev + invoice.totalAmount);

        final double nequiTotal = todaysSales
            .where((invoice) => invoice.medioPago.toLowerCase() == 'nequi')
            .fold(0.0, (prev, invoice) => prev + invoice.totalAmount);

        final double daviplataTotal = todaysSales
            .where((invoice) => invoice.medioPago.toLowerCase() == 'daviplata')
            .fold(0.0, (prev, invoice) => prev + invoice.totalAmount);

        final double bancolombiaTotal = todaysSales
            .where(
                (invoice) => invoice.medioPago.toLowerCase() == 'bancolombia')
            .fold(0.0, (prev, invoice) => prev + invoice.totalAmount);

        // Convertir a int (redondeado) para formatear sin decimales
        final int totalDiaInt = totalDia.round();
        final int efectivoInt = efectivoTotal.round();
        final int nequiInt = nequiTotal.round();
        final int daviplataInt = daviplataTotal.round();
        final int bancolombiaInt = bancolombiaTotal.round();

        return Container(
          // Fondo azul con esquinas superiores redondeadas
          decoration: const BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(10),
              topRight: Radius.circular(10),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildFooterItem("Total Día:", totalDiaInt),
              _buildFooterItem("Efectivo:", efectivoInt),
              _buildFooterItem("Nequi:", nequiInt),
              _buildFooterItem("Daviplata:", daviplataInt),
              _buildFooterItem("Bancolombia:", bancolombiaInt),
            ],
          ),
        );
      },
    );
  }

  /// Construye cada item del footer mostrando "Etiqueta: Valor"
  Widget _buildFooterItem(String label, int amount) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 16,
          color: Colors.white,
        ),
        children: [
          TextSpan(
            text: '$label ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          TextSpan(
            text: '\$${_formatCurrency(amount)}',
            style: const TextStyle(fontWeight: FontWeight.normal),
          ),
        ],
      ),
    );
  }
}
