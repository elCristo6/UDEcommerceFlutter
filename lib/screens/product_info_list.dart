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

class ProductInfoScreen extends StatefulWidget {
  const ProductInfoScreen({
    super.key,
  });

  @override
  State<ProductInfoScreen> createState() =>
      _ProductInfoScreenState();
}

class _ProductInfoScreenState extends State<ProductInfoScreen> {
  bool _argumentsProcessed = false;
  String _currentSearchTerm = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_argumentsProcessed) {
      return;
    }

    _argumentsProcessed = true;

    final arguments =
        ModalRoute.of(context)?.settings.arguments;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _processNavigationArguments(arguments);
    });
  }

  Future<void> _processNavigationArguments(
    Object? arguments,
  ) async {
    final provider = context.read<ProductProvider>();

    if (arguments is Map) {
      final type = arguments['type']?.toString();

      // ============================================================
      // NAVEGACIÓN DESDE UNA CATEGORÍA
      // ============================================================
      if (type == 'category') {
        final categoryId =
            arguments['categoryId']?.toString().trim() ?? '';

        final categoryName =
            arguments['categoryName']?.toString().trim() ?? '';

        if (categoryId.isEmpty) {
          return;
        }

        if (mounted) {
          setState(() {
            _currentSearchTerm = '';
          });
        }

        /*
         * HomeScreen normalmente consulta la categoría antes
         * de navegar. Esta validación evita repetir el GET.
         */
        if (provider.selectedCategoryId != categoryId) {
          await provider.filterProductsByCategory(
            categoryId: categoryId,
            categoryName: categoryName,
          );
        }

        return;
      }

      // ============================================================
      // NAVEGACIÓN DESDE UNA BÚSQUEDA GLOBAL
      // ============================================================
      if (type == 'search') {
        final query =
            arguments['query']?.toString().trim() ?? '';

        if (query.isEmpty) {
          provider.clearSearch();

          if (mounted) {
            setState(() {
              _currentSearchTerm = '';
            });
          }

          return;
        }

        if (mounted) {
          setState(() {
            _currentSearchTerm = query;
          });
        }

        /*
         * filterProducts debe buscar siempre sobre _products
         * y eliminar cualquier filtro de categoría activo.
         */
        provider.filterProducts(query);

        return;
      }
    }

    // ==============================================================
    // COMPATIBILIDAD CON NAVEGACIÓN ANTERIOR
    // arguments: "arduino"
    // ==============================================================
    if (arguments is String) {
      final query = arguments.trim();

      if (query.isEmpty) {
        provider.clearSearch();

        if (mounted) {
          setState(() {
            _currentSearchTerm = '';
          });
        }

        return;
      }

      if (mounted) {
        setState(() {
          _currentSearchTerm = query;
        });
      }

      provider.filterProducts(query);
    }
  }

  /// Se ejecuta mientras se escribe en el buscador.
  /// La búsqueda siempre es global.
  void _onSearchChanged(String searchTerm) {
    final query = searchTerm.trim();

    if (mounted) {
      setState(() {
        _currentSearchTerm = searchTerm;
      });
    }

    final provider = context.read<ProductProvider>();

    if (query.isEmpty) {
      provider.clearSearch();
      return;
    }

    provider.filterProducts(searchTerm);
  }

  /// Se ejecuta al presionar Enter.
  /// Como ya estamos en ProductInfoScreen, no abre otra pantalla:
  /// actualiza los resultados en esta misma página.
  void _onSearchSubmitted(String searchTerm) {
    final query = searchTerm.trim();

    if (query.isEmpty) {
      return;
    }

    if (mounted) {
      setState(() {
        _currentSearchTerm = query;
      });
    }

    context
        .read<ProductProvider>()
        .filterProducts(query);
  }

  Future<void> _refreshProducts() async {
    final provider = context.read<ProductProvider>();

    // Si estamos visualizando una categoría, refrescamos esa categoría.
    if (provider.isFilteringByCategory) {
      final categoryId =
          provider.selectedCategoryId;

      final categoryName =
          provider.selectedCategoryName;

      if (categoryId != null &&
          categoryName != null) {
        await provider.filterProductsByCategory(
          categoryId: categoryId,
          categoryName: categoryName,
        );

        return;
      }
    }

    // Si estamos en una búsqueda global, recargamos todos y reaplicamos.
    final currentQuery =
        _currentSearchTerm.trim();

    await provider.fetchProducts(
      forceUpdate: true,
    );

    if (currentQuery.isNotEmpty) {
      provider.filterProducts(currentQuery);
    }
  }

  void _clearCategoryFilter() {
    final provider =
        context.read<ProductProvider>();

    provider.clearCategoryFilter();

    if (mounted) {
      setState(() {
        _currentSearchTerm = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider =
        context.watch<ProductProvider>();

    return Scaffold(
      backgroundColor: Colors.grey[200],

      appBar: custom.SearchBar(
        /*
         * Para que el término enviado desde HomeScreen
         * aparezca escrito en la nueva barra.
         */
        initialQuery: _currentSearchTerm,
        onChanged: _onSearchChanged,
        onSubmitted: _onSearchSubmitted,
      ),

      body: Column(
        children: [
          if (provider.isFilteringByCategory)
            _CategoryFilterHeader(
              categoryName:
                  provider.selectedCategoryName ??
                      'Categoría',
              productCount:
                  provider.filteredProducts.length,
              onClear: _clearCategoryFilter,
            ),

          if (provider.isLoading ||
              provider.isLoadingCategory)
            const LinearProgressIndicator(
              minHeight: 3,
            ),

          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshProducts,
              child: ProductInfoList(
                searchTerm: _currentSearchTerm,
              ),
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (dialogContext) {
              return ProductCreateModal(
                onSave: (newProduct) async {
                  final provider =
                      context.read<ProductProvider>();

                  await provider.fetchProducts(
                    forceUpdate: true,
                  );

                  final query =
                      _currentSearchTerm.trim();

                  if (query.isNotEmpty) {
                    provider.filterProducts(query);
                  }
                },
              );
            },
          );
        },
        child: const Icon(Icons.add),
      ),

      floatingActionButtonLocation:
          TopRightFloatingActionButtonLocation(),
    );
  }
}

class _CategoryFilterHeader extends StatelessWidget {
  final String categoryName;
  final int productCount;
  final VoidCallback onClear;

  const _CategoryFilterHeader({
    required this.categoryName,
    required this.productCount,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade300,
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.category_outlined,
            color: Color(0xFF168CFF),
            size: 21,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              categoryName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            '$productCount productos',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 12),
          TextButton.icon(
            onPressed: onClear,
            icon: const Icon(
              Icons.close,
              size: 18,
            ),
            label: const Text(
              'Ver todos',
            ),
          ),
        ],
      ),
    );
  }
}

