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
  State<ProjectDetailsCard> createState() => _ProjectDetailsCardState();
}

class _ProjectDetailsCardState extends State<ProjectDetailsCard> {
  late final TextEditingController _descriptionCtrl;
  late final TextEditingController _advanceCtrl;

  static const Color _primary = Color(0xFF2563EB);
  static const Color _text = Color(0xFF172033);
  static const Color _muted = Color(0xFF64748B);
  static const Color _border = Color(0xFFE2E8F0);
  static const Color _background = Color(0xFFFAFBFE);

  @override
  void initState() {
    super.initState();
    _loadControllers();
  }

  void _loadControllers() {
    final details = widget.item.projectDetails;

    _descriptionCtrl = TextEditingController(
      text: details?.description ?? '',
    );

    final advance = details?.advancePayment ?? 0.0;

    _advanceCtrl = TextEditingController(
      text: advance > 0 ? advance.toStringAsFixed(0) : '',
    );
  }

  @override
  void didUpdateWidget(covariant ProjectDetailsCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.item.productId != widget.item.productId) {
      _descriptionCtrl.text = widget.item.projectDetails?.description ?? '';

      final advance = widget.item.projectDetails?.advancePayment ?? 0.0;

      _advanceCtrl.text = advance > 0 ? advance.toStringAsFixed(0) : '';
    }
  }

  @override
  void dispose() {
    _descriptionCtrl.dispose();
    _advanceCtrl.dispose();
    super.dispose();
  }

  String _money(num value) {
    return value.round().toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]}.',
        );
  }

  Future<void> _selectDeliveryDate() async {
    final provider = context.read<CartProvider>();

    final initial = widget.item.projectDetails?.deliveryDate ?? DateTime.now();

    final today = DateTime.now();
    final firstDate = DateTime(today.year, today.month, today.day);

    final date = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(firstDate) ? firstDate : initial,
      firstDate: firstDate,
      lastDate: DateTime(2100),
      helpText: 'Fecha de entrega',
      cancelText: 'Cancelar',
      confirmText: 'Seleccionar',
    );

    if (date == null || !mounted) return;

    await provider.setProjectDeliveryDate(
      widget.item.productId,
      date,
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    Widget? prefix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xFF94A3B8),
        fontSize: 13,
      ),
      prefixIcon: prefix,
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 13,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
          color: _primary,
          width: 1.4,
        ),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _text,
        ),
      ),
    );
  }

  Widget _financialItem({
    required String label,
    required double amount,
    Color? color,
    bool emphasize = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: _muted,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          '\$${_money(amount)}',
          style: TextStyle(
            fontSize: emphasize ? 17 : 15,
            fontWeight: FontWeight.w700,
            color: color ?? _text,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final details = item.projectDetails;

    final double total = item.commercialTotal;
    final double advance = details?.advancePayment ?? 0.0;
    final double balance = item.pendingBalance;

    final bool isValid = item.isProjectValid;
    final deliveryDate = details?.deliveryDate;

    final deliveryText = deliveryDate == null
        ? 'Seleccionar fecha'
        : '${deliveryDate.day.toString().padLeft(2, '0')}/'
            '${deliveryDate.month.toString().padLeft(2, '0')}/'
            '${deliveryDate.year}';

    final provider = context.read<CartProvider>();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ENCABEZADO
          Row(
            children: [
              const Icon(
                Icons.assignment_outlined,
                size: 19,
                color: _primary,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Información del proyecto',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _text,
                  ),
                ),
              ),
              Icon(
                isValid ? Icons.check_circle_outline : Icons.info_outline,
                size: 18,
                color:
                    isValid ? const Color(0xFF16A34A) : const Color(0xFFD97706),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // DESCRIPCIÓN
          _fieldLabel('Descripción del trabajo *'),

          TextField(
            controller: _descriptionCtrl,
            minLines: 2,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            style: const TextStyle(
              fontSize: 13,
              color: _text,
            ),
            decoration: _inputDecoration(
              hint: 'Describe el trabajo solicitado...',
            ),
            onChanged: (value) {
              provider.setProjectDescription(
                item.productId,
                value,
              );
            },
          ),

          const SizedBox(height: 13),

          // ABONO Y FECHA
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 420;

              final abonoField = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _fieldLabel('Abono recibido *'),
                  TextField(
                    controller: _advanceCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _text,
                    ),
                    decoration: _inputDecoration(
                      hint: '0',
                      prefix: const Icon(
                        Icons.payments_outlined,
                        size: 18,
                        color: _muted,
                      ),
                    ).copyWith(prefixText: '\$ '),
                    onChanged: (value) {
                      final amount = double.tryParse(value) ?? 0.0;

                      provider.setProjectAdvancePayment(
                        item.productId,
                        amount,
                      );
                    },
                  ),
                ],
              );

              final fechaField = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _fieldLabel('Fecha de entrega *'),
                  SizedBox(
                    width: double.infinity,
                    height: 43,
                    child: OutlinedButton.icon(
                      onPressed: _selectDeliveryDate,
                      icon: const Icon(
                        Icons.calendar_today_outlined,
                        size: 17,
                      ),
                      label: Text(
                        deliveryText,
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _primary,
                        backgroundColor: Colors.white,
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                        ),
                        textStyle: const TextStyle(fontSize: 12),
                        side: const BorderSide(color: _border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              );

              if (compact) {
                return Column(
                  children: [
                    abonoField,
                    const SizedBox(height: 12),
                    fechaField,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: abonoField),
                  const SizedBox(width: 12),
                  Expanded(child: fechaField),
                ],
              );
            },
          ),

          const SizedBox(height: 15),

          // RESUMEN FINANCIERO
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final items = [
                  _financialItem(
                    label: 'Valor total',
                    amount: total,
                  ),
                  _financialItem(
                    label: 'Abono recibido',
                    amount: advance,
                    color: const Color(0xFF15803D),
                  ),
                  _financialItem(
                    label: 'Saldo pendiente',
                    amount: balance,
                    color: _primary,
                    emphasize: true,
                  ),
                ];

                if (constraints.maxWidth < 380) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < items.length; i++) ...[
                        if (i > 0) const SizedBox(height: 10),
                        items[i],
                      ],
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final financialItem in items)
                      Expanded(child: financialItem),
                  ],
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          // ESTADO DE VALIDACIÓN
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                isValid ? Icons.check_circle_outline : Icons.info_outline,
                size: 15,
                color:
                    isValid ? const Color(0xFF15803D) : const Color(0xFFB45309),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  isValid
                      ? 'Proyecto listo para facturar'
                      : 'Completa la descripción, fecha y un abono '
                          'mayor a \$0 y no superior al total.',
                  style: TextStyle(
                    fontSize: 11,
                    color: isValid
                        ? const Color(0xFF15803D)
                        : const Color(0xFF92400E),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
