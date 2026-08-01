// loan_summary_card.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/loan_model.dart';
import '../providers/loan_provider.dart';
import '../providers/auth_provider.dart';

class LoanSummaryCard extends StatefulWidget {
  final LoanModel? loan;
  final LoanClient client;

  const LoanSummaryCard({Key? key, this.loan, required this.client}) : super(key: key);

  @override
  State<LoanSummaryCard> createState() => _LoanSummaryCardState();
}

class _LoanSummaryCardState extends State<LoanSummaryCard> {
  String _medioPago = 'Efectivo';
  final TextEditingController _pagaConController = TextEditingController();
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);

  @override
  void dispose() {
    _pagaConController.dispose();
    super.dispose();
  }

  Widget _buildPaymentOption(String label) {
    final isSelected = _medioPago == label;
    return GestureDetector(
      onTap: () => setState(() => _medioPago = label),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey[700],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pendingItems = widget.loan?.items.where((it) => it.pendingQty > 0).toList() ?? [];
    
    final int totalUnidades = pendingItems.fold(0, (sum, item) => sum + item.pendingQty);
    final double totalCOP = pendingItems.fold(0.0, (sum, item) => sum + (item.pendingQty * item.customPrice));

    final double pagaCon = double.tryParse(_pagaConController.text) ?? 0.0;
    final double cambio = (pagaCon > totalCOP) ? (pagaCon - totalCOP) : 0.0;

    return Container(
      margin: const EdgeInsets.only(top: 8.0, bottom: 8.0, right: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.08), spreadRadius: 2, blurRadius: 6, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Resumen de Factura', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Unidades Pendientes:', style: TextStyle(fontSize: 15)),
              Text('$totalUnidades', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total a Cobrar:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text(
                _currencyFormat.format(totalCOP),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ],
          ),
          const SizedBox(height: 15),
          const Divider(height: 20),
          const Text('Medio de pago:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: [
              _buildPaymentOption('Efectivo'),
              _buildPaymentOption('Nequi'),
              _buildPaymentOption('Daviplata'),
              _buildPaymentOption('Bancolombia'),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Paga con:'),
              SizedBox(
                width: 130,
                child: TextField(
                  controller: _pagaConController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.right,
                  decoration: const InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    hintText: 'COP',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(),
                  ),
                  style: const TextStyle(fontSize: 14),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          if (_medioPago == 'Efectivo' && pagaCon > 0) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Cambio:'),
                Text(_currencyFormat.format(cambio), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.blue)),
              ],
            ),
          ],
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              icon: const Icon(Icons.receipt_long, color: Colors.white),
              onPressed: (widget.loan == null || totalUnidades == 0)
                  ? null
                  : () async {
                      final token = context.read<AuthProvider>().token ?? '';

                      final success = await context.read<LoanProvider>().finalizeAndBill(
                        token,
                        loanId: widget.loan!.id,
                        medioPago: _medioPago,
                        pagaCon: pagaCon > 0 ? pagaCon : totalCOP,
                        
                      );

                      if (success && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('¡Préstamo facturado correctamente con precios especiales!')),
                        );
                        _pagaConController.clear();
                      }
                    },
              label: const Text('FACTURAR Y CERRAR', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}