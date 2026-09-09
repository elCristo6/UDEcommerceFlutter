
// loan_product_list.dart

/*
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../models/loan_model.dart';
import '../providers/loan_provider.dart';
import '../providers/product_provider.dart';
import '../providers/auth_provider.dart';

class LoanProductList extends StatefulWidget {
  final LoanModel? loan;
  final LoanClient client;
  final VoidCallback? onItemPriceChanged;

  const LoanProductList({
    Key? key,
    this.loan,
    required this.client,
    this.onItemPriceChanged,
  }) : super(key: key);

  @override
  State<LoanProductList> createState() => _LoanProductListState();
}

class _LoanProductListState extends State<LoanProductList> {
  bool _isSearchActive = false;
  final FocusNode _searchFocusNode = FocusNode();
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);
  final Map<String, Timer> _debounceTimers = {};

  @override
  void dispose() {
    _searchFocusNode.dispose();
    for (var timer in _debounceTimers.values) {
      timer.cancel();
    }
    super.dispose();
  }

  Future<int?> _askForQuantity(BuildContext context, String productName, int maxStock) async {
    final TextEditingController qtyCtrl = TextEditingController(text: '1');
    return showDialog<int>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Prestar: $productName', style: const TextStyle(fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Stock disponible: $maxStock'),
              const SizedBox(height: 10),
              TextField(
                controller: qtyCtrl,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  labelText: 'Cantidad a prestar',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text('Cancelar', style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: () {
                int qty = int.tryParse(qtyCtrl.text) ?? 0;
                Navigator.pop(ctx, qty);
              },
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }

  // Envía el precio modificado al backend Node.js
  Future<void> _saveCustomPrice(LoanItem item, String value) async {
    final double newP = double.tryParse(value) ?? item.productPrice;
    
    if (widget.loan != null && widget.loan!.id.isNotEmpty && item.id.isNotEmpty) {
      final token = context.read<AuthProvider>().token ?? '';
      await context.read<LoanProvider>().updateItemPrice(
        token,
        loanId: widget.loan!.id,
        itemId: item.id,
        newPrice: newP,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.loan?.items.where((it) => it.pendingQty > 0).toList() ?? [];

    return GestureDetector(
      onTap: () {
        if (_isSearchActive) setState(() => _isSearchActive = false);
        FocusScope.of(context).unfocus();
      },
      child: Container(
        margin: const EdgeInsets.only(top: 8.0, bottom: 8.0, left: 8.0, right: 4.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(color: Colors.grey.withOpacity(0.08), spreadRadius: 2, blurRadius: 6, offset: const Offset(0, 3)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.black12))),
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          items.isEmpty ? 'Nueva Cesta' : 'Artículos (${items.length})',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(
                          width: 300,
                          child: TextField(
                            focusNode: _searchFocusNode,
                            decoration: InputDecoration(
                              hintText: 'Buscar Producto para prestar...',
                              prefixIcon: const Icon(Icons.search, color: Colors.grey),
                              filled: true,
                              fillColor: Colors.white,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                borderSide: const BorderSide(color: Colors.blue, width: 2),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                borderSide: const BorderSide(color: Colors.grey, width: 1),
                              ),
                            ),
                            onTap: () => setState(() => _isSearchActive = true),
                            onChanged: (value) => context.read<ProductProvider>().filterProducts(value),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: items.isEmpty
                        ? const Center(
                            child: Text('Usa el buscador para agregar productos al préstamo.', style: TextStyle(fontSize: 16, color: Colors.grey)),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(8),
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              final item = items[index];

                              String fechaItem = '';
                              if (item.createdAt != null) {
                                final localDate = item.createdAt!.toLocal();
                                fechaItem = DateFormat("dd MMM - hh:mm a").format(localDate);
                              }

                              String displayImage = item.image;
                              if (displayImage.isEmpty) {
                                final catalog = context.read<ProductProvider>().products;
                                final idx = catalog.indexWhere((p) => p.id == item.productId);
                                if (idx != -1 && catalog[idx].images.isNotEmpty) {
                                  displayImage = catalog[idx].images.first;
                                }
                              }

                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                elevation: 2,
                                child: Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      displayImage.isNotEmpty
                                          ? ClipRRect(
                                              borderRadius: BorderRadius.circular(6),
                                              child: Image.network(
                                                Uri.encodeFull(displayImage),
                                                width: 55,
                                                height: 55,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 55, color: Colors.grey),
                                              ),
                                            )
                                          : const Icon(Icons.inventory_2, color: Colors.blue, size: 55),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.productName,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Prestados: ${item.qtyBorrowed}  |  Pendientes: ${item.pendingQty}',
                                              style: const TextStyle(fontSize: 13, color: Colors.black87),
                                            ),
                                            if (fechaItem.isNotEmpty)
                                              Text('🕒 $fechaItem', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),

                                      // Campo para Precio Especial
                                      SizedBox(
                                        width: 135,
                                        child: Column(
                                          // ✅ CORREGIDO: CrossAxisAlignment.end
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.end,
                                              children: [
                                                Text(
                                                  item.customPrice != item.productPrice ? 'Precio Modificado:' : 'Precio Especial:',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: item.customPrice != item.productPrice ? Colors.orange[800] : Colors.grey,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 2),
                                            TextFormField(
  // 1. SOLUCIÓN AL TECLADO: El Key solo debe depender del ID, no del precio.
  key: ValueKey(item.id), 
  initialValue: item.customPrice.toInt().toString(),
  keyboardType: TextInputType.number,
  textAlign: TextAlign.right,
  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue),
  decoration: const InputDecoration(
    isDense: true,
    prefixText: '\$ ',
    contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
    border: OutlineInputBorder(),
  ),
  onChanged: (val) {
    final newP = double.tryParse(val) ?? item.productPrice;
    
    // Actualizamos los totales visuales en la pantalla inmediatamente
    setState(() {
      item.customPrice = newP;
    });
    if (widget.onItemPriceChanged != null) {
      widget.onItemPriceChanged!();
    }

    // 2. LÓGICA DE AUTO-GUARDADO INTUITIVO (DEBOUNCE)
    // Si el usuario sigue escribiendo, cancelamos el guardado anterior
    if (_debounceTimers[item.id] != null) {
      _debounceTimers[item.id]!.cancel();
    }
    
    // Creamos una nueva espera de 800 milisegundos.
    // Si deja de escribir por casi 1 segundo, se guarda solo en el Backend Node.js
    _debounceTimers[item.id] = Timer(const Duration(milliseconds: 800), () {
      _saveCustomPrice(item, val);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Precio actualizado en la base de datos', style: TextStyle(fontSize: 12)),
          duration: Duration(seconds: 1),
          backgroundColor: Colors.green,
        )
      );
    });
  },
  // Por si el usuario presiona el botón "Check/Enter" en el teclado de su celular
  onFieldSubmitted: (val) {
    if (_debounceTimers[item.id] != null) {
      _debounceTimers[item.id]!.cancel();
    }
    _saveCustomPrice(item, val);
  },
),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Subtotal: ${_currencyFormat.format(item.customPrice * item.pendingQty)}',
                                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 10),

                                      if (widget.loan != null)
                                        ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.orange,
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                          ),
                                          icon: const Icon(Icons.undo, color: Colors.white, size: 16),
                                          label: const Text('Devolver 1', style: TextStyle(color: Colors.white, fontSize: 12)),
                                          onPressed: () async {
                                            final token = context.read<AuthProvider>().token ?? '';
                                            await context.read<LoanProvider>().returnProduct(token, widget.loan!.id, item.id, 1);
                                          },
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),

              if (_isSearchActive)
                Positioned(
                  top: 75,
                  right: 16,
                  child: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(8.0),
                    child: Container(
                      width: 300,
                      constraints: const BoxConstraints(maxHeight: 300),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8.0)),
                      child: Consumer<ProductProvider>(
                        builder: (context, productProvider, _) {
                          if (productProvider.isLoading) return const Padding(padding: EdgeInsets.all(20.0), child: Center(child: CircularProgressIndicator()));
                          return ListView.builder(
                            shrinkWrap: true,
                            itemCount: productProvider.filteredProducts.length,
                            itemBuilder: (context, index) {
                              final product = productProvider.filteredProducts[index];
                              return ListTile(
                                leading: product.images.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: Image.network(
                                          Uri.encodeFull(product.images.first),
                                          width: 55,
                                          height: 55,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 55, color: Colors.grey),
                                        ),
                                      )
                                    : const Icon(Icons.image, size: 55, color: Colors.grey),
                                title: Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                                subtitle: Text('Stock: ${product.stock} | Base: ${_currencyFormat.format(product.price)}', style: const TextStyle(fontSize: 11)),
                                onTap: () async {
                                  if (product.stock <= 0) {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sin stock')));
                                    return;
                                  }
                                  if (widget.client.id.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: Cliente inválido')));
                                    return;
                                  }

                                  final int? qtySelected = await _askForQuantity(context, product.name, product.stock);

                                  if (qtySelected == null || qtySelected <= 0) return;
                                  if (qtySelected > product.stock) {
                                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Stock insuficiente')));
                                    return;
                                  }

                                  final token = context.read<AuthProvider>().token ?? '';

                                  await context.read<LoanProvider>().loanService.createLoanBatch(
                                    token,
                                    clientId: widget.client.id,
                                    items: [{"productId": product.id, "qty": qtySelected}],
                                  );

                                  await context.read<LoanProvider>().fetchStoresAndLoans(token);
                                  setState(() => _isSearchActive = false);
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}*/

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../models/loan_model.dart';
import '../providers/loan_provider.dart';
import '../providers/product_provider.dart';
import '../providers/auth_provider.dart';