class ProductInfoList extends StatelessWidget {
  final String searchTerm;

  const ProductInfoList({
    super.key,
    this.searchTerm = '',
  });

  @override
  Widget build(BuildContext context) {
    final productProvider =
        context.watch<ProductProvider>();

    if (productProvider.isLoadingCategory ||
        productProvider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (productProvider.categoryFilterError !=
        null) {
      return _CategoryErrorView(
        message:
            productProvider.categoryFilterError!,
      );
    }

    if (productProvider.productsError != null &&
        productProvider.products.isEmpty) {
      return _ProductsErrorView(
        message:
            productProvider.productsError!,
      );
    }

    final List<Product> products =
        productProvider.filteredProducts;

    if (products.isEmpty) {
      return _EmptyProductsView(
        isCategoryFilter:
            productProvider.isFilteringByCategory,
        categoryName:
            productProvider.selectedCategoryName,
        searchTerm: searchTerm,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount =
            _calculateCrossAxisCount(
          constraints.maxWidth,
        );

        return GridView.builder(
          physics:
              const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(12),
          gridDelegate:
              SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.65,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            return ProductCard(
              product: products[index],
              activeSearchTerm: searchTerm,
            );
          },
        );
      },
    );
  }

  int _calculateCrossAxisCount(
    double width,
  ) {
    if (width >= 1400) return 5;
    if (width >= 1050) return 4;
    if (width >= 750) return 3;
    if (width >= 500) return 2;

    return 1;
  }
}

