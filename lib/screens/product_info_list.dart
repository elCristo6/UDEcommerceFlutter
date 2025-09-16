/*import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product_model.dart';
import '../providers/product_provider.dart';
import '../widgets/product_create_modal.dart';
import '../widgets/product_details_modal.dart';
import '../widgets/product_edit_modal.dart';
import '../widgets/search_bar.dart' as custom;

class ProductInfoScreen extends StatelessWidget {
  const ProductInfoScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      // Usa tu SearchBar personalizada como appBar.
      appBar: custom.SearchBar(
        onChanged: (searchTerm) {
          Provider.of<ProductProvider>(context, listen: false)
              .filterProducts(searchTerm);
        },
      ),
      body: const Column(
        children: [
          Expanded(child: ProductInfoList()),
        ],
      ),
      // Botón flotante para crear un nuevo producto
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
              return ProductCreateModal(
                onSave: (newProduct) async {
                  // Una vez creado el producto, refrescamos la lista.
                  await Provider.of<ProductProvider>(context, listen: false)
                      .fetchProducts(forceUpdate: true);
                },
              );
            },
          );
        },
        child: const Icon(Icons.add),
      ),
      // Usamos la ubicación personalizada para situarlo en la esquina superior derecha.
      floatingActionButtonLocation: TopRightFloatingActionButtonLocation(),
    );
  }
}

class ProductInfoList extends StatelessWidget {
  const ProductInfoList({Key? key}) : super(key: key);

  /// Formatea la moneda con puntos de mil (ej: 35000 -> "35.000")
  String formatCurrency(num value) {
    final strVal = value.toStringAsFixed(0);
    return strVal.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (Match match) => '${match[1]}.',
    );
  }

  /// Formatea la fecha en estilo "25 ENERO 2025"
  String _formatDate(DateTime date) {
    final months = [
      'ENERO',
      'FEBRERO',
      'MARZO',
      'ABRIL',
      'MAYO',
      'JUNIO',
      'JULIO',
      'AGOSTO',
      'SEPTIEMBRE',
      'OCTUBRE',
      'NOVIEMBRE',
      'DICIEMBRE'
    ];
    final day = date.day.toString().padLeft(2, '0');
    final month = months[date.month - 1];
    final year = date.year.toString();
    return "$day $month $year";
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final List<Product> products = productProvider.filteredProducts;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    if (products.isEmpty) {
      return const Center(child: Text('No hay productos disponibles.'));
    }

    // Calcula las filas por página de forma dinámica
    final int computedRowsPerPage =
        ((screenHeight * 0.7 - 56) / 56).floor().clamp(1, products.length);

    return Container(
      width: screenWidth,
      padding: const EdgeInsets.all(8.0),
      child: PaginatedDataTable(
        header: const Text('Información de Productos'),
        columns: const [
          DataColumn(label: Text('Productos')),
          DataColumn(label: Text('Cantidad')),
          DataColumn(label: Text('Precio')),
          DataColumn(label: Text('Caja')),
          DataColumn(label: Text('Opciones')),
          DataColumn(label: Text('Última modificación')),
        ],
        source: ProductDataSource(
          products,
          screenWidth,
          formatCurrency,
          _formatDate,
          context,
        ),
        rowsPerPage: computedRowsPerPage,
        columnSpacing: 10.0,
        horizontalMargin: 8.0,
      ),
    );
  }
}

/// DataTableSource personalizado para construir las filas según se necesiten.
class ProductDataSource extends DataTableSource {
  final List<Product> products;
  final double screenWidth;
  final String Function(num) formatCurrency;
  final String Function(DateTime) formatDate;
  final BuildContext context;

  ProductDataSource(
    this.products,
    this.screenWidth,
    this.formatCurrency,
    this.formatDate,
    this.context,
  );

  @override
  DataRow? getRow(int index) {
    if (index >= products.length) return null;
    final product = products[index];
    final formattedPrice = "\$${formatCurrency(product.price)}";
    final boxText = product.box.isNotEmpty ? product.box.join(', ') : 'N/A';
    final updatedAtText = product.updatedAt != null
        ? formatDate(product.updatedAt!)
        : 'Sin actualizar';

    return DataRow(
      cells: [
        DataCell(
          Container(
            width: screenWidth * 0.35,
            child: Text(
              product.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
              softWrap: true,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ),
        DataCell(Text(product.stock.toString())),
        DataCell(Text(formattedPrice)),
        DataCell(Text(boxText)),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.info, color: Colors.blue),
                tooltip: 'Detalles',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return ProductDetailsModal(product: product);
                    },
                  );
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.orange),
                tooltip: 'Editar',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return ProductEditModal(
                        product: product,
                        onSave: (updatedProduct) async {
                          await Provider.of<ProductProvider>(context,
                                  listen: false)
                              .fetchProducts(forceUpdate: true);
                        },
                      );
                    },
                  );
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                tooltip: 'Eliminar',
                onPressed: () {
                  // Acción para eliminar producto.
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
        DataCell(Text(updatedAtText)),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;
  @override
  int get rowCount => products.length;
  @override
  int get selectedRowCount => 0;
}

/// Ubicación personalizada para el FloatingActionButton en la esquina superior derecha.
class TopRightFloatingActionButtonLocation
    extends FloatingActionButtonLocation {
  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    // Margen de 16 píxeles desde el top y right.
    final double fabX = scaffoldGeometry.scaffoldSize.width -
        scaffoldGeometry.floatingActionButtonSize.width -
        16.0;

    const double fabY = 145.0; // Desde el top
    return Offset(fabX, fabY);
  }
}
*/
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product_model.dart';
import '../providers/product_provider.dart';
import '../widgets/product_create_modal.dart';
import '../widgets/product_details_modal.dart';
import '../widgets/product_edit_modal.dart';
import '../widgets/search_bar.dart' as custom;

