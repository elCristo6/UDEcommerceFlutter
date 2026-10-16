// top_selling_carousel.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/product_provider.dart';
import 'product_card.dart';

class TopSellingCarousel extends StatefulWidget {
  const TopSellingCarousel({super.key});

  @override
  State<TopSellingCarousel> createState() => _TopSellingCarouselState();
}

class _TopSellingCarouselState extends State<TopSellingCarousel> {
  final ScrollController _scrollController = ScrollController();
  bool _canScrollLeft = false;
  bool _canScrollRight = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateArrows);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateArrows());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateArrows);
    _scrollController.dispose();
    super.dispose();
  }

  void _updateArrows() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    final canLeft = position.pixels > 8;
    final canRight = position.pixels < (position.maxScrollExtent - 8);

    if (canLeft != _canScrollLeft || canRight != _canScrollRight) {
      setState(() {
        _canScrollLeft = canLeft;
        _canScrollRight = canRight;
      });
    }
  }

  int _itemsPerView(double width) {
    if (width >= 1700) return 8;
    if (width >= 1450) return 7;
    if (width >= 1180) return 6;
    if (width >= 900) return 5;
    if (width >= 650) return 4;
    return 2;
  }

  double _cardWidth({
    required double screenWidth,
    required int itemsPerView,
    double horizontalPadding = 24,
    double spacing = 16,
  }) {
    final usableWidth =
        screenWidth - horizontalPadding - ((itemsPerView - 1) * spacing);
    return usableWidth / itemsPerView;
  }

  double _cardHeight(double cardWidth) {
    const ratio = 0.62;
    return cardWidth / ratio;
  }

  Future<void> _scrollByAmount(double amount) async {
    if (!_scrollController.hasClients) return;
    final current = _scrollController.offset;
    final max = _scrollController.position.maxScrollExtent;
    final target = (current + amount).clamp(0.0, max);

    await _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 850;

    return Consumer<ProductProvider>(
      builder: (context, provider, child) {
        if (provider.isLoadingTopSelling) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final products = provider.topSellingProducts;
        if (products.isEmpty) return const SizedBox.shrink();

        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final itemsPerView = _itemsPerView(width);
            const horizontalPadding = 16.0;
            const spacing = 16.0;

            final cardWidth = _cardWidth(
              screenWidth: width,
              itemsPerView: itemsPerView,
              horizontalPadding: horizontalPadding * 2,
              spacing: spacing,
            );

            final cardHeight = _cardHeight(cardWidth);
            final pageJump = (cardWidth + spacing) * (itemsPerView - 0.15);

            WidgetsBinding.instance
                .addPostFrameCallback((_) => _updateArrows());

            return Container(
              color: const Color(0xFFF8F9FB),
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(isDesktop),
                  SizedBox(
                    height: cardHeight + 40,
                    child: Stack(
                      children: [
                        ListView.separated(
                          controller: _scrollController,
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                              horizontal: horizontalPadding),
                          physics: const BouncingScrollPhysics(),
                          itemCount: products.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: spacing),
                          itemBuilder: (context, index) {
                            return SizedBox(
                              width: cardWidth,
                              child: ProductCard(product: products[index]),
                            );
                          },
                        ),
                        if (isDesktop) ...[
                          _buildArrow(
                            icon: Icons.chevron_left_rounded,
                            visible: _canScrollLeft,
                            alignment: Alignment.centerLeft,
                            onTap: () => _scrollByAmount(-pageJump),
                          ),
                          _buildArrow(
                            icon: Icons.chevron_right_rounded,
                            visible: _canScrollRight,
                            alignment: Alignment.centerRight,
                            onTap: () => _scrollByAmount(pageJump),
                          ),
                        ]
                      ],
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

  Widget _buildSectionTitle(bool isDesktop) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, isDesktop ? 18 : 10),
      child: Row(
        children: [
          RichText(
            text: const TextSpan(
              children: [
                TextSpan(
                    text: 'Más ',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                        letterSpacing: -0.5)),
                TextSpan(
                    text: 'vendidos 🔥',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1976D2),
                        letterSpacing: -0.5)),
              ],
            ),
          ),
          const SizedBox(width: 14),
          if (isDesktop)
            Expanded(
              child: Container(
                height: 1.0,
                color: Colors.black.withValues(alpha: 0.08),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildArrow({
    required IconData icon,
    required VoidCallback onTap,
    required bool visible,
    required Alignment alignment,
  }) {
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: visible ? 1 : 0,
        child: Align(
          alignment: alignment,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Material(
              color: Colors.white,
              elevation: 4,
              borderRadius: BorderRadius.circular(999),
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: onTap,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: Colors.black.withValues(alpha: 0.05)),
                  ),
                  child: Icon(icon, size: 22, color: Colors.black87),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