class LoanProductList extends StatefulWidget {
  final LoanModel? loan;
  final LoanClient client;
  final VoidCallback? onItemPriceChanged;

  const LoanProductList({
    Key? key,
    this.loan,
    required this.client,
    this.onItemPriceChanged,
  }) : super(key: key);

  @override
  State<LoanProductList> createState() => _LoanProductListState();
}

class _LoanProductListState extends State<LoanProductList> {
  bool _isSearchActive = false;
  final FocusNode _searchFocusNode = FocusNode();
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);
  final Map<String, Timer> _debounceTimers = {};

  @override
  void dispose() {
    _searchFocusNode.dispose();
    for (var timer in _debounceTimers.values) {
      timer.cancel();
    }
    super.dispose();
  }

  Future<int?> _askForQuantity(BuildContext context, String productName, int maxStock) async {
    final TextEditingController qtyCtrl = TextEditingController(text: '1');
    return showDialog<int>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Prestar: $productName', style: const TextStyle(fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Stock disponible: $maxStock'),
              const SizedBox(height: 10),
              TextField(
                controller: qtyCtrl,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  labelText: 'Cantidad a prestar',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text('Cancelar', style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: () {
                int qty = int.tryParse(qtyCtrl.text) ?? 0;
                Navigator.pop(ctx, qty);
              },
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveCustomPrice(LoanItem item, String value) async {
    final double newP = double.tryParse(value) ?? item.productPrice;
    
    if (widget.loan != null && widget.loan!.id.isNotEmpty && item.id.isNotEmpty) {
      final token = context.read<AuthProvider>().token ?? '';
      await context.read<LoanProvider>().updateItemPrice(
        token,
        loanId: widget.loan!.id,
        itemId: item.id,
        newPrice: newP,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.loan?.items.where((it) => it.pendingQty > 0).toList() ?? [];

    return GestureDetector(
      onTap: () {
        if (_isSearchActive) setState(() => _isSearchActive = false);
        FocusScope.of(context).unfocus();
      },
      child: Container(
        margin: const EdgeInsets.only(top: 8.0, bottom: 8.0, left: 8.0, right: 4.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(color: Colors.grey.withOpacity(0.08), spreadRadius: 2, blurRadius: 6, offset: const Offset(0, 3)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.black12))),
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          items.isEmpty ? 'Nueva Cesta' : 'Artículos (${items.length})',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(
                          width: 300,
                          child: TextField(
                            focusNode: _searchFocusNode,
                            decoration: InputDecoration(
                              hintText: 'Buscar Producto para prestar...',
                              prefixIcon: const Icon(Icons.search, color: Colors.grey),
                              filled: true,
                              fillColor: Colors.white,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                borderSide: const BorderSide(color: Colors.blue, width: 2),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                borderSide: const BorderSide(color: Colors.grey, width: 1),
                              ),
                            ),
                            onTap: () => setState(() => _isSearchActive = true),
                            onChanged: (value) => context.read<ProductProvider>().filterProducts(value),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: items.isEmpty
                        ? const Center(
                            child: Text('Usa el buscador para agregar productos al préstamo.', style: TextStyle(fontSize: 16, color: Colors.grey)),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(8),
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              final item = items[index];
                              final isSelected = context.watch<LoanProvider>().isItemSelected(item.id);

                              String fechaItem = '';
                              if (item.createdAt != null) {
                                final localDate = item.createdAt!.toLocal();
                                fechaItem = DateFormat("dd MMM - hh:mm a").format(localDate);
                              }

                              String displayImage = item.image;
                              if (displayImage.isEmpty) {
                                final catalog = context.read<ProductProvider>().products;
                                final idx = catalog.indexWhere((p) => p.id == item.productId);
                                if (idx != -1 && catalog[idx].images.isNotEmpty) {
                                  displayImage = catalog[idx].images.first;
                                }
                              }

                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                elevation: 2,
                                child: Opacity(
                                  // Si lo deseleccionan, atenuamos visualmente la tarjeta un poco
                                  opacity: isSelected ? 1.0 : 0.6,
                                  child: Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        // ✅ NUEVO: Checkbox Selector
                                        Transform.scale(
                                          scale: 1.2,
                                          child: Checkbox(
                                            value: isSelected,
                                            shape: const CircleBorder(),
                                            activeColor: Colors.blue,
                                            onChanged: (bool? val) {
                                              context.read<LoanProvider>().toggleItemSelection(item.id, val ?? true);
                                            },
                                          ),
                                        ),
                                        displayImage.isNotEmpty
                                            ? ClipRRect(
                                                borderRadius: BorderRadius.circular(6),
                                                child: Image.network(
                                                  Uri.encodeFull(displayImage),
                                                  width: 55,
                                                  height: 55,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 55, color: Colors.grey),
                                                ),
                                              )
                                            : const Icon(Icons.inventory_2, color: Colors.blue, size: 55),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.productName,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Prestados: ${item.qtyBorrowed}  |  Pendientes: ${item.pendingQty}',
                                                style: const TextStyle(fontSize: 13, color: Colors.black87),
                                              ),
                                              if (fechaItem.isNotEmpty)
                                                Text('🕒 $fechaItem', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),

                                        SizedBox(
                                          width: 135,
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.end,
                                                children: [
                                                  Text(
                                                    item.customPrice != item.productPrice ? 'Precio Modificado:' : 'Precio Especial:',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                      color: item.customPrice != item.productPrice ? Colors.orange[800] : Colors.grey,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 2),
                                              TextFormField(
                                                key: ValueKey(item.id), 
                                                initialValue: item.customPrice.toInt().toString(),
                                                keyboardType: TextInputType.number,
                                                textAlign: TextAlign.right,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue),
                                                decoration: const InputDecoration(
                                                  isDense: true,
                                                  prefixText: '\$ ',
                                                  contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                                                  border: OutlineInputBorder(),
                                                ),
                                                onChanged: (val) {
                                                  final newP = double.tryParse(val) ?? item.productPrice;
                                                  
                                                  setState(() {
                                                    item.customPrice = newP;
                                                  });
                                                  if (widget.onItemPriceChanged != null) {
                                                    widget.onItemPriceChanged!();
                                                  }

                                                  if (_debounceTimers[item.id] != null) {
                                                    _debounceTimers[item.id]!.cancel();
                                                  }
                                                  
                                                  _debounceTimers[item.id] = Timer(const Duration(milliseconds: 800), () {
                                                    _saveCustomPrice(item, val);
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      const SnackBar(
                                                        content: Text('Precio actualizado en la base de datos', style: TextStyle(fontSize: 12)),
                                                        duration: Duration(seconds: 1),
                                                        backgroundColor: Colors.green,
                                                      )
                                                    );
                                                  });
                                                },
                                                onFieldSubmitted: (val) {
                                                  if (_debounceTimers[item.id] != null) {
                                                    _debounceTimers[item.id]!.cancel();
                                                  }
                                                  _saveCustomPrice(item, val);
                                                },
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Subtotal: ${_currencyFormat.format(item.customPrice * item.pendingQty)}',
                                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 10),

                                        if (widget.loan != null)
                                          ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.orange,
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                            ),
                                            icon: const Icon(Icons.undo, color: Colors.white, size: 16),
                                            label: const Text('Devolver 1', style: TextStyle(color: Colors.white, fontSize: 12)),
                                            onPressed: () async {
                                              final token = context.read<AuthProvider>().token ?? '';
                                              await context.read<LoanProvider>().returnProduct(token, widget.loan!.id, item.id, 1);
                                            },
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),

              if (_isSearchActive)
                Positioned(
                  top: 75,
                  right: 16,
                  child: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(8.0),
                    child: Container(
                      width: 300,
                      constraints: const BoxConstraints(maxHeight: 300),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8.0)),
                      child: Consumer<ProductProvider>(
                        builder: (context, productProvider, _) {
                          if (productProvider.isLoading) return const Padding(padding: EdgeInsets.all(20.0), child: Center(child: CircularProgressIndicator()));
                          return ListView.builder(
                            shrinkWrap: true,
                            itemCount: productProvider.filteredProducts.length,
                            itemBuilder: (context, index) {
                              final product = productProvider.filteredProducts[index];
                              return ListTile(
                                leading: product.images.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: Image.network(
                                          Uri.encodeFull(product.images.first),
                                          width: 55,
                                          height: 55,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 55, color: Colors.grey),
                                        ),
                                      )
                                    : const Icon(Icons.image, size: 55, color: Colors.grey),
                                title: Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                                subtitle: Text('Stock: ${product.stock} | Base: ${_currencyFormat.format(product.price)}', style: const TextStyle(fontSize: 11)),
                                onTap: () async {
                                  if (product.stock <= 0) {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sin stock')));
                                    return;
                                  }
                                  if (widget.client.id.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: Cliente inválido')));
                                    return;
                                  }

                                  final int? qtySelected = await _askForQuantity(context, product.name, product.stock);

                                  if (qtySelected == null || qtySelected <= 0) return;
                                  if (qtySelected > product.stock) {
                                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Stock insuficiente')));
                                    return;
                                  }

                                  final token = context.read<AuthProvider>().token ?? '';

                                  await context.read<LoanProvider>().loanService.createLoanBatch(
                                    token,
                                    clientId: widget.client.id,
                                    items: [{"productId": product.id, "qty": qtySelected}],
                                  );

                                  await context.read<LoanProvider>().fetchStoresAndLoans(token);
                                  setState(() => _isSearchActive = false);
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}