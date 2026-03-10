import 'dart:ui' show ImageFilter;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product_model.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../screens/product_detail_screen.dart';

class ProductCard extends StatefulWidget {
  final Product product;

  const ProductCard({
    super.key,
    required this.product,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _hover = false;

  bool _isNew(Product p) {
    final updated = p.updatedAt;
    if (updated == null) return false;
    return DateTime.now().difference(updated).inDays <= 30;
  }

  bool get _isDesktopHover =>
      kIsWeb ||
      {TargetPlatform.macOS, TargetPlatform.windows, TargetPlatform.linux}
          .contains(Theme.of(context).platform);

  Future<void> _addToCart(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final cart = context.read<CartProvider>();

    final String? token = auth.token;
    final appliedPrice = widget.product.price.toInt();
    final role = auth.role; // 'admin' o 'user' etc

    await cart.addProduct(
      widget.product,
      quantity: 1,
      token: (token != null && token.isNotEmpty) ? token : null,
      role: role,
      appliedPrice: appliedPrice,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.product.name} agregado a la cesta'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _preview(BuildContext context) {
    final p = widget.product;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: _ProductImage(
                      url: p.images.isNotEmpty ? p.images.first : null,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  p.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 16,
                      color: (p.stock <= 0)
                          ? Colors.grey
                          : const Color(0xFF16A34A),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Stock: ${p.stock} disponibles',
                      style: TextStyle(
                        fontSize: 13,
                        color: (p.stock <= 0)
                            ? Colors.grey.shade700
                            : const Color(0xFF166534),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'COP ${p.price}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProductDetailScreen(product: p),
                            ),
                          );
                        },
                        icon: const Icon(Icons.visibility_outlined),
                        label: const Text('Ver ficha'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: (p.stock <= 0)
                            ? null
                            : () async {
                                Navigator.pop(context);
                                await _addToCart(context);
                              },
                        icon: const Icon(Icons.shopping_cart_outlined),
                        label: const Text('Añadir'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final isNew = _isNew(p);

    return MouseRegion(
      onEnter: (_) {
        if (_isDesktopHover) setState(() => _hover = true);
      },
      onExit: (_) {
        if (_isDesktopHover) setState(() => _hover = false);
      },
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          // mobile/normal tap -> ficha técnica
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailScreen(product: p),
            ),
          );
        },
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              // ======= CONTENT (tu tarjeta limpia) =======
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // IMAGEN GRANDE
                  Expanded(
                    flex: 60,
                    child: Stack(
                      children: [
                        _ProductImage(
                          url: p.images.isNotEmpty ? p.images.first : null,
                          fit: BoxFit.contain,
                        ),
                        if (isNew)
                          const Positioned(
                            top: 14,
                            left: 14,
                            child: _NewBadge(),
                          ),
                      ],
                    ),
                  ),

                  // INFO
                  Expanded(
                    flex: 40,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 16,
                                color: (p.stock <= 0)
                                    ? Colors.grey
                                    : const Color(0xFF16A34A),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Stock: ${p.stock} disponibles',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: (p.stock <= 0)
                                      ? Colors.grey.shade700
                                      : const Color(0xFF166534),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            'COP ${p.price}',
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // ======= HOVER OVERLAY (2 botones) =======
              if (_isDesktopHover)
                AnimatedOpacity(
                  opacity: _hover ? 1 : 0,
                  duration: const Duration(milliseconds: 140),
                  curve: Curves.easeOut,
                  child: IgnorePointer(
                    ignoring: !_hover,
                    child: Container(
                      color: Colors.black.withOpacity(0.22),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 220),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: (p.stock <= 0)
                                        ? null
                                        : () => _addToCart(context),
                                    icon: const Icon(
                                        Icons.shopping_cart_outlined),
                                    label: const Text('Añadir'),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14),
                                      backgroundColor: const Color(0xFF2563EB),
                                      foregroundColor: Colors.white,
                                      textStyle: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () => _preview(context),
                                    icon: const Icon(Icons.visibility_outlined),
                                    label: const Text('Previsualizar'),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14),
                                      foregroundColor: Colors.white,
                                      side: const BorderSide(
                                          color: Colors.white, width: 1.2),
                                      textStyle: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewBadge extends StatelessWidget {
  const _NewBadge();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF2563EB),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Text(
          'Nuevo',
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  final String? url;
  final BoxFit fit;

  const _ProductImage({this.url, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return Container(
        color: Colors.white,
        alignment: Alignment.center,
        child:
            const Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
      );
    }

    return Image.network(
      url!,
      fit: fit,
      alignment: Alignment.center,
      loadingBuilder: (_, child, progress) {
        if (progress == null) return child;
        return const Center(child: CircularProgressIndicator(strokeWidth: 2));
      },
      errorBuilder: (_, __, ___) => const Center(
        child: Icon(Icons.broken_image, size: 48),
      ),
    );
  }
}
