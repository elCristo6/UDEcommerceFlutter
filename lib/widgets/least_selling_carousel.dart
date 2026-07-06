/*import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/product_provider.dart';
import 'product_card.dart';

class LeastSellingCarousel extends StatelessWidget {
  const LeastSellingCarousel({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        if (provider.isLoadingLeastSelling) {
          return const Center(child: CircularProgressIndicator());
        }

        final products = provider.leastSellingProducts;

        if (products.isEmpty) {
          return const Center(child: Text('No hay productos disponibles.'));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: Text(
                'Promociones',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(
              height: 360, // más alto para tu diseño (botón + qty + stock)
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                itemCount: products.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  return SizedBox(
                    width: 240, // ancho que se ve PRO en carrusel
                    child: ProductCard(product: products[index]),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
*/

// least_selling_carousel.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/product_provider.dart';
import 'product_card.dart';

class LeastSellingCarousel extends StatefulWidget {
  const LeastSellingCarousel({super.key});

  @override
  State<LeastSellingCarousel> createState() => _LeastSellingCarouselState();
}

class _LeastSellingCarouselState extends State<LeastSellingCarousel> {
  final ScrollController _scrollController = ScrollController();

  int _itemsPerView(double width) {
    if (width >= 1700) return 8;
    if (width >= 1450) return 7;
    if (width >= 1180) return 6;
    if (width >= 900) return 5;
    if (width >= 650) return 4;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 850;

    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        if (provider.isLoadingLeastSelling) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final products = provider.leastSellingProducts;
        if (products.isEmpty) return const SizedBox.shrink();

        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final itemsPerView = _itemsPerView(width);
            const horizontalPadding = 16.0;
            const spacing = 16.0;

            final usableWidth = width - (horizontalPadding * 2) - ((itemsPerView - 1) * spacing);
            final cardWidth = usableWidth / itemsPerView;
            final cardHeight = cardWidth / 0.62;

            return Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, isDesktop ? 18 : 10),
                    child: Row(
                      children: [
                        RichText(
                          text: const TextSpan(
                            children: [
                              TextSpan(text: 'Promociones ', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.black, letterSpacing: -0.5)),
                              TextSpan(text: 'Especiales 🏷️', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.purple, letterSpacing: -0.5)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        if (isDesktop)
                          Expanded(
                            child: Container(
                              height: 1.0,
                              color: Colors.black.withOpacity(0.08),
                    ),
                  ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: cardHeight + 40,
                    child: ListView.separated(
                      controller: _scrollController,
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
                      physics: const BouncingScrollPhysics(),
                      itemCount: products.length,
                      separatorBuilder: (_, __) => const SizedBox(width: spacing),
                      itemBuilder: (context, index) {
                        return SizedBox(
                          width: cardWidth,
                          child: ProductCard(product: products[index]),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}