/*import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../widgets/image_carousel.dart';
import '../widgets/least_selling_carousel.dart';
import '../widgets/product_card.dart';
import '../widgets/search_bar.dart' as custom;
import '../widgets/top_selling_carousel.dart';
import '../widgets/whatsapp_logo_widget.dart';
import '../widgets/store_footer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const int _pageSize = 24;

  final ScrollController _scrollController = ScrollController();
  int _visibleCount = _pageSize;

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(() {
      final position = _scrollController.position;
      if (!position.hasPixels || !position.hasContentDimensions) return;

      final threshold = 600.0;
      final isNearBottom =
          position.pixels >= (position.maxScrollExtent - threshold);

      if (isNearBottom) {
        final total = context.read<ProductProvider>().products.length;
        if (_visibleCount < total) {
          setState(() {
            _visibleCount = (_visibleCount + _pageSize).clamp(0, total);
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    await context.read<ProductProvider>().fetchProducts();
    if (mounted) setState(() => _visibleCount = _pageSize);
  }

  int _crossAxisCountForWidth(double width) {
    // Objetivo: 6 por fila en desktop.
    // En pantallas pequeñas baja para evitar overflow.
    if (width >= 1200) return 6;
    if (width >= 992) return 5;
    if (width >= 820) return 4;
    if (width >= 600) return 3;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: custom.SearchBar(
        onSubmitted: (query) {
          context.read<ProductProvider>().filterProducts(query);
          Navigator.pushNamed(context, '/infoProducts', arguments: query);
        },
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          controller: _scrollController,
          children: [
            AspectRatio(
              aspectRatio: 2.7, // ancho / alto
              child: const ImageCarousel(),
            ),
            const SizedBox(height: 10),

            const TopSellingCarousel(),
            const SizedBox(height: 10),

            const LeastSellingCarousel(),
            const SizedBox(height: 10),

            // =========================
            // GRID DE PRODUCTOS
            // =========================
            Consumer<ProductProvider>(
              builder: (context, productProvider, child) {
                if (productProvider.isLoading) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final products = productProvider.products;

                if (products.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text('No hay productos disponibles'),
                    ),
                  );
                }

                final total = products.length;
                final countToShow = _visibleCount.clamp(0, total);
                final visibleProducts = products.take(countToShow).toList();

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final count = _crossAxisCountForWidth(constraints.maxWidth);

                    const paddingH = 12.0;
                    const spacing = 12.0;

                    final usableWidth = constraints.maxWidth - (paddingH * 2);
                    final itemWidth =
                        (usableWidth - (spacing * (count - 1))) / count;

                    // Tu diseño necesita ser más alto en grids densos (6 por fila).
                    // Ajusta este ratio: más pequeño => más alta la celda.
                    final ratio = (count >= 6) ? 0.62 : 0.72;

                    final itemHeight = itemWidth / ratio;

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                          horizontal: paddingH, vertical: 8),
                      itemCount: visibleProducts.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: count,
                        crossAxisSpacing: spacing,
                        mainAxisSpacing: spacing,
                        mainAxisExtent: itemHeight, // <-- altura garantizada
                      ),
                      itemBuilder: (_, i) =>
                          ProductCard(product: visibleProducts[i]),
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 20),

            Container(
              color: Colors.black,
              padding: const EdgeInsets.all(16.0),
              child: const Center(
                child: Text(
                  '© 2025 UD Electronics. Todos los derechos reservados.',
                  style: TextStyle(fontSize: 14, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: const WhatsAppLogoWidget(),
    );
  }
}
*/
// home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/product_provider.dart';
import '../widgets/image_carousel.dart';
import '../widgets/least_selling_carousel.dart';
import '../widgets/search_bar.dart' as custom;
import '../widgets/top_selling_carousel.dart';
import '../widgets/whatsapp_logo_widget.dart';
import '../widgets/store_footer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<void> _refresh() async {
    await context.read<ProductProvider>().fetchProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: custom.SearchBar(
        onSubmitted: (query) {
          context.read<ProductProvider>().filterProducts(query);
          Navigator.pushNamed(context, '/infoProducts', arguments: query);
        },
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const ClampingScrollPhysics(),
          children: [ // ✅ CORREGIDO: Retirado el const global de la lista
            // 1. Banner Principal de la Tienda (Hero Asset)
            const AspectRatio(
              aspectRatio: 2.7,
              child: ImageCarousel(),
            ),
            const SizedBox(height: 18),

            // 2. Carrusel Más Vendidos (Social Proof y Rotación Rápida)
            const TopSellingCarousel(),
            const SizedBox(height: 18),

            // 3. Carrusel De Liquidación / Liquidación Dinámica de Ofertas
            const LeastSellingCarousel(),
            const SizedBox(height: 36),

            // 4. Cierre Masivo Corporativo e Institucional (SEO Técnico)
            const StoreFooter(), // ✅ Ahora puede computar de forma dinámica
          ],
        ),
      ),
      floatingActionButton: const WhatsAppLogoWidget(),
    );
  }
}