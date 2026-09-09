/*
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/loan_model.dart';
import '../providers/loan_provider.dart';
import '../providers/auth_provider.dart';

// Importaciones necesarias para reciclar el generador de PDFs
import '../services/pdfService.dart';
import '../models/invoice_model.dart';
import '../models/product_model.dart';
import '../models/user_model.dart';

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
    
    // Calculamos el total usando el customPrice de cada ítem
    final double totalCobrar = pendingItems.fold(0.0, (sum, item) => sum + (item.customPrice * item.pendingQty));
    final double pagaCon = double.tryParse(_pagaConController.text) ?? 0.0;
    final double cambio = pagaCon > totalCobrar ? pagaCon - totalCobrar : 0.0;

    return Container(
      margin: const EdgeInsets.only(top: 8.0, bottom: 8.0, right: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 6, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Resumen del Préstamo', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Unidades no devueltas:', style: TextStyle(fontSize: 16)),
              Text('$totalUnidades', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total a Cobrar:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(
                _currencyFormat.format(totalCobrar),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
              ),
            ],
          ),
          const Divider(height: 30),

          const Text('Medio de Pago:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildPaymentOption('Efectivo'),
              _buildPaymentOption('Nequi'),
              _buildPaymentOption('Daviplata'),
              _buildPaymentOption('Bancolombia'),
            ],
          ),
          const SizedBox(height: 16),

          if (_medioPago == 'Efectivo') ...[
            TextField(
              controller: _pagaConController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'El cliente paga con:',
                prefixText: '\$ ',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (val) => setState(() {}),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Cambio:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text(
                  _currencyFormat.format(cambio),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: (pagaCon > 0 && pagaCon < totalCobrar) ? Colors.red : Colors.green,
                  ),
                ),
              ],
            ),
          ],

          const Spacer(),

          // =========================================================
          // BOTÓN: PREVISUALIZAR PDF SIN FACTURAR NI CERRAR
          // =========================================================
          SizedBox(
            width: double.infinity,
            height: 45,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.blue, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.picture_as_pdf, color: Colors.blue),
              label: const Text('PREVISUALIZAR CUENTA (PDF)', style: TextStyle(color: Colors.blue, fontSize: 14, fontWeight: FontWeight.bold)),
              onPressed: () async {
                if (totalUnidades == 0) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No hay productos para previsualizar.')));
                  return;
                }

                // 1. Mapeamos los ítems prestados al formato Product de tu sistema
                final productsForPdf = pendingItems.map((item) {
                  return Product(
                    id: item.productId,
                    name: item.productName,
                    price: item.customPrice, // Mantiene el precio especial
                    description: '',
                    stock: 0,
                    category: '',
                    images: item.image.isNotEmpty ? [item.image] : [],
                    quantity: item.pendingQty, // Cantidad pendiente
                  );
                }).toList();

                // 2. Construimos una factura temporal solo para armar el PDF
                final previewInvoice = Invoice(
                  id: "preview-${widget.loan?.id ?? 'temp'}",
                  user: User(
                    id: widget.client.id,
                    name: widget.client.name,
                    phone: widget.client.phone,
                    nit: widget.client.detalles, 
                    email: '', 
                    role: 'store'
                  ),
                  products: productsForPdf,
                  totalAmount: totalCobrar,
                  // ✅ AQUÍ ESTÁ EL CAMBIO: Pasamos los valores calculados en la interfaz
                  medioPago: _medioPago, 
                  pagaCon: pagaCon,      
                  cambio: cambio,        
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );

                // 3. Imprimimos reutilizando PDFService, pero con título diferente
                await PDFService().printInvoiceStyled(previewInvoice, docType: 'ESTADO DE CUENTA');
              },
            ),
          ),
          const SizedBox(height: 12),

          // =========================================================
          // BOTÓN ORIGINAL: FINALIZAR Y FACTURAR (Cierra el préstamo)
          // =========================================================
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.receipt_long, color: Colors.white),
              label: const Text('FINALIZAR Y FACTURAR', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              onPressed: () async {
                if (totalUnidades == 0) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No hay productos pendientes por facturar.')));
                  return;
                }

                final token = context.read<AuthProvider>().token ?? '';
                final success = await context.read<LoanProvider>().finalizeAndBill(
                  token,
                  loanId: widget.loan!.id,
                  medioPago: _medioPago,
                  pagaCon: pagaCon,
                );

                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Préstamo facturado correctamente.')));
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}*/
// loan_summary_card.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/loan_model.dart';
import '../providers/loan_provider.dart';
import '../providers/auth_provider.dart';
import '../services/pdfService.dart';
import '../models/invoice_model.dart';
import '../models/product_model.dart';
import '../models/user_model.dart';

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
    final loanProvider = context.watch<LoanProvider>();
    final allPendingItems = widget.loan?.items.where((it) => it.pendingQty > 0).toList() ?? [];
    
    // ✅ FILTRAMOS: Solo trabajamos con los ítems que el usuario dejó seleccionados
    final pendingItems = allPendingItems.where((it) => loanProvider.isItemSelected(it.id)).toList();
    
    final int totalUnidades = pendingItems.fold(0, (sum, item) => sum + item.pendingQty);
    final double totalCobrar = pendingItems.fold(0.0, (sum, item) => sum + (item.customPrice * item.pendingQty));
    final double pagaCon = double.tryParse(_pagaConController.text) ?? 0.0;
    final double cambio = pagaCon > totalCobrar ? pagaCon - totalCobrar : 0.0;

    return Container(
      margin: const EdgeInsets.only(top: 8.0, bottom: 8.0, right: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 6, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Resumen del Préstamo', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Items seleccionados:', style: TextStyle(fontSize: 16)),
              Text('$totalUnidades', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total a Cobrar:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(
                _currencyFormat.format(totalCobrar),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
              ),
            ],
          ),
          const Divider(height: 30),

          const Text('Medio de Pago:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildPaymentOption('Efectivo'),
              _buildPaymentOption('Nequi'),
              _buildPaymentOption('Daviplata'),
              _buildPaymentOption('Bancolombia'),
            ],
          ),
          const SizedBox(height: 16),

          if (_medioPago == 'Efectivo') ...[
            TextField(
              controller: _pagaConController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'El cliente paga con:',
                prefixText: '\$ ',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (val) => setState(() {}),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Cambio:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text(
                  _currencyFormat.format(cambio),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: (pagaCon > 0 && pagaCon < totalCobrar) ? Colors.red : Colors.green,
                  ),
                ),
              ],
            ),
          ],

          const Spacer(),

          SizedBox(
            width: double.infinity,
            height: 45,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.blue, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.picture_as_pdf, color: Colors.blue),
              label: const Text('PREVISUALIZAR CUENTA', style: TextStyle(color: Colors.blue, fontSize: 14, fontWeight: FontWeight.bold)),
              onPressed: () async {
                if (totalUnidades == 0) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecciona productos para previsualizar.')));
                  return;
                }

                final productsForPdf = pendingItems.map((item) {
                  return Product(
                    id: item.productId,
                    name: item.productName,
                    price: item.customPrice,
                    description: '',
                    stock: 0,
                    category: '',
                    images: item.image.isNotEmpty ? [item.image] : [],
                    quantity: item.pendingQty, 
                  );
                }).toList();

                final previewInvoice = Invoice(
                  id: "preview-${widget.loan?.id ?? 'temp'}",
                  user: User(
                    id: widget.client.id,
                    name: widget.client.name,
                    phone: widget.client.phone,
                    nit: widget.client.detalles, 
                    email: '', 
                    role: 'store'
                  ),
                  products: productsForPdf,
                  totalAmount: totalCobrar,
                  medioPago: _medioPago, 
                  pagaCon: pagaCon,      
                  cambio: cambio,        
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );

                await PDFService().printInvoiceStyled(previewInvoice, docType: 'ESTADO DE CUENTA');
              },
            ),
          ),
          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.receipt_long, color: Colors.white),
              label: const Text('FINALIZAR Y FACTURAR', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              onPressed: () async {
                if (totalUnidades == 0) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecciona al menos un producto.')));
                  return;
                }

                // Extraemos únicamente los IDs de los ítems seleccionados
                final selectedItemIds = pendingItems.map((e) => e.id).toList();

                // ✅ SE MUESTRA EL MODAL DE CONFIRMACIÓN ANTES DE ENVIAR
                showDialog(
                  context: context,
                  builder: (dialogCtx) {
                    return AlertDialog(
                      title: const Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.orange),
                          SizedBox(width: 8),
                          Text('Confirmar Facturación'),
                        ],
                      ),
                      content: Text(
                        'Estás a punto de facturar $totalUnidades artículo(s) por un total de ${_currencyFormat.format(totalCobrar)} pagando con $_medioPago.\n\n¿Deseas continuar?'
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogCtx),
                          child: const Text('Revisar de nuevo', style: TextStyle(color: Colors.red)),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          onPressed: () async {
                            Navigator.pop(dialogCtx); // Cerramos el modal primero
                            
                            final token = context.read<AuthProvider>().token ?? '';
                            
                            final success = await context.read<LoanProvider>().finalizeAndBill(
                              token,
                              loanId: widget.loan!.id,
                              medioPago: _medioPago,
                              pagaCon: pagaCon,
                              selectedItemIds: selectedItemIds,
                            );

                            if (success && mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Préstamo facturado correctamente.')));
                            }
                          },
                          child: const Text('Sí, Facturar', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}