class _EmptyProductsView extends StatelessWidget {
  final bool isCategoryFilter;
  final String? categoryName;
  final String searchTerm;

  const _EmptyProductsView({
    required this.isCategoryFilter,
    required this.categoryName,
    required this.searchTerm,
  });

  @override
  Widget build(BuildContext context) {
    String message;

    if (searchTerm.trim().isNotEmpty) {
      message =
          'No se encontraron productos para "$searchTerm".';
    } else if (isCategoryFilter) {
      message =
          'No hay productos asignados a '
          '${categoryName ?? 'esta categoría'}.';
    } else {
      message =
          'No hay productos disponibles.';
    }

    return ListView(
      physics:
          const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height:
              MediaQuery.of(context).size.height *
                  0.55,
          child: Center(
            child: Padding(
              padding:
                  const EdgeInsets.all(24),
              child: Column(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 55,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    message,
                    textAlign:
                        TextAlign.center,
                    style: TextStyle(
                      color:
                          Colors.grey.shade700,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryErrorView extends StatelessWidget {
  final String message;

  const _CategoryErrorView({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final provider =
        context.read<ProductProvider>();

    return ListView(
      physics:
          const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height:
              MediaQuery.of(context).size.height *
                  0.55,
          child: Center(
            child: Padding(
              padding:
                  const EdgeInsets.all(24),
              child: Column(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 55,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'No fue posible cargar la categoría',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    textAlign:
                        TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      final categoryId =
                          provider.selectedCategoryId;

                      final categoryName =
                          provider.selectedCategoryName;

                      if (categoryId != null &&
                          categoryName != null) {
                        provider
                            .filterProductsByCategory(
                          categoryId:
                              categoryId,
                          categoryName:
                              categoryName,
                        );
                      }
                    },
                    icon: const Icon(
                      Icons.refresh,
                    ),
                    label: const Text(
                      'Reintentar',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProductsErrorView extends StatelessWidget {
  final String message;

  const _ProductsErrorView({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics:
          const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height:
              MediaQuery.of(context).size.height *
                  0.55,
          child: Center(
            child: Padding(
              padding:
                  const EdgeInsets.all(24),
              child: Column(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.cloud_off_outlined,
                    size: 55,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'No fue posible cargar los productos',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    textAlign:
                        TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      context
                          .read<ProductProvider>()
                          .fetchProducts(
                            forceUpdate: true,
                          );
                    },
                    icon: const Icon(
                      Icons.refresh,
                    ),
                    label: const Text(
                      'Reintentar',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ProductCard extends StatelessWidget {
  final Product product;
  final String activeSearchTerm;

  const ProductCard({
    super.key,
    required this.product,
    this.activeSearchTerm = '',
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(10),
      ),
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: Container(
              color: Colors.white,
              child: product.images.isNotEmpty
                  ? Image.network(
                      product.images.first,
                      fit: BoxFit.contain,
                      loadingBuilder: (
                        context,
                        child,
                        loadingProgress,
                      ) {
                        if (loadingProgress == null) {
                          return child;
                        }

                        return const Center(
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        );
                      },
                      errorBuilder: (
                        context,
                        error,
                        stackTrace,
                      ) {
                        return const Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            size: 50,
                          ),
                        );
                      },
                    )
                  : Image.asset(
                      'assets/placeholder.png',
                      fit: BoxFit.contain,
                      errorBuilder: (
                        context,
                        error,
                        stackTrace,
                      ) {
                        return const Center(
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            size: 50,
                          ),
                        );
                      },
                    ),
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 2,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'COP ${product.price.toStringAsFixed(0)}',
                  style:
                      const TextStyle(
                    color: Colors.red,
                    fontWeight:
                        FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Caja: '
                  '${product.box.isNotEmpty ? product.box.join(', ') : 'N/A'}',
                  style:
                      const TextStyle(
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Última actualización: '
                  '${product.updatedAt != null ? _formatDate(product.updatedAt!) : 'Sin actualizar'}',
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      const TextStyle(
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Cantidad: ${product.stock}',
                  style:
                      const TextStyle(
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 6,
              vertical: 4,
            ),
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.info,
                    size: 18,
                    color: Colors.blue,
                  ),
                  tooltip: 'Detalles',
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder:
                          (dialogContext) {
                        return ProductDetailsModal(
                          product: product,
                        );
                      },
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(
                    Icons.edit,
                    size: 18,
                    color: Colors.orange,
                  ),
                  tooltip: 'Editar',
                  onPressed: () {
                    _openEditModal(context);
                  },
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete,
                    size: 18,
                    color: Colors.red,
                  ),
                  tooltip: 'Eliminar',
                  onPressed: () {
                    _showDeleteDialog(
                      context,
                      product,
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

  void _openEditModal(
    BuildContext context,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return ProductEditModal(
          product: product,
          onSave: (updatedProduct) async {
            final provider =
                context.read<ProductProvider>();

            await provider.fetchProducts(
              forceUpdate: true,
            );

            final query =
                activeSearchTerm.trim();

            if (query.isNotEmpty) {
              provider.filterProducts(query);
              return;
            }

            if (provider.isFilteringByCategory) {
              final categoryId =
                  provider.selectedCategoryId;

              final categoryName =
                  provider.selectedCategoryName;

              if (categoryId != null &&
                  categoryName != null) {
                await provider
                    .filterProductsByCategory(
                  categoryId: categoryId,
                  categoryName: categoryName,
                );
              }
            }
          },
        );
      },
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    Product product,
  ) {
    final passwordController =
        TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Confirmar eliminación',
          ),
          content: TextField(
            controller:
                passwordController,
            autofocus: true,
            obscureText: true,
            decoration:
                const InputDecoration(
              labelText:
                  'Ingrese la contraseña',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext)
                    .pop();
              },
              child:
                  const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (passwordController.text !=
                    '6038') {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Contraseña incorrecta',
                      ),
                    ),
                  );

                  return;
                }

                try {
                  await context
                      .read<ProductProvider>()
                      .deleteProduct(
                        product.id,
                      );

                  if (!dialogContext.mounted) {
                    return;
                  }

                  Navigator.of(dialogContext)
                      .pop();
                } catch (error) {
                  if (!context.mounted) {
                    return;
                  }

                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    SnackBar(
                      content: Text(
                        'Error al eliminar: $error',
                      ),
                    ),
                  );
                }
              },
              child:
                  const Text('Eliminar'),
            ),
          ],
        );
      },
    ).whenComplete(
      passwordController.dispose,
    );
  }

  String _formatDate(DateTime date) {
    const months = [
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
      'DICIEMBRE',
    ];

    final day =
        date.day.toString().padLeft(2, '0');

    final month =
        months[date.month - 1];

    final year =
        date.year.toString();

    return '$day $month $year';
  }
}

class TopRightFloatingActionButtonLocation
    extends FloatingActionButtonLocation {
  @override
  Offset getOffset(
    ScaffoldPrelayoutGeometry scaffoldGeometry,
  ) {
    final fabX =
        scaffoldGeometry.scaffoldSize.width -
            scaffoldGeometry
                .floatingActionButtonSize.width -
            16;

    const fabY = 145.0;

    return Offset(fabX, fabY);
  }
}