class ProductInfoScreen extends StatelessWidget {
  const ProductInfoScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: custom.SearchBar(
        onChanged: (searchTerm) {
          Provider.of<ProductProvider>(context, listen: false)
              .filterProducts(searchTerm);
        },
      ),
      body: const ProductInfoList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
              return ProductCreateModal(
                onSave: (newProduct) async {
                  await Provider.of<ProductProvider>(context, listen: false)
                      .fetchProducts(forceUpdate: true);
                },
              );
            },
          );
        },
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: TopRightFloatingActionButtonLocation(),
    );
  }
}

class ProductInfoList extends StatelessWidget {
  const ProductInfoList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final List<Product> products = productProvider.filteredProducts;

    if (products.isEmpty) {
      return const Center(child: Text('No hay productos disponibles.'));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4, // Cuatro productos por fila
        childAspectRatio:
            0.65, // Relación de aspecto ajustada para dar un diseño compacto
        crossAxisSpacing: 8.0, // Espacio horizontal entre los productos
        mainAxisSpacing: 8.0, // Espacio vertical entre los productos
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return ProductCard(product: product); // Usamos el ProductCard existente
      },
    );
  }
}

/// ProductCard Widget con los iconos de acción y datos como stock, caja, última actualización.
class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Imagen del producto
          Expanded(
            flex: 3, // Ajustamos el flex para que la imagen ocupe más espacio
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10.0),
                topRight: Radius.circular(10.0),
              ),
              child: product.images.isNotEmpty
                  ? Image.network(
                      product.images.first,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.broken_image, size: 50),
                    )
                  : Image.asset(
                      'assets/placeholder.png', // Imagen por defecto si no hay
                      fit: BoxFit.cover,
                    ),
            ),
          ),
          // Información del producto
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nombre del producto
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12, // Reducimos el tamaño del texto
                  ),
                ),
                const SizedBox(height: 4),
                // Precio del producto
                Text(
                  'COP ${product.price}',
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 14, // Ajuste de tamaño del precio
                  ),
                ),
                const SizedBox(height: 4),
                // Caja
                Text(
                  'Caja: ${product.box.isNotEmpty ? product.box.join(', ') : 'N/A'}',
                  style: const TextStyle(fontSize: 10),
                ),
                const SizedBox(height: 4),
                // Última actualización
                Text(
                  'Última actualización: ${product.updatedAt != null ? _formatDate(product.updatedAt!) : 'Sin actualizar'}',
                  style: const TextStyle(fontSize: 10),
                ),
                const SizedBox(height: 4),
                // Cantidad
                Text(
                  'Cantidad: ${product.stock}',
                  style: const TextStyle(fontSize: 10),
                ),
              ],
            ),
          ),
          // Los iconos de acción (Detalles, Editar, Eliminar)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.info, size: 18, color: Colors.blue),
                  tooltip: 'Detalles',
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return ProductDetailsModal(product: product);
                      },
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 18, color: Colors.orange),
                  tooltip: 'Editar',
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return ProductEditModal(
                          product: product,
                          onSave: (updatedProduct) async {
                            await Provider.of<ProductProvider>(context,
                                    listen: false)
                                .fetchProducts(forceUpdate: true);
                          },
                        );
                      },
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                  tooltip: 'Eliminar',
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        String password = '';
                        return AlertDialog(
                          title: const Text('Confirmar eliminación'),
                          content: TextField(
                            autofocus: true,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Ingrese la contraseña',
                            ),
                            onChanged: (value) {
                              password = value;
                            },
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context)
                                    .pop(); // Cierra el diálogo
                              },
                              child: const Text('Cancelar'),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                if (password == '6038') {
                                  // Llama al método deleteProduct del provider
                                  await Provider.of<ProductProvider>(context,
                                          listen: false)
                                      .deleteProduct(product.id);
                                  Navigator.of(context)
                                      .pop(); // Cierra el diálogo
                                } else {
                                  // Opcional: mostrar mensaje de error por contraseña incorrecta
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Contraseña incorrecta')),
                                  );
                                }
                              },
                              child: const Text('Ok'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Método auxiliar para formatear la fecha
  String _formatDate(DateTime date) {
    final months = [
      'ENERO',
      'FEBRERO',
      'MARZO',
      'ABRIL',
      'MAYO',
      'JUNIO',
      'JULIO',
      'AGOSTO',
      'SEPTIEMBRE',
      'OCTUBRE',
      'NOVIEMBRE',
      'DICIEMBRE'
    ];
    final day = date.day.toString().padLeft(2, '0');
    final month = months[date.month - 1];
    final year = date.year.toString();
    return "$day $month $year";
  }
}

/// Ubicación personalizada para el FloatingActionButton en la esquina superior derecha.
class TopRightFloatingActionButtonLocation
    extends FloatingActionButtonLocation {
  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final double fabX = scaffoldGeometry.scaffoldSize.width -
        scaffoldGeometry.floatingActionButtonSize.width -
        16.0;

    const double fabY = 145.0; // Desde el top
    return Offset(fabX, fabY);
  }
}
