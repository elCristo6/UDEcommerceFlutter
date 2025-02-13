import 'package:flutter/material.dart';
import 'package:input_quantity/input_quantity.dart';
import 'package:provider/provider.dart';

import '../models/user_model.dart';
import '../providers/invoice_provider.dart';
import '../providers/product_provider.dart';

class ProductList extends StatefulWidget {
  // ignore: use_super_parameters
  const ProductList({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _ProductListState createState() => _ProductListState();
}

class _ProductListState extends State<ProductList> {
  String formatCurrency(int value) {
    return value.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match match) => '${match[1]}.');
  }

  bool _isSearchActive =
      false; // Controla si la lista de productos se muestra o no
  late FocusNode _searchFocusNode;

  @override
  void initState() {
    super.initState();
    _searchFocusNode = FocusNode();

    // Listener para actualizar productos al obtener foco
    _searchFocusNode.addListener(() async {
      if (_searchFocusNode.hasFocus) {
        final productProvider =
            Provider.of<ProductProvider>(context, listen: false);

        // Llama a fetchProducts para actualizar la lista
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
    _searchFocusNode.dispose(); // Limpia el FocusNode al desmontar el widget
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);

    return GestureDetector(
      onTap: () {
        // Oculta la lista de productos al hacer clic fuera
        if (_isSearchActive) {
          setState(() {
            _isSearchActive = false; // Oculta la lista después de agregar
          });
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Stack(
        children: [
          // Contenido principal (Cesta y demás widgets)
          Column(
            children: [
              // Encabezado con los campos Nombre, NIT y Barra de búsqueda
              Container(
                color: Colors.grey[100],
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Campo Nombre
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3.0),
                        child: TextField(
                          onChanged: (value) {
                            final invoiceProvider =
                                Provider.of<InvoiceProvider>(context,
                                    listen: false);
                            // Actualiza el nombre del usuario actual
                            final currentUser = invoiceProvider.currentUser ??
                                User(
                                    id: '',
                                    name: '',
                                    email: '',
                                    phone: '',
                                    nit: '');
                            invoiceProvider.setCurrentUser(
                                currentUser.copyWith(name: value));
                          },
                          decoration: InputDecoration(
                            labelText: 'Nombre',
                            prefixIcon:
                                const Icon(Icons.person, color: Colors.blue),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: const BorderSide(
                                  color: Colors.blue, width: 2),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: const BorderSide(
                                  color: Colors.grey, width: 1),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Campo NIT
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: TextField(
                          onChanged: (value) {
                            final invoiceProvider =
                                Provider.of<InvoiceProvider>(context,
                                    listen: false);
                            final currentUser = invoiceProvider.currentUser ??
                                User(
                                    id: '',
                                    name: '',
                                    email: '',
                                    phone: '',
                                    nit: '');
                            invoiceProvider.setCurrentUser(
                                currentUser.copyWith(nit: value));
                          },
                          decoration: InputDecoration(
                            labelText: 'NIT',
                            prefixIcon: const Icon(Icons.document_scanner,
                                color: Colors.green),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: const BorderSide(
                                  color: Colors.green, width: 2),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: const BorderSide(
                                  color: Colors.grey, width: 1),
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
                          onChanged: (value) {
                            final invoiceProvider =
                                Provider.of<InvoiceProvider>(context,
                                    listen: false);
                            final currentUser = invoiceProvider.currentUser ??
                                User(
                                    id: '',
                                    name: '',
                                    email: '',
                                    phone: '',
                                    nit: '');
                            invoiceProvider.setCurrentUser(
                                currentUser.copyWith(phone: value));
                          },
                          decoration: InputDecoration(
                            labelText: 'Telefono',
                            prefixIcon: const Icon(Icons.document_scanner,
                                color: Colors.green),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: const BorderSide(
                                  color: Colors.green, width: 2),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: const BorderSide(
                                  color: Colors.grey, width: 1),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Barra de búsqueda (más ancha)
                    SizedBox(
                      width:
                          300, // Aumenté el ancho para que la lista tenga más espacio
                      child: TextField(
                        focusNode: _searchFocusNode,
                        decoration: InputDecoration(
                          hintText: 'Buscar Producto',
                          prefixIcon:
                              const Icon(Icons.search, color: Colors.grey),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide:
                                const BorderSide(color: Colors.blue, width: 2),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide:
                                const BorderSide(color: Colors.grey, width: 1),
                          ),
                        ),
                        onTap: () {
                          setState(() {
                            _isSearchActive =
                                true; // Muestra la lista de productos
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

              // Encabezado de la cesta
              Container(
                padding: const EdgeInsets.all(16.0),
                color: Colors.grey[100],
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Cesta (${productProvider.cart.length})',
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
                            value: productProvider.cart.length ==
                                    productProvider.selectedProducts.length &&
                                productProvider.cart.isNotEmpty,
                            onChanged: (value) {
                              if (value == true) {
                                // Selecciona todos los productos
                                productProvider.selectAllProducts();
                              } else {
                                // Deselecciona todos los productos
                                productProvider.deselectAllProducts();
                              }
                            },
                            shape: const CircleBorder(),
                          ),
                        ),

                        const SizedBox(
                            width: 8.0), // Espacio entre la casilla y el texto
                        const Text(
                          'Seleccionar todos los artículos',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(width: 8),

                        if (productProvider.cart.length ==
                                productProvider.selectedProducts.length &&
                            productProvider.cart.isNotEmpty)
                          TextButton(
                            onPressed: () {
                              productProvider
                                  .removeSelectedProducts(); // Borra los artículos seleccionados
                            },
                            child: const Text(
                              'Borrar artículos seleccionados',
                              style:
                                  TextStyle(color: Colors.blue, fontSize: 16),
                            ),
                          ),
                      ],
                    )
                  ],
                ),
              ),

              // Lista de productos en la cesta
              Expanded(
                child: productProvider.cart.isEmpty
                    ? const Center(
                        child: Text(
                          'La cesta está vacía',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(1.0),
                        itemCount: productProvider.cart.length,
                        itemBuilder: (context, index) {
                          final product = productProvider.cart[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4.0),
                            child: ListTile(
                              leading: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Checkbox para marcar o desmarcar el producto
                                  Transform.scale(
                                    scale: 1.5,
                                    child: Checkbox(
                                      value: productProvider.selectedProducts
                                          .contains(product),
                                      onChanged: (value) {
                                        if (value == true) {
                                          productProvider
                                              .selectProduct(product);
                                        } else {
                                          productProvider
                                              .deselectProduct(product);
                                        }
                                      },
                                      shape: const CircleBorder(),
                                    ),
                                  ),
                                  const SizedBox(
                                      width:
                                          8), // Espaciado entre el checkbox y la imagen

                                  // Imagen del producto
                                  product.imageUrl.isNotEmpty
                                      ? Image.network(
                                          product.imageUrl,
                                          fit: BoxFit.cover,
                                          width: 50,
                                          height: 50,
                                        )
                                      : const Icon(Icons.image, size: 50),
                                ],
                              ),
                              title: Text(product.name),
                              subtitle: Row(
                                children: [
                                  const Text('COP ',
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold)),
                                  SizedBox(
                                    width: 50, // Ancho del campo editable
                                    child: TextFormField(
                                      controller: productProvider
                                          .getPriceController(product),
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold),
                                      decoration: const InputDecoration(
                                        border: InputBorder
                                            .none, // **Quita los bordes**
                                        contentPadding: EdgeInsets.symmetric(
                                            vertical: 2), // **Reduce altura**
                                        isDense: true, // **Compacta el campo**
                                      ),
                                      onChanged: (value) {
                                        double? newPrice = double.tryParse(
                                            value.replaceAll('.', ''));
                                        if (newPrice != null && newPrice > 0) {
                                          productProvider.updatePrice(
                                              product, newPrice);
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Botones de cantidad

                                  InputQty.int(
                                    maxVal: product.stock,
                                    initVal:
                                        productProvider.quantities[product] ??
                                            1,
                                    minVal: 1,
                                    steps: 1,
                                    decoration: const QtyDecorationProps(
                                      qtyStyle: QtyStyle
                                          .classic, // Adjust based on available styles
                                      orientation: ButtonOrientation.horizontal,
                                      isBordered: true,
                                      borderShape: BorderShapeBtn
                                          .square, // Use valid border shapes
                                    ),
                                    qtyFormProps: const QtyFormProps(
                                      cursorColor: Colors
                                          .blue, // Styling for the input field
                                    ),
                                    onQtyChanged: (value) {
                                      if (value <= product.stock) {
                                        // Actualiza solo si la cantidad es menor o igual al stock
                                        final invoiceProvider =
                                            Provider.of<InvoiceProvider>(
                                                context,
                                                listen: false);
                                        productProvider.updateQuantity(
                                            product, value, invoiceProvider);
                                        // Actualiza el subtotal en el InvoiceProvider
                                      } else {
                                        // Lógica opcional para notificar que se alcanzó el límite
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'No puedes seleccionar más de ${product.stock} unidades.',
                                              style:
                                                  const TextStyle(fontSize: 14),
                                            ),
                                            duration:
                                                const Duration(seconds: 2),
                                          ),
                                        );
                                      }
                                    },
                                  ),

                                  const SizedBox(
                                      width:
                                          8), // Espaciado entre botones y el icono delete

                                  // Botón de eliminar
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () {
                                      productProvider.removeFromCart(product);
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

          // Lista de productos (visible solo si la barra de búsqueda está activa)
          if (_isSearchActive)
            Positioned(
              top: 60,
              right: 10,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(12.0),
                child: Container(
                  width:
                      300, // La lista tiene el mismo ancho que la barra de búsqueda

                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: ListView.builder(
                    itemCount: productProvider.filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = productProvider.filteredProducts[index];
                      return GestureDetector(
                        onTap: () {
                          productProvider.addToCart(product);
                          setState(() {
                            _isSearchActive =
                                false; // Oculta la lista después de agregar
                          });
                        },
                        child: Card(
                          margin: const EdgeInsets.symmetric(vertical: 4.0),
                          child: ListTile(
                              leading: product.imageUrl.isNotEmpty
                                  ? Image.network(
                                      product.imageUrl,
                                      fit: BoxFit.cover,
                                      width: 50,
                                      height: 50,
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
                                    'Stock: ${product.stock}', // Muestra el stock disponible
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              )),
                        ),
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
}
