/*import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product_model.dart';
import '../providers/product_provider.dart';
import '../widgets/product_details_modal.dart';
import '../widgets/product_edit_modal.dart';
import '../widgets/search_bar.dart' as custom;

class ProductInfoScreen extends StatelessWidget {
  const ProductInfoScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      // Use your custom SearchBar as the app bar.
      appBar: custom.SearchBar(
        onChanged: (searchTerm) {
          Provider.of<ProductProvider>(context, listen: false)
              .filterProducts(searchTerm);
        },
      ),
      // Use Expanded so that the table occupies all available space
      body: const Column(
        children: [
          Expanded(child: ProductInfoList()),
        ],
      ),
    );
  }
}

class ProductInfoList extends StatelessWidget {
  const ProductInfoList({Key? key}) : super(key: key);

  /// Formats a number with thousand separators (e.g. 35000 -> "35.000")
  String formatCurrency(num value) {
    final strVal = value.toStringAsFixed(0);
    return strVal.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (Match match) => '${match[1]}.',
    );
  }

  /// Formats a DateTime as "25 ENERO 2025"
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
    // Use the filtered list so that only matching products are shown
    final List<Product> products = productProvider.filteredProducts;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    if (products.isEmpty) {
      return const Center(child: Text('No hay productos disponibles.'));
    }

    // Compute available rows per page dynamically.
    // Here we assume an approximate row height of 56.0 and reserve some height for the header.
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
          context, // Pass context to show the modal
        ),
        rowsPerPage: computedRowsPerPage,
        columnSpacing: 10.0,
        horizontalMargin: 8.0,
      ),
    );
  }
}

/// Custom DataTableSource that builds rows on demand.
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

    final updatedAtText = product.updatedAt != null
        ? formatDate(product.updatedAt!)
        : 'Sin actualizar';

    return DataRow(
      cells: [
        // "Productos" column: use a Container with relative width
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
        // "Cantidad" column: using product.stock (adjust as needed)
        DataCell(Text(product.stock.toString())),
        // "Precio" column
        DataCell(Text(formattedPrice)),
        // "Caja" column
        DataCell(Text(product.box.isNotEmpty ? product.box.join(', ') : 'N/A')),
        // "Opciones" column: three icons (Details, Edit, Delete)
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.info, color: Colors.blue),
                tooltip: 'Detalles',
                onPressed: () {
                  // Show the modal with product details
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
                          // Una vez guardado en el servidor, refrescamos la lista
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
                  // Acción para eliminar producto
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
        // "Última modificación" column
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
