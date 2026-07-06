
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

  /// compact = ideal para carruseles horizontales
  /// compact = false para grid principal
  final bool compact;

  const ProductCard({
    super.key,
    required this.product,
    this.compact = false,
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
      {
        TargetPlatform.macOS,
        TargetPlatform.windows,
        TargetPlatform.linux,
      }.contains(Theme.of(context).platform);

  Future<void> _addToCart(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final cart = context.read<CartProvider>();

    final token = auth.token;
    final role = auth.role;
    final appliedPrice = widget.product.price.toInt();

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
// Redirección nativa leyendo el String real desde el documento de Mongoose
  void _openDetail(BuildContext context) {
    final realSlug = widget.product.slug; 
    
    if (realSlug.isNotEmpty) {
      // Inyecta directamente la URL limpia en la raíz de Chrome
      Navigator.pushNamed(
        context,
        '/$realSlug',
      );
    } else {
      // Si no existe, no navegamos a una ruta inventada, reportamos el log técnico para corregir el producto
      debugPrint("Error: El producto con ID ${widget.product.id} no posee la propiedad 'slug' migrada en el backend.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este producto está en mantenimiento de indexación.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _preview(BuildContext context) {
    final p = widget.product;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AspectRatio(
                    aspectRatio: 16 / 10,
                    child: _ProductImage(
                      url: p.images.isNotEmpty ? p.images.first : null,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  p.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 10),
                _StockRow(stock: p.stock),
                const SizedBox(height: 12),
                Text(
                  _formatCop(p.price),
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _openDetail(context);
                        },
                        icon: const Icon(Icons.visibility_outlined),
                        label: const Text('Ver ficha'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
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
                          padding: const EdgeInsets.symmetric(vertical: 13),
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

  static String _formatCop(num value) {
    final raw = value.toStringAsFixed(value % 1 == 0 ? 0 : 2);
    final parts = raw.split('.');
    final intPart = parts[0];
    final decimalPart = parts.length > 1 ? parts[1] : null;

    final buffer = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      final positionFromEnd = intPart.length - i;
      buffer.write(intPart[i]);
      if (positionFromEnd > 1 && positionFromEnd % 3 == 1) {
        buffer.write('.');
      }
    }

    return decimalPart == null || decimalPart == '00'
        ? 'COP ${buffer.toString()}'
        : 'COP ${buffer.toString()},$decimalPart';
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final isNew = _isNew(p);

    final isCompact = widget.compact;

    final titleFontSize = isCompact ? 16.0 : 18.0;
    final priceFontSize = isCompact ? 22.0 : 26.0;
    final horizontalPadding = isCompact ? 14.0 : 16.0;
    final verticalPadding = isCompact ? 12.0 : 14.0;
    final imageFlex = isCompact ? 56 : 60;
    final infoFlex = isCompact ? 44 : 40;

    return MouseRegion(
      onEnter: (_) {
        if (_isDesktopHover) setState(() => _hover = true);
      },
      onExit: (_) {
        if (_isDesktopHover) setState(() => _hover = false);
      },
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _openDetail(context),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(isCompact ? 20 : 22),
            border: Border.all(
              color: _hover ? const Color(0xFFBFDBFE) : const Color(0xFFF1F5F9),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_hover ? 0.10 : 0.06),
                blurRadius: _hover ? 24 : 16,
                offset: Offset(0, _hover ? 12 : 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: imageFlex,
                    child: Stack(
                      children: [
                        Container(
                          color: const Color(0xFFF8FAFC),
                          child: Padding(
                            padding: EdgeInsets.all(isCompact ? 14 : 18),
                            child: _ProductImage(
                              url: p.images.isNotEmpty ? p.images.first : null,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        if (isNew)
                          Positioned(
                            top: 12,
                            left: 12,
                            child: _NewBadge(compact: isCompact),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: infoFlex,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        verticalPadding,
                        horizontalPadding,
                        isCompact ? 14 : 16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.name,
                            maxLines: isCompact ? 2 : 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: titleFontSize,
                              fontWeight: FontWeight.w800,
                              height: 1.12,
                              color: const Color(0xFF111827),
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _StockRow(stock: p.stock, compact: isCompact),
                          const Spacer(),
                          Text(
                            _formatCop(p.price),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: priceFontSize,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF0F172A),
                              letterSpacing: -0.4,
                              height: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (_isDesktopHover)
                AnimatedOpacity(
                  opacity: _hover ? 1 : 0,
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeOut,
                  child: IgnorePointer(
                    ignoring: !_hover,
                    child: Container(
                      color: Colors.black.withOpacity(0.20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: isCompact ? 190 : 220,
                            ),
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
                                      padding: EdgeInsets.symmetric(
                                        vertical: isCompact ? 12 : 14,
                                      ),
                                      backgroundColor: const Color(0xFF2563EB),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      textStyle: TextStyle(
                                        fontSize: isCompact ? 14 : 16,
                                        fontWeight: FontWeight.w800,
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
                                    label: const Text('Vista rápida'),
                                    style: OutlinedButton.styleFrom(
                                      padding: EdgeInsets.symmetric(
                                        vertical: isCompact ? 12 : 14,
                                      ),
                                      foregroundColor: Colors.white,
                                      side: const BorderSide(
                                        color: Colors.white,
                                        width: 1.2,
                                      ),
                                      textStyle: TextStyle(
                                        fontSize: isCompact ? 14 : 16,
                                        fontWeight: FontWeight.w800,
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

class _StockRow extends StatelessWidget {
  final int stock;
  final bool compact;

  const _StockRow({
    required this.stock,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final inStock = stock > 0;

    return Row(
      children: [
        Icon(
          inStock ? Icons.check_circle : Icons.remove_circle_outline,
          size: compact ? 15 : 16,
          color: inStock ? const Color(0xFF16A34A) : Colors.grey,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'Stock: $stock disponibles',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: compact ? 12.5 : 13,
              color: inStock ? const Color(0xFF166534) : Colors.grey.shade700,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _NewBadge extends StatelessWidget {
  final bool compact;

  const _NewBadge({this.compact = false});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF2563EB),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.14),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 14,
          vertical: compact ? 6 : 8,
        ),
        child: Text(
          'Nuevo',
          style: TextStyle(
            color: Colors.white,
            fontSize: compact ? 11.5 : 13,
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

  const _ProductImage({
    this.url,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return Container(
        color: Colors.white,
        alignment: Alignment.center,
        child: const Icon(
          Icons.image_not_supported_outlined,
          size: 42,
          color: Colors.grey,
        ),
      );
    }

    return Image.network(
      url!,
      fit: fit,
      alignment: Alignment.center,
      loadingBuilder: (_, child, progress) {
        if (progress == null) return child;
        return const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      },
      errorBuilder: (_, __, ___) => const Center(
        child: Icon(Icons.broken_image_outlined, size: 42, color: Colors.grey),
      ),
    );
  }
}
