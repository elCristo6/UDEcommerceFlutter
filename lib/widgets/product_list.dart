/*
import 'package:flutter/material.dart';
import 'package:input_quantity/input_quantity.dart';
import 'package:provider/provider.dart';

import '../models/cart_model.dart';
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

  bool _isSearchActive = false;
  late FocusNode _searchFocusNode;

  /// Selección de ítems del carrito (por productId) para ambos roles
  final Set<String> _selectedProductIds = {};

  /// Controladores de precio por productId (solo para admin)
  final Map<String, TextEditingController> _priceControllers = {};

  String formatCurrency(int value) {
    return value.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (Match match) => '${match[1]}.',
        );
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
    super.dispose();
  }

  // ============================================================
  //  Helpers de selección y actualización de carrito
  // ============================================================

  bool _allSelected(List<CartItem> cartItems) {
    return cartItems.isNotEmpty &&
        _selectedProductIds.length == cartItems.length;
  }

  Future<void> _deleteSelectedItems(
    CartProvider cartProvider,
    String token,
    List<CartItem> cartItems,
  ) async {
    final toRemove = cartItems
        .where((item) => _selectedProductIds.contains(item.product.id))
        .toList();

    for (final item in toRemove) {
      await cartProvider.removeItem(token, productId: item.product.id);
    }

    setState(() {
      _selectedProductIds.clear();
    });

    final invoiceProvider =
        Provider.of<InvoiceProvider>(context, listen: false);

    invoiceProvider.setSelectedCartItems([]);
    invoiceProvider.recalculateFromCart(cartProvider.cart);
  }

  /// Actualiza carrito en backend cambiando cantidad y/o precio aplicado
  Future<void> _updateCartItem(
    CartProvider cartProvider,
    String token,
    List<CartItem> cartItems,
    CartItem targetItem, {
    int? newQuantity,
    int? newAppliedPrice,
  }) async {
    final updatedItems = cartItems.map((item) {
      if (item.product.id == targetItem.product.id) {
        return item.copyWith(
          quantity: newQuantity ?? item.quantity,
          appliedPrice: newAppliedPrice ?? item.appliedPrice,
        );
      }
      return item;
    }).toList();

    await cartProvider.updateUserCartQuantities(
      token,
      items: updatedItems,
    );
  }

  TextEditingController _getPriceController(
    String productId,
    int initialPrice,
  ) {
    if (_priceControllers.containsKey(productId)) {
      return _priceControllers[productId]!;
    }
    final controller = TextEditingController(text: initialPrice.toString());
    _priceControllers[productId] = controller;
    return controller;
  }

  // ============================================================
  //  BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context);
    final invoiceProvider = Provider.of<InvoiceProvider>(context);
    final isAdmin = authProvider.role == 'admin';
    final token = authProvider.token ?? '';
    final cartItems = cartProvider.cart?.items ?? [];

    final int totalItems = cartItems.length;

    return GestureDetector(
      onTap: () {
        if (_isSearchActive) {
          setState(() {
            _isSearchActive = false;
          });
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
                      // ------------------ NOMBRE ------------------
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
                                  current.copyWith(name: value));
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

                      // ------------------ NIT ------------------
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
                              invoiceProvider
                                  .setCurrentUser(current.copyWith(nit: value));
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

                      // ------------------ TELÉFONO (CON BÚSQUEDA) ------------------
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
                                  current.copyWith(phone: value));
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
                                        'Cliente encontrado: ${user.name}',
                                      ),
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

                      // ------------------ BUSCADOR DE PRODUCTOS ------------------
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
                          onTap: () {
                            setState(() {
                              _isSearchActive = true;
                            });
                          },
                          onChanged: (value) {
                            Provider.of<ProductProvider>(context, listen: false)
                                .filterProducts(value);
                          },
                        ),
                      ),
                    ],
                  ),
                ),

              // ======= ENCABEZADO CESTA (ambos roles) =======
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
                            value: _allSelected(cartItems),
                            onChanged: (value) {
                              setState(() {
                                if (value == true) {
                                  _selectedProductIds.clear();
                                  _selectedProductIds.addAll(
                                      cartItems.map((item) => item.product.id));
                                } else {
                                  _selectedProductIds.clear();
                                }
                              });

                              final invoiceProvider =
                                  Provider.of<InvoiceProvider>(context,
                                      listen: false);

                              final selectedItems = cartItems
                                  .where((item) => _selectedProductIds
                                      .contains(item.product.id))
                                  .toList();

                              invoiceProvider
                                  .setSelectedCartItems(selectedItems);
                              invoiceProvider
                                  .recalculateFromCart(cartProvider.cart);
                            },
                            shape: const CircleBorder(),
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        const Text(
                          'Seleccionar todos los artículos',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (_selectedProductIds.isNotEmpty &&
                            cartItems.isNotEmpty &&
                            token.isNotEmpty)
                          TextButton(
                            onPressed: () async {
                              await _deleteSelectedItems(
                                  cartProvider, token, cartItems);
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
                    )
                  ],
                ),
              ),

              // ======= LISTA CESTA UNIFICADA (admin + user) =======
              Expanded(
                child: _buildCartList(
                  cartItems: cartItems,
                  cartProvider: cartProvider,
                  token: token,
                  isAdmin: isAdmin,
                ),
              ),
            ],
          ),

          // ======= LISTA DE BÚSQUEDA (solo admin, cuando _isSearchActive) =======
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

                              await cartProvider.addItem(
                                token,
                                productId: product.id,
                                quantity: 1,
                                appliedPrice: product.price.toInt(),
                              );
                              setState(() {
                                _isSearchActive = false;
                              });
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
                                        errorBuilder:
                                            (context, error, stackTrace) {
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
  //  LISTA DE CARRITO UNIFICADA
  // ============================================================

  Widget _buildCartList({
    required List<CartItem> cartItems,
    required CartProvider cartProvider,
    required String token,
    required bool isAdmin,
  }) {
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
        final int quantity = item.quantity;
        final int priceToShow =
            item.appliedPrice > 0 ? item.appliedPrice : product.price.toInt();

        final priceController = _getPriceController(product.id, priceToShow);

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.scale(
                  scale: 1.5,
                  child: Checkbox(
                    value: _selectedProductIds.contains(product.id),
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedProductIds.add(product.id);
                        } else {
                          _selectedProductIds.remove(product.id);
                        }
                      });

                      final invoiceProvider =
                          Provider.of<InvoiceProvider>(context, listen: false);

                      final selectedItems = cartItems
                          .where((item) =>
                              _selectedProductIds.contains(item.product.id))
                          .toList();
                      invoiceProvider.setSelectedCartItems(selectedItems);
                      invoiceProvider.recalculateFromCart(cartProvider.cart);
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
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.broken_image, size: 50);
                        },
                      )
                    : const Icon(Icons.image, size: 50),
              ],
            ),
            title: Text(product.name),
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
                            if (newPrice == null || newPrice <= 0) return;

                            await _updateCartItem(
                              cartProvider,
                              token,
                              cartItems,
                              item,
                              newAppliedPrice: newPrice,
                            );

                            final invoiceProvider =
                                Provider.of<InvoiceProvider>(context,
                                    listen: false);

                            final freshCart = Provider.of<CartProvider>(context,
                                    listen: false)
                                .cart;

                            final selectedItems = freshCart?.items
                                    .where((i) => _selectedProductIds
                                        .contains(i.product.id))
                                    .toList() ??
                                [];

                            invoiceProvider.setSelectedCartItems(selectedItems);
                            invoiceProvider.recalculateFromCart(freshCart);
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
                // Control de cantidad para ambos roles
                InputQty.int(
                  maxVal: product.stock > 0 ? product.stock : 9999,
                  initVal: quantity,
                  minVal: 1,
                  steps: 1,
                  decoration: const QtyDecorationProps(
                    qtyStyle: QtyStyle.classic,
                    orientation: ButtonOrientation.horizontal,
                    isBordered: true,
                    borderShape: BorderShapeBtn.square,
                  ),
                  qtyFormProps: const QtyFormProps(
                    cursorColor: Colors.blue,
                  ),
                  onQtyChanged: (newVal) async {
                    if (newVal == quantity) return;

                    await _updateCartItem(
                      cartProvider,
                      token,
                      cartItems,
                      item,
                      newQuantity: newVal,
                    );

                    final invoiceProvider =
                        Provider.of<InvoiceProvider>(context, listen: false);

                    final freshCart =
                        Provider.of<CartProvider>(context, listen: false).cart;

                    final selectedItems = freshCart?.items
                            .where((i) =>
                                _selectedProductIds.contains(i.product.id))
                            .toList() ??
                        [];

                    invoiceProvider.setSelectedCartItems(selectedItems);
                    invoiceProvider.recalculateFromCart(freshCart);
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
                    setState(() {
                      _selectedProductIds.remove(product.id);
                    });

                    final invoiceProvider =
                        Provider.of<InvoiceProvider>(context, listen: false);

                    final freshCart =
                        Provider.of<CartProvider>(context, listen: false).cart;

                    final selectedItems = freshCart?.items
                            .where((i) =>
                                _selectedProductIds.contains(i.product.id))
                            .toList() ??
                        [];

                    invoiceProvider.setSelectedCartItems(selectedItems);
                    invoiceProvider.recalculateFromCart(freshCart);
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
*/

