
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/local_cart_item_model.dart';
import '../providers/cart_provider.dart';

class ProjectDetailsCard extends StatefulWidget {
  final LocalCartItem item;

  const ProjectDetailsCard({
    super.key,
    required this.item,
  });

  @override
  State<ProjectDetailsCard> createState() =>
      _ProjectDetailsCardState();
}

class _ProjectDetailsCardState extends State<ProjectDetailsCard> {
  late final TextEditingController _descriptionCtrl;
  late final TextEditingController _advanceCtrl;

  @override
  void initState() {
    super.initState();

    final details = widget.item.projectDetails;

    _descriptionCtrl = TextEditingController(
      text: details?.description ?? '',
    );

    _advanceCtrl = TextEditingController(
      text: details == null || details.advancePayment == 0
          ? ''
          : details.advancePayment.toStringAsFixed(0),
    );
  }

  @override
  void didUpdateWidget(covariant ProjectDetailsCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.item.productId != widget.item.productId) {
      _descriptionCtrl.text =
          widget.item.projectDetails?.description ?? '';

      final advance =
          widget.item.projectDetails?.advancePayment ?? 0;

      _advanceCtrl.text =
          advance > 0 ? advance.toStringAsFixed(0) : '';
    }
  }

  @override
  void dispose() {
    _descriptionCtrl.dispose();
    _advanceCtrl.dispose();
    super.dispose();
  }

  String _money(double value) {
    final number = value.round().toString();

    return number.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );
  }

  Future<void> _selectDeliveryDate() async {
    final provider = context.read<CartProvider>();

    final initial =
        widget.item.projectDetails?.deliveryDate ?? DateTime.now();

    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Fecha de entrega del proyecto',
      cancelText: 'Cancelar',
      confirmText: 'Seleccionar',
    );

    if (date == null || !mounted) return;

    await provider.setProjectDeliveryDate(
      widget.item.productId,
      date,
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final details = item.projectDetails;

    final total = item.commercialTotal;
    final advance = details?.advancePayment ?? 0;
    final balance = item.pendingBalance;
    final isValid = item.isProjectValid;

    final deliveryDate = details?.deliveryDate;

    final deliveryText = deliveryDate == null
        ? 'Seleccionar fecha de entrega'
        : '${deliveryDate.day.toString().padLeft(2, '0')}/'
          '${deliveryDate.month.toString().padLeft(2, '0')}/'
          '${deliveryDate.year}';

    final provider = context.read<CartProvider>();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF081525),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF1B4775),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.precision_manufacturing_outlined,
                color: Colors.lightBlueAccent,
              ),
              SizedBox(width: 8),
              Text(
                'DETALLES DEL PROYECTO',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          TextField(
            controller: _descriptionCtrl,
            maxLines: 3,
            minLines: 2,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Descripción del trabajo',
              labelStyle:
                  const TextStyle(color: Colors.white70),
              hintText:
                  'Ej. Fabricar carcasa en PLA negro, '
                  'medidas 120 x 80 mm',
              hintStyle:
                  const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: const Color(0xFF10233A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: (value) {
              provider.setProjectDescription(
                item.productId,
                value,
              );
            },
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _advanceCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Abono recibido',
                    prefixText: '\$ ',
                    prefixStyle:
                        const TextStyle(color: Colors.white),
                    labelStyle:
                        const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: const Color(0xFF10233A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) {
                    final amount =
                        double.tryParse(value) ?? 0;

                    provider.setProjectAdvancePayment(
                      item.productId,
                      amount,
                    );
                  },
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _selectDeliveryDate,
                  icon: const Icon(Icons.calendar_month),
                  label: Text(deliveryText),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.lightBlueAccent,
                    padding: const EdgeInsets.symmetric(
                      vertical: 20,
                      horizontal: 12,
                    ),
                    side: const BorderSide(
                      color: Color(0xFF28649B),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          const Divider(color: Colors.white24),

          _amountRow(
            'Valor total del proyecto',
            total,
          ),

          const SizedBox(height: 8),

          _amountRow(
            'Abono recibido',
            advance,
          ),

          const SizedBox(height: 8),

          _amountRow(
            'Saldo pendiente',
            balance,
            highlight: true,
          ),

          const SizedBox(height: 14),

          if (!isValid)
            const Text(
              'Completa la descripción, la fecha de entrega '
              'y un abono mayor a \$0 que no supere '
              'el valor del proyecto.',
              style: TextStyle(
                color: Colors.orangeAccent,
                fontSize: 12,
              ),
            )
          else
            const Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.greenAccent,
                  size: 17,
                ),
                SizedBox(width: 6),
                Text(
                  'Proyecto listo para facturar',
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _amountRow(
    String label,
    double value, {
    bool highlight = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: highlight
                ? Colors.lightBlueAccent
                : Colors.white70,
            fontWeight:
                highlight ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          '\$${_money(value)}',
          style: TextStyle(
            color: highlight
                ? Colors.lightBlueAccent
                : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: highlight ? 17 : 14,
          ),
        ),
      ],
    );
  }
}
