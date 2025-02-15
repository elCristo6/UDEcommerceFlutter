import 'package:flutter/material.dart';

class SalesFooter extends StatelessWidget {
  const SalesFooter({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      // Fondo azul y esquinas superiores redondeadas
      decoration: const BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        // Distribuimos cada elemento de manera uniforme
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildFooterItem("Total Día:", 300000),
          _buildFooterItem("Efectivo:", 100000),
          _buildFooterItem("Nequi:", 50000),
          _buildFooterItem("Daviplata:", 100000),
          _buildFooterItem("Bancolombia:", 50000),
        ],
      ),
    );
  }

  /// Construye cada texto con "Etiqueta: Valor", formateando la cantidad con puntos.
  Widget _buildFooterItem(String label, int amount) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 16,
          color: Colors.white,
        ),
        children: [
          // Parte en negrita: "Total Día:" o "Efectivo:", etc.
          TextSpan(
            text: '$label ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          // Parte normal: la cantidad
          TextSpan(
            text: '\$${_formatCurrency(amount)}',
            style: const TextStyle(fontWeight: FontWeight.normal),
          ),
        ],
      ),
    );
  }

  /// Formatea el entero con puntos de miles, p. ej. 50000 -> "50.000"
  String _formatCurrency(int value) {
    final strVal = value.toString();
    return strVal.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (Match match) => '${match[1]}.',
    );
  }
}