import 'package:flutter/material.dart';
import 'package:input_quantity/input_quantity.dart';
import 'package:provider/provider.dart';

import '../models/cart_model.dart';
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

  bool _isSearchActive = false;
  late FocusNode _searchFocusNode;

  /// Selección de ítems del carrito (por productId) para ambos roles
  final Set<String> _selectedProductIds = {};

  /// Controladores de precio por productId (solo para admin)
  final Map<String, TextEditingController> _priceControllers = {};

  String formatCurrency(int value) {
    return value.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (Match match) => '${match[1]}.',
        );
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
    super.dispose();
  }

  // ============================================================
  //  Helpers de selección / totales / precio unitario
  // ============================================================

  bool _allSelected(List<CartItem> cartItems) {
    return cartItems.isNotEmpty &&
        _selectedProductIds.length == cartItems.length;
  }

  /// Precio unitario según rol:
  /// - admin → usa appliedPrice (si > 0) o product.price
  /// - user  → SIEMPRE usa product.price
  double _unitPriceForItem(CartItem item, bool isAdmin) {
    if (isAdmin) {
      return item.appliedPrice > 0
          ? item.appliedPrice.toDouble()
          : item.product.price;
    } else {
      return item.product.price;
    }
  }

  Future<void> _deleteSelectedItems(
    CartProvider cartProvider,
    String token,
    List<CartItem> cartItems,
  ) async {
    final toRemove = cartItems
        .where((item) => _selectedProductIds.contains(item.product.id))
        .toList();

    for (final item in toRemove) {
      await cartProvider.removeItem(token, productId: item.product.id);
    }

    setState(() {
      _selectedProductIds.clear();
    });

    // Sincronizar con InvoiceProvider después de borrar
    final invoiceProvider =
        Provider.of<InvoiceProvider>(context, listen: false);
    invoiceProvider.setSelectedCartItems([]);
    invoiceProvider.updateTotals(0.0);
  }

  /// Actualiza carrito en backend cambiando cantidad y/o precio aplicado
  Future<void> _updateCartItem(
    CartProvider cartProvider,
    String token,
    List<CartItem> cartItems,
    CartItem targetItem, {
    int? newQuantity,
    int? newAppliedPrice,
  }) async {
    final updatedItems = cartItems.map((item) {
      if (item.product.id == targetItem.product.id) {
        return item.copyWith(
          quantity: newQuantity ?? item.quantity,
          appliedPrice: newAppliedPrice ?? item.appliedPrice,
        );
      }
      return item;
    }).toList();

    await cartProvider.updateUserCartQuantities(
      token,
      items: updatedItems,
    );
  }

  TextEditingController _getPriceController(
    String productId,
    int initialPrice,
  ) {
    if (_priceControllers.containsKey(productId)) {
      return _priceControllers[productId]!;
    }
    final controller = TextEditingController(text: initialPrice.toString());
    _priceControllers[productId] = controller;
    return controller;
  }

  // ============================================================
  //  BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context);
    final invoiceProvider = Provider.of<InvoiceProvider>(context);
    final isAdmin = authProvider.role == 'admin';
    final token = authProvider.token ?? '';
    final cartItems = cartProvider.cart?.items ?? [];

    final int totalItems = cartItems.length;

    return GestureDetector(
      onTap: () {
        if (_isSearchActive) {
          setState(() {
            _isSearchActive = false;
          });
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
                      // ------------------ NOMBRE ------------------
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
                                  current.copyWith(name: value));
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

                      // ------------------ NIT ------------------
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
                              invoiceProvider
                                  .setCurrentUser(current.copyWith(nit: value));
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

                      // ------------------ TELÉFONO (CON BÚSQUEDA) ------------------
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
                                  current.copyWith(phone: value));
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
                                        'Cliente encontrado: ${user.name}',
                                      ),
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

                      // ------------------ BUSCADOR DE PRODUCTOS ------------------
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
                          onTap: () {
                            setState(() {
                              _isSearchActive = true;
                            });
                          },
                          onChanged: (value) {
                            Provider.of<ProductProvider>(context, listen: false)
                                .filterProducts(value);
                          },
                        ),
                      ),
                    ],
                  ),
                ),

              // ======= ENCABEZADO CESTA (ambos roles) =======
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
                            value: _allSelected(cartItems),
                            onChanged: (value) {
                              setState(() {
                                if (value == true) {
                                  _selectedProductIds.clear();
                                  _selectedProductIds.addAll(
                                      cartItems.map((item) => item.product.id));
                                } else {
                                  _selectedProductIds.clear();
                                }
                              });

                              final selectedItems = cartItems
                                  .where((item) => _selectedProductIds
                                      .contains(item.product.id))
                                  .toList();

                              // Actualizar selección en provider
                              invoiceProvider
                                  .setSelectedCartItems(selectedItems);

                              // Recalcular subtotal usando carrito actual
                              invoiceProvider.recalculateTotalsFromCart(
                                cartProvider.cart,
                                isAdmin: isAdmin,
                              );
                            },
                            shape: const CircleBorder(),
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        const Text(
                          'Seleccionar todos los artículos',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (_selectedProductIds.isNotEmpty &&
                            cartItems.isNotEmpty &&
                            token.isNotEmpty)
                          TextButton(
                            onPressed: () async {
                              await _deleteSelectedItems(
                                  cartProvider, token, cartItems);
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
                    )
                  ],
                ),
              ),

              // ======= LISTA CESTA UNIFICADA (admin + user) =======
              Expanded(
                child: _buildCartList(
                  cartItems: cartItems,
                  cartProvider: cartProvider,
                  token: token,
                  isAdmin: isAdmin,
                ),
              ),
            ],
          ),

          // ======= LISTA DE BÚSQUEDA (solo admin, cuando _isSearchActive) =======
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

                              await cartProvider.addItem(
                                token,
                                productId: product.id,
                                quantity: 1,
                                appliedPrice: product.price.toInt(),
                              );
                              setState(() {
                                _isSearchActive = false;
                              });
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
                                        errorBuilder:
                                            (context, error, stackTrace) {
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
  //  LISTA DE CARRITO UNIFICADA
  // ============================================================

  Widget _buildCartList({
    required List<CartItem> cartItems,
    required CartProvider cartProvider,
    required String token,
    required bool isAdmin,
  }) {
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
        final int quantity = item.quantity;

        final double unitPrice = _unitPriceForItem(item, isAdmin);
        final int priceToShow = unitPrice.toInt();

        final priceController = _getPriceController(product.id, priceToShow);

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.scale(
                  scale: 1.5,
                  child: Checkbox(
                    value: _selectedProductIds.contains(product.id),
                    onChanged: (value) {
                      final invoiceProvider =
                          Provider.of<InvoiceProvider>(context, listen: false);

                      setState(() {
                        if (value == true) {
                          _selectedProductIds.add(product.id);
                        } else {
                          _selectedProductIds.remove(product.id);
                        }
                      });

                      final selectedItems = cartItems
                          .where(
                              (i) => _selectedProductIds.contains(i.product.id))
                          .toList();

                      invoiceProvider.setSelectedCartItems(selectedItems);

                      // Recalcular subtotal con carrito actual
                      invoiceProvider.recalculateTotalsFromCart(
                        cartProvider.cart,
                        isAdmin: isAdmin,
                      );
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
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.broken_image, size: 50);
                        },
                      )
                    : const Icon(Icons.image, size: 50),
              ],
            ),
            title: Text(product.name),
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
                            if (newPrice == null || newPrice <= 0) return;

                            await _updateCartItem(
                              cartProvider,
                              token,
                              cartItems,
                              item,
                              newAppliedPrice: newPrice,
                            );

                            final invoiceProvider =
                                Provider.of<InvoiceProvider>(context,
                                    listen: false);

                            // Carrito fresco desde el provider
                            final freshCart = Provider.of<CartProvider>(context,
                                    listen: false)
                                .cart;

                            final selectedItems = freshCart?.items
                                    .where((i) => _selectedProductIds
                                        .contains(i.product.id))
                                    .toList() ??
                                [];

                            invoiceProvider.setSelectedCartItems(selectedItems);

                            invoiceProvider.recalculateTotalsFromCart(
                              freshCart,
                              isAdmin: isAdmin,
                            );
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
                // Control de cantidad para ambos roles
                InputQty.int(
                  maxVal: product.stock > 0 ? product.stock : 9999,
                  initVal: quantity,
                  minVal: 1,
                  steps: 1,
                  decoration: const QtyDecorationProps(
                    qtyStyle: QtyStyle.classic,
                    orientation: ButtonOrientation.horizontal,
                    isBordered: true,
                    borderShape: BorderShapeBtn.square,
                  ),
                  qtyFormProps: const QtyFormProps(
                    cursorColor: Colors.blue,
                  ),
                  onQtyChanged: (newVal) async {
                    if (newVal == quantity) return;

                    await _updateCartItem(
                      cartProvider,
                      token,
                      cartItems,
                      item,
                      newQuantity: newVal,
                    );

                    final invoiceProvider =
                        Provider.of<InvoiceProvider>(context, listen: false);

                    final freshCart =
                        Provider.of<CartProvider>(context, listen: false).cart;

                    final selectedItems = freshCart?.items
                            .where((i) =>
                                _selectedProductIds.contains(i.product.id))
                            .toList() ??
                        [];

                    invoiceProvider.setSelectedCartItems(selectedItems);

                    invoiceProvider.recalculateTotalsFromCart(
                      freshCart,
                      isAdmin: isAdmin,
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
                    setState(() {
                      _selectedProductIds.remove(product.id);
                    });

                    final invoiceProvider =
                        Provider.of<InvoiceProvider>(context, listen: false);

                    final freshCart =
                        Provider.of<CartProvider>(context, listen: false).cart;

                    final selectedItems = freshCart?.items
                            .where((i) =>
                                _selectedProductIds.contains(i.product.id))
                            .toList() ??
                        [];

                    invoiceProvider.setSelectedCartItems(selectedItems);

                    invoiceProvider.recalculateTotalsFromCart(
                      freshCart,
                      isAdmin: isAdmin,
                    );
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
