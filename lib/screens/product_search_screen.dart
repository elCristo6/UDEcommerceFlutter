// lib/screens/product_search_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/product_model.dart';
import '../providers/cart_provider.dart';
import '../providers/product_provider.dart';
import '../widgets/search_bar.dart' as custom;
import '../widgets/whatsapp_logo_widget.dart';
import '../widgets/store_footer.dart';

class ProductSearchScreen extends StatefulWidget {
  final String searchQuery;

  const ProductSearchScreen({Key? key, required this.searchQuery}) : super(key: key);

  @override
  State<ProductSearchScreen> createState() => _ProductSearchScreenState();
}

class _ProductSearchScreenState extends State<ProductSearchScreen> {
  String _sortOption = 'relevance';
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);

  // Paleta E-commerce Limpia y de Alto Contraste
  static const Color _lightBg = Color(0xFFF8FAFC);     // Gris azulado ultra claro
  static const Color _cardBg = Color(0xFFFFFFFF);      // Tarjeta blanca pura
  static const Color _darkText = Color(0xFF0F172A);    // Texto principal oscuro
  static const Color _mutedText = Color(0xFF64748B);   // Texto secundario
  static const Color _primaryBlue = Color(0xFF0284C7); // Azul primario para botones e íconos
  static const Color _borderColor = Color(0xFFE2E8F0); // Bordes suaves

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<ProductProvider>().filterProducts(widget.searchQuery);
    });
  }

  List<Product> _getSortedProducts(List<Product> products) {
    final List<Product> sorted = List.from(products);
    if (_sortOption == 'price_asc') {
      sorted.sort((a, b) => a.price.compareTo(b.price));
    } else if (_sortOption == 'price_desc') {
      sorted.sort((a, b) => b.price.compareTo(a.price));
    } else if (_sortOption == 'stock') {
      sorted.sort((a, b) => b.stock.compareTo(a.stock));
    }
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightBg,
      appBar: custom.SearchBar(
        initialQuery: widget.searchQuery,
        onSubmitted: (query) {
          context.read<ProductProvider>().filterProducts(query);
        },
      ),
      body: Consumer<ProductProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: _primaryBlue),
                  SizedBox(height: 16),
                  Text(
                    'Buscando componentes...',
                    style: TextStyle(color: _mutedText, fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            );
          }

          final rawProducts = provider.filteredProducts;
          final products = _getSortedProducts(rawProducts);

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ENCABEZADO DE BÚSQUEDA Y FILTROS
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(bottom: BorderSide(color: _borderColor)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Breadcrumb
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pushNamed(context, '/home'),
                            child: const Text('Inicio', style: TextStyle(color: _primaryBlue, fontSize: 13, fontWeight: FontWeight.w600)),
                          ),
                          const Icon(Icons.chevron_right, color: _mutedText, size: 16),
                          const Text('Resultados de Búsqueda', style: TextStyle(color: _mutedText, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Título con término buscado
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(fontSize: 22, color: _darkText, fontFamily: 'Raleway'),
                          children: [
                            const TextSpan(text: 'Resultados para '),
                            TextSpan(
                              text: '"${widget.searchQuery}"',
                              style: const TextStyle(fontWeight: FontWeight.w800, color: _primaryBlue),
                            ),
                            TextSpan(
                              text: ' (${products.length} productos)',
                              style: const TextStyle(fontSize: 15, color: _mutedText, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Filtros Rápidos / Ordenamiento
                      if (products.isNotEmpty)
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              const Icon(Icons.tune_rounded, size: 18, color: _mutedText),
                              const SizedBox(width: 6),
                              const Text('Ordenar: ', style: TextStyle(color: _mutedText, fontSize: 13, fontWeight: FontWeight.w600)),
                              const SizedBox(width: 8),
                              _sortChip('Relevancia', 'relevance'),
                              _sortChip('Precio: Menor a Mayor', 'price_asc'),
                              _sortChip('Precio: Mayor a Menor', 'price_desc'),
                              _sortChip('Disponibilidad', 'stock'),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // RESULTADOS O ESTADO VACÍO
              if (products.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(context),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 280, 
                      childAspectRatio: 0.58,   
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final product = products[index];
                        return _buildECommerceProductCard(context, product);
                      },
                      childCount: products.length,
                    ),
                  ),
                ),

              // PIE DE PÁGINA CORPORATIVO
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: StoreFooter(),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: const WhatsAppLogoWidget(),
    );
  }

  // --- TARJETA TIPO E-COMMERCE (FOTOS GIGANTES EDGE-TO-EDGE) ---
  Widget _buildECommerceProductCard(BuildContext context, Product product) {
    final bool hasStock = product.stock > 0;
    final bool isLowStock = product.stock > 0 && product.stock <= 5;
    final slug = product.slug.isNotEmpty ? product.slug : product.name.toLowerCase().replaceAll(' ', '-');

    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => Navigator.pushNamed(context, '/$slug'),
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. ÁREA DE IMAGEN GIGANTE Y SIN BORDES
              Expanded(
                flex: 7, // Le damos aún más porcentaje de la tarjeta a la foto
                child: Stack(
                  fit: StackFit.expand, // Fuerza a la imagen a llenar todo el contenedor
                  children: [
                    ClipRRect(
                      // Redondeamos únicamente las esquinas superiores para fusionarse con la tarjeta
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                      child: Container(
                        color: Colors.white, // Fondo puro para imágenes transparentes
                        child: product.images.isNotEmpty
                            ? Image.network(
                                Uri.encodeFull(product.images.first),
                                fit: BoxFit.cover, // ✅ EFECTO GIGANTE: Llena el 100% del área
                                width: double.infinity,
                                height: double.infinity,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.broken_image_outlined,
                                  color: _mutedText,
                                  size: 48,
                                ),
                              )
                            : const Icon(
                                Icons.memory_rounded,
                                color: _mutedText,
                                size: 48,
                              ),
                      ),
                    ),

                    // BADGE DE STOCK FLOTANTE
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: !hasStock
                              ? const Color(0xFFE11D48)
                              : isLowStock
                                  ? const Color(0xFFD97706)
                                  : const Color(0xFF16A34A),
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2))
                          ]
                        ),
                        child: Text(
                          !hasStock
                              ? 'AGOTADO'
                              : isLowStock
                                  ? 'ÚLTIMAS ${product.stock}'
                                  : 'EN STOCK',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 2. DETALLES DEL PRODUCTO, PRECIO Y BOTÓN DE CESTA
              Expanded(
                flex: 5, 
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Categoría
                          if (product.category.isNotEmpty)
                            Text(
                              product.category.toUpperCase(),
                              style: const TextStyle(
                                color: _primaryBlue,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          const SizedBox(height: 4),

                          // Nombre del Producto 
                          Text(
                            product.name,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _darkText,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),

                      // Bloque Inferior: Precio + Botón Agregar a Cesta
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(color: _borderColor, height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Precio Destacado
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Precio',
                                      style: TextStyle(color: _mutedText, fontSize: 10, fontWeight: FontWeight.w500),
                                    ),
                                    Text(
                                      _currencyFormat.format(product.price),
                                      style: const TextStyle(
                                        color: _darkText,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Botón de Cesta
                              Material(
                                color: hasStock ? _primaryBlue : const Color(0xFF94A3B8),
                                borderRadius: BorderRadius.circular(10),
                                child: InkWell(
                                  onTap: hasStock
                                      ? () async {
                                          await context.read<CartProvider>().addProduct(product, quantity: 1);
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Row(
                                                  children: [
                                                    const Icon(Icons.check_circle, color: Colors.white, size: 18),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                        '${product.name} agregado a la cesta',
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                duration: const Duration(seconds: 2),
                                                backgroundColor: const Color(0xFF16A34A),
                                                behavior: SnackBarBehavior.floating,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                              ),
                                            );
                                          }
                                        }
                                      : null,
                                  borderRadius: BorderRadius.circular(10),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.add_shopping_cart_rounded, color: Colors.white, size: 16),
                                        SizedBox(width: 4),
                                        Text(
                                          'Agregar',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Chips de Selección de Orden
  Widget _sortChip(String label, String value) {
    final bool isSelected = _sortOption == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) setState(() => _sortOption = value);
        },
        selectedColor: _primaryBlue,
        backgroundColor: Colors.white,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : _mutedText,
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: isSelected ? _primaryBlue : _borderColor),
        ),
      ),
    );
  }

  // Pantalla para cuando no hay resultados de búsqueda
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Color(0x0F000000), blurRadius: 16, offset: Offset(0, 4)),
                ],
              ),
              child: const Icon(Icons.search_off_rounded, color: _primaryBlue, size: 56),
            ),
            const SizedBox(height: 20),
            Text(
              'No encontramos resultados para "${widget.searchQuery}"',
              textAlign: TextAlign.center,
              style: const TextStyle(color: _darkText, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Verifica que el nombre o la categoría estén bien escritos.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _mutedText, fontSize: 14),
            ),
            const SizedBox(height: 24),
            const Text(
              'Búsquedas sugeridas:',
              style: TextStyle(color: _darkText, fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _suggestionChip(context, 'ESP32'),
                _suggestionChip(context, 'Arduino'),
                _suggestionChip(context, 'Filamento 3D'),
                _suggestionChip(context, 'Sensores'),
                _suggestionChip(context, 'Robótica'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _suggestionChip(BuildContext context, String term) {
    return ActionChip(
      label: Text(term),
      backgroundColor: Colors.white,
      labelStyle: const TextStyle(color: _primaryBlue, fontSize: 12, fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: _borderColor),
      ),
      onPressed: () {
        context.read<ProductProvider>().filterProducts(term);
        Navigator.pushReplacementNamed(context, '/search', arguments: term);
      },
    );
  }
}