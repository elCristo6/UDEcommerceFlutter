import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/cart_model.dart';
import '../models/local_cart_item_model.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/invoice_provider.dart';
import '../providers/product_provider.dart';

class ProductList extends StatefulWidget {
  const ProductList({Key? key}) : super(key: key);

  @override
  _ProductListState createState() => _ProductListState();
}

class _ProductListState extends State<ProductList> {
  final _nameCtrl = TextEditingController();
  final _nitCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final Map<String, TextEditingController> _qtyControllers = {};
  bool _isSearchActive = false;
  late FocusNode _searchFocusNode;
  final Map<String, String?> _qtyHint = {};

  /// Controladores de precio por productId
  final Map<String, TextEditingController> _priceControllers = {};

  String formatCurrency(int value) {
    return value.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (Match match) => '${match[1]}.',
        );
  }

  TextEditingController _getQtyController(String productId, int initialQty) {
    final existing = _qtyControllers[productId];
    if (existing != null) {
      final t = initialQty.toString();
      if (existing.text != t) {
        existing.text = t;
        existing.selection =
            TextSelection.collapsed(offset: existing.text.length);
      }
      return existing;
    }
    final c = TextEditingController(text: initialQty.toString());
    _qtyControllers[productId] = c;
    return c;
  }

  Widget qtyClassic({
    required BuildContext context,
    required String id,
    required int quantity,
    required int min,
    required int max,
    required Future<void> Function(int newQty) onChange,
  }) {
    final ctrl = _getQtyController(id, quantity);

    Future<void> setQty(int v) async {
      // Normalizar mínimo
      if (v < min) v = min;

      // 🚫 SIN STOCK
      if (max <= 0) {
        setState(() {
          _qtyHint[id] = 'Sin stock';
        });

        ctrl.text = quantity.toString();
        ctrl.selection = TextSelection.collapsed(offset: ctrl.text.length);
        return;
      }

      // 🚨 SUPERA STOCK
      if (v > max) {
        setState(() {
          _qtyHint[id] = 'Máx: $max unidades';
        });

        ctrl.text = quantity.toString();
        ctrl.selection = TextSelection.collapsed(offset: ctrl.text.length);
        return;
      }

      // ✅ Valor válido → limpiar mensaje
      setState(() {
        _qtyHint[id] = null;
      });

      // Si no cambió realmente, no hagas nada
      if (v == quantity) return;

      // Actualizar visualmente
      ctrl.text = v.toString();
      ctrl.selection = TextSelection.collapsed(offset: ctrl.text.length);

      // Actualizar modelo (provider)
      await onChange(v);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          height: 36,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 36,
                child: InkWell(
                  onTap: () => setQty(quantity - 1),
                  child: const Center(child: Icon(Icons.remove, size: 18)),
                ),
              ),
              Container(width: 1, color: Colors.grey),
              SizedBox(
                width: 52,
                child: TextField(
                  controller: ctrl,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.only(bottom: 10),
                  ),
                  onChanged: (value) async {
                    final v = int.tryParse(value);
                    if (v == null) return;
                    await setQty(v);
                  },
                ),
              ),
              Container(width: 1, color: Colors.grey),
              SizedBox(
                width: 36,
                child: InkWell(
                  onTap: () => setQty(quantity + 1),
                  child: const Center(child: Icon(Icons.add, size: 18)),
                ),
              ),
            ],
          ),
        ),

        // ✅ MENSAJE BAJO LOS BOTONES (+/-)
        if ((_qtyHint[id] ?? '').isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              _qtyHint[id]!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  int _stockForLocalItem(BuildContext context, String productId) {
    final products = context.read<ProductProvider>().products;

    // Busca el producto por id en el catálogo cargado
    final idx = products.indexWhere((p) => p.id == productId);
    if (idx == -1) return -1; // desconocido (no cargado)

    return products[idx].stock;
  }

  @override
  void initState() {
    super.initState();
    _searchFocusNode = FocusNode();

    _searchFocusNode.addListener(() async {
      if (_searchFocusNode.hasFocus) {
        final productProvider =
            Provider.of<ProductProvider>(context, listen: false);
        await productProvider.fetchProducts(forceUpdate: true);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authProvider = context.read<AuthProvider>();
      final cartProvider = context.read<CartProvider>();
      final token = authProvider.token;
      final role = authProvider.role;

      if (token == null || token.isEmpty) {
        await cartProvider.initGuest();
      } else {
        if (role == 'admin') {
          // admin = carrito local
          await cartProvider.initGuest();
        } else {
          // user auth
          cartProvider.sanitizeSelection();
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final productProvider =
        Provider.of<ProductProvider>(context, listen: false);
    if (!productProvider.isLoading && productProvider.products.isEmpty) {
      productProvider.fetchProducts();
    }
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _nameCtrl.dispose();
    _nitCtrl.dispose();
    _phoneCtrl.dispose();
    for (final c in _priceControllers.values) {
      c.dispose();
    }
    for (final c in _qtyControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  // ============================================================
  // Helpers remoto
  // ============================================================

  double _unitPriceForItem(CartItem item, bool isAdmin) {
    if (isAdmin) {
      return item.appliedPrice > 0
          ? item.appliedPrice.toDouble()
          : item.product.price;
    } else {
      return item.product.price;
    }
  }

  Future<void> _updateCartItem(
    CartProvider cartProvider,
    String token,
    List<CartItem> cartItems,
    CartItem targetItem, {
    int? newQuantity,
    int? newAppliedPrice,
  }) async {
    final updatedItems = cartItems.map((x) {
      if (x.product.id == targetItem.product.id) {
        return x.copyWith(
          quantity: newQuantity ?? x.quantity,
          appliedPrice: newAppliedPrice ?? x.appliedPrice,
        );
      }
      return x;
    }).toList();

    await cartProvider.updateUserCartQuantities(token, items: updatedItems);
    cartProvider.sanitizeSelection();
  }

  // ============================================================
  // Controller de precio (SINCRONIZA texto)
  // ============================================================
  TextEditingController _getPriceController(
      String productId, int initialPrice) {
    final existing = _priceControllers[productId];
    if (existing != null) {
      final newText = initialPrice.toString();
      if (existing.text != newText) {
        existing.text = newText;
        existing.selection =
            TextSelection.collapsed(offset: existing.text.length);
      }
      return existing;
    }

    final controller = TextEditingController(text: initialPrice.toString());
    _priceControllers[productId] = controller;
    return controller;
  }

  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context);
    final invoiceProvider = Provider.of<InvoiceProvider>(context);

    final isAdmin = authProvider.role == 'admin';
    final token = authProvider.token ?? '';
    final isAuth = token.isNotEmpty;

    // Solo user autenticado usa remoto en esta pantalla
    final bool useRemoteCart = isAuth && !isAdmin;
    final cartItems =
        useRemoteCart ? (cartProvider.cart?.items ?? []) : <CartItem>[];

    final uiItems = cartProvider.uiItems;
    final totalItems = cartProvider.uiUnitsCount;
    final hasAnyCartUI =
        (isAuth && !isAdmin) ? cartItems.isNotEmpty : uiItems.isNotEmpty;

    return GestureDetector(
      onTap: () {
        if (_isSearchActive) {
          setState(() => _isSearchActive = false);
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Stack(
        children: [
          Column(
            children: [
              // ======= ENCABEZADO DATOS CLIENTE + BUSCADOR (solo ADMIN) =======
              if (isAdmin)
                Container(
                  color: Colors.grey[100],
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3.0),
                          child: TextField(
                            controller: _nameCtrl,
                            onChanged: (value) {
                              final current = invoiceProvider.currentUser ??
                                  User(
                                    id: '',
                                    name: '',
                                    email: '',
                                    phone: '',
                                    nit: '',
                                    role: '',
                                  );
                              invoiceProvider.setCurrentUser(
                                current.copyWith(name: value),
                              );
                            },
                            decoration: InputDecoration(
                              labelText: 'Nombre',
                              prefixIcon:
                                  const Icon(Icons.person, color: Colors.blue),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.0),
                                borderSide: const BorderSide(
                                  color: Colors.blue,
                                  width: 2,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.0),
                                borderSide: const BorderSide(
                                  color: Colors.grey,
                                  width: 1,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: TextField(
                            controller: _nitCtrl,
                            onChanged: (value) {
                              final current = invoiceProvider.currentUser ??
                                  User(
                                    id: '',
                                    name: '',
                                    email: '',
                                    phone: '',
                                    nit: '',
                                    role: '',
                                  );
                              invoiceProvider.setCurrentUser(
                                current.copyWith(nit: value),
                              );
                            },
                            decoration: InputDecoration(
                              labelText: 'NIT',
                              prefixIcon: const Icon(
                                Icons.document_scanner,
                                color: Colors.green,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.0),
                                borderSide: const BorderSide(
                                  color: Colors.green,
                                  width: 2,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.0),
                                borderSide: const BorderSide(
                                  color: Colors.grey,
                                  width: 1,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: TextField(
                            controller: _phoneCtrl,
                            keyboardType: TextInputType.phone,
                            onChanged: (value) {
                              final current = invoiceProvider.currentUser ??
                                  User(
                                    id: '',
                                    name: '',
                                    email: '',
                                    phone: '',
                                    nit: '',
                                    role: '',
                                  );
                              invoiceProvider.setCurrentUser(
                                current.copyWith(phone: value),
                              );
                            },
                            onSubmitted: (value) async {
                              final phone = value.trim();
                              if (phone.isEmpty) return;

                              final user =
                                  await invoiceProvider.fetchUserByPhone(phone);

                              if (user != null) {
                                _nameCtrl.text = user.name;
                                _nitCtrl.text = user.nit;
                                _phoneCtrl.text = user.phone;
                                invoiceProvider.setCurrentUser(user);

                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'Cliente encontrado: ${user.name}'),
                                    ),
                                  );
                                }
                              } else {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'No existe un cliente con ese teléfono',
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                            decoration: InputDecoration(
                              labelText: 'Telefono',
                              prefixIcon:
                                  const Icon(Icons.phone, color: Colors.green),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.0),
                                borderSide: const BorderSide(
                                  color: Colors.green,
                                  width: 2,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.0),
                                borderSide: const BorderSide(
                                  color: Colors.grey,
                                  width: 1,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 300,
                        child: TextField(
                          focusNode: _searchFocusNode,
                          decoration: InputDecoration(
                            hintText: 'Buscar Producto',
                            prefixIcon:
                                const Icon(Icons.search, color: Colors.grey),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: const BorderSide(
                                color: Colors.blue,
                                width: 2,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: const BorderSide(
                                color: Colors.grey,
                                width: 1,
                              ),
                            ),
                          ),
                          onTap: () => setState(() => _isSearchActive = true),
                          onChanged: (value) {
                            context
                                .read<ProductProvider>()
                                .filterProducts(value);
                          },
                        ),
                      ),
                    ],
                  ),
                ),

              // ======= ENCABEZADO CESTA =======
              Container(
                padding: const EdgeInsets.all(16.0),
                color: Colors.grey[100],
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Cesta ($totalItems)',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    Row(
                      children: [
                        Transform.scale(
                          scale: 1.5,
                          child: Checkbox(
                            shape: const CircleBorder(),
                            value: cartProvider.allSelected,
                            onChanged: (value) {
                              if (value == true) {
                                cartProvider.selectAll();
                              } else {
                                cartProvider.clearSelection();
                              }

                              // Solo sincroniza invoice para admin+auth (si lo usas)
                              if (isAdmin && isAuth) {
                                final selectedIds = cartProvider.selectedIds;
                                final selectedItems = cartItems
                                    .where((x) =>
                                        selectedIds.contains(x.product.id))
                                    .toList();

                                invoiceProvider
                                    .setSelectedCartItems(selectedItems);

                                invoiceProvider.recalculateTotalsFromCart(
                                  cartProvider.cart,
                                  isAdmin: true,
                                );
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        const Text(
                          'Seleccionar todos los artículos',
                          style: TextStyle(fontSize: 16, color: Colors.black),
                        ),
                        const SizedBox(width: 8),
                        if (cartProvider.selectedIds.isNotEmpty && hasAnyCartUI)
                          TextButton(
                            onPressed: () async {
                              final ids = cartProvider.selectedIds.toList();
                              final useRemote = isAuth &&
                                  !isAdmin; // user autenticado => remoto

                              if (useRemote) {
                                // remoto (user)
                                for (final id in ids) {
                                  await cartProvider.removeItem(
                                    token,
                                    productId: id,
                                  );
                                }
                              } else {
                                // local (guest/admin)
                                for (final id in ids) {
                                  await cartProvider.removeLocal(id);
                                }
                              }

                              cartProvider.clearSelection();
                              cartProvider.sanitizeSelection();

                              if (isAdmin && isAuth) {
                                invoiceProvider.setSelectedCartItems([]);
                                invoiceProvider.updateTotals(0.0);
                              }
                            },
                            child: const Text(
                              'Borrar artículos seleccionados',
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 16,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              Expanded(
                child: _buildCartList(
                  cartItems: cartItems,
                  cartProvider: cartProvider,
                  token: token,
                  isAdmin: isAdmin,
                  isAuth: isAuth,
                ),
              ),
            ],
          ),

          // ======= LISTA BÚSQUEDA (admin) =======
          if (_isSearchActive && isAdmin)
            Positioned(
              top: 60,
              right: 10,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(12.0),
                child: Container(
                  width: 300,
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: Consumer<ProductProvider>(
                    builder: (context, productProvider, _) {
                      return ListView.builder(
                        itemCount: productProvider.filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product =
                              productProvider.filteredProducts[index];
                          return GestureDetector(
                            onTap: () async {
                              if (token.isEmpty) return;

                              // ✅ BLOQUEO: no permitir agregar si no hay stock
                              if (product.stock <= 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Sin stock'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                                return;
                              }

                              await cartProvider.addProduct(
                                product,
                                quantity: 1,
                                token: token,
                                role: authProvider.role, // admin => local
                                appliedPrice: product.price.toInt(),
                              );

                              cartProvider.sanitizeSelection();
                              setState(() => _isSearchActive = false);
                            },
                            child: Card(
                              margin: const EdgeInsets.symmetric(vertical: 4.0),
                              child: ListTile(
                                leading: product.images.isNotEmpty
                                    ? Image.network(
                                        Uri.encodeFull(product.images.first),
                                        fit: BoxFit.cover,
                                        width: 50,
                                        height: 50,
                                        errorBuilder: (_, __, ___) {
                                          return const Icon(
                                            Icons.broken_image,
                                            size: 50,
                                          );
                                        },
                                      )
                                    : const Icon(Icons.image, size: 50),
                                title: Text(product.name),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'COP ${formatCurrency(product.price.toInt())}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    Text(
                                      'Stock: ${product.stock}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
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
    );
  }

  // ============================================================
  // LISTA CARRITO
  // ============================================================
  Widget _buildCartList({
    required List<CartItem> cartItems,
    required CartProvider cartProvider,
    required String token,
    required bool isAdmin,
    required bool isAuth,
  }) {
    // =========================
    // LOCAL (guest/admin)
    // =========================
    if (!isAuth || isAdmin) {
      if (cartProvider.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }

      final List<LocalCartItem> items = cartProvider.uiItems;

      if (items.isEmpty) {
        return const Center(
          child: Text(
            'Tu carrito está vacío',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final it = items[index];
          final productId = it.productId;
          final quantity = it.quantity;

          final priceToShow = it.effectivePrice.toInt();
          final priceController = _getPriceController(productId, priceToShow);
          final stock = _stockForLocalItem(context, productId);
          final maxStock =
              stock >= 0 ? stock : 9999; // si no sé stock, no bloqueo

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: ListTile(
              leading: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.scale(
                    scale: 1.5,
                    child: Checkbox(
                      value: cartProvider.isSelected(productId),
                      onChanged: (value) {
                        cartProvider.toggleSelection(productId, value == true);
                      },
                      shape: const CircleBorder(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  it.image.isNotEmpty
                      ? Image.network(
                          Uri.encodeFull(it.image),
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) {
                            return const Icon(Icons.broken_image, size: 50);
                          },
                        )
                      : const Icon(Icons.image, size: 50),
                ],
              ),
              title: Text(it.name),

              // ✅ AQUÍ VA LA EDICIÓN DE PRECIO LOCAL (solo admin)
              subtitle: isAdmin
                  ? Row(
                      children: [
                        const Text(
                          'COP ',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(
                          width: 70,
                          child: TextFormField(
                            controller: priceController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 2),
                            ),
                            onChanged: (value) async {
                              final clean = value.replaceAll('.', '').trim();
                              final newPrice = int.tryParse(clean);
                              if (newPrice == null) return;

                              // si vuelve al precio base => limpia override
                              if (newPrice == it.price.toInt()) {
                                await cartProvider
                                    .clearLocalAppliedPrice(productId);
                              } else if (newPrice > 0) {
                                await cartProvider.setLocalAppliedPrice(
                                  productId,
                                  newPrice.toDouble(),
                                );
                              }

                              cartProvider.sanitizeSelection();
                            },
                          ),
                        ),
                      ],
                    )
                  : Text(
                      'COP ${formatCurrency(priceToShow)}',
                      style: const TextStyle(fontSize: 14),
                    ),

              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  qtyClassic(
                    context: context,
                    id: productId,
                    quantity: quantity,
                    min: 1,
                    max: maxStock,
                    onChange: (newQty) async {
                      await cartProvider.setLocalQuantity(productId, newQty);
                      cartProvider.sanitizeSelection();
                    },
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      await cartProvider.removeLocal(productId);
                      cartProvider.sanitizeSelection();
                    },
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    // =========================
    // REMOTO (user auth)
    // =========================
    if (token.isEmpty) {
      return const Center(
        child: Text(
          'Inicia sesión para ver tu carrito',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    if (cartItems.isEmpty) {
      return const Center(
        child: Text(
          'Tu carrito está vacío',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: cartItems.length,
      itemBuilder: (context, index) {
        final item = cartItems[index];
        final product = item.product;
        final quantity = item.quantity;

        final unitPrice = _unitPriceForItem(item, isAdmin);
        final priceToShow = unitPrice.toInt();

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.scale(
                  scale: 1.5,
                  child: Checkbox(
                    value: cartProvider.isSelected(product.id),
                    onChanged: (value) {
                      cartProvider.toggleSelection(product.id, value == true);
                    },
                    shape: const CircleBorder(),
                  ),
                ),
                const SizedBox(width: 8),
                product.images.isNotEmpty
                    ? Image.network(
                        Uri.encodeFull(product.images.first),
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) {
                          return const Icon(Icons.broken_image, size: 50);
                        },
                      )
                    : const Icon(Icons.image, size: 50),
              ],
            ),
            title: Text(product.name),

            // remoto: normalmente user no edita precio
            subtitle: Text(
              'COP ${formatCurrency(priceToShow)}',
              style: const TextStyle(fontSize: 14),
            ),

            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                qtyClassic(
                  context: context,
                  id: product.id,
                  quantity: quantity,
                  min: 1,
                  // max: product.stock > 0 ? product.stock : 9999,
                  max: product.stock, // si es 0, setQty mostrará "Sin stock"
                  onChange: (newQty) async {
                    await _updateCartItem(
                      cartProvider,
                      token,
                      cartItems,
                      item,
                      newQuantity: newQty,
                    );
                  },
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    await cartProvider.removeItem(
                      token,
                      productId: product.id,
                    );
                    cartProvider.sanitizeSelection();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
