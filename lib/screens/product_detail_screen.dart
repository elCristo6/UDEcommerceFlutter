import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product_model.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../widgets/search_bar.dart' as custom;

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int selectedImageIndex = 0;
  bool _adding = false;
  int _qty = 1;

  String _formatCurrency(num value) {
    final s = value.toStringAsFixed(0);
    return s.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }

  Color _stockColor(int stock) {
    if (stock <= 0) return Colors.redAccent;
    if (stock <= 5) return Colors.orange;
    return Colors.green;
  }

  String _stockLabel(int stock) {
    if (stock <= 0) return 'Sin stock';
    if (stock <= 5) return 'Pocas unidades';
    return 'Disponible';
  }

  Future<void> _addToCart({
    required Product product,
    required String token,
    required String? role,
  }) async {
    if (product.stock <= 0) return;
    if (_qty <= 0) return;

    // Seguridad por stock
    final safeQty = _qty > product.stock ? product.stock : _qty;

    setState(() => _adding = true);
    final cart = context.read<CartProvider>();

    await cart.addProduct(
      product,
      quantity: safeQty,
      token: token,
      role: role,
      appliedPrice: product.price.toInt(),
    );

    cart.sanitizeSelection();
    setState(() => _adding = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Agregado a la cesta (x$safeQty)'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    final auth = context.watch<AuthProvider>();
    final token = auth.token ?? '';
    final role = auth.role;

    final inStock = product.stock > 0;
    final isDesktop = MediaQuery.of(context).size.width >= 1100;

    final images = product.images.where((e) => e.trim().isNotEmpty).toList();
    final hasImages = images.isNotEmpty;

    final maxQty = product.stock <= 0 ? 1 : product.stock;
    if (_qty > maxQty) _qty = maxQty;
    if (_qty < 1) _qty = 1;

    return Scaffold(
      appBar: custom.SearchBar(
        onSubmitted: (query) {
          Navigator.pushNamed(context, '/infoProducts', arguments: query);
        },
      ),

      // ✅ Sticky bar solo en mobile
      bottomNavigationBar: isDesktop
          ? null
          : _MobileStickyBar(
              enabled: inStock && !_adding,
              priceText: 'COP ${_formatCurrency(product.price)}',
              stockText: _stockLabel(product.stock),
              stockColor: _stockColor(product.stock),
              onAdd: () =>
                  _addToCart(product: product, token: token, role: role),
            ),

      body: LayoutBuilder(
        builder: (context, c) {
          return SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1280),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 24 : 14,
                    vertical: 18,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // =========================
                      // TOP: Breadcrumb + Header
                      // =========================
                      _Breadcrumb(
                        category: product.category,
                        title: product.name,
                      ),
                      const SizedBox(height: 14),

                      // =========================
                      // HERO AREA (Premium)
                      // Desktop: Gallery | Info | BuyBox
                      // Mobile: Gallery + Info + BuyBox inline
                      // =========================
                      if (isDesktop)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 6,
                              child: _GalleryPanel(
                                images: images,
                                hasImages: hasImages,
                                selectedIndex: selectedImageIndex,
                                onSelect: (i) =>
                                    setState(() => selectedImageIndex = i),
                              ),
                            ),
                            const SizedBox(width: 18),
                            Expanded(
                              flex: 4,
                              child: _InfoPanel(
                                productName: product.name,
                                category: product.category,
                                updatedAt: product.updatedAt,
                                priceText:
                                    'COP ${_formatCurrency(product.price)}',
                                stockText: _stockLabel(product.stock),
                                stockColor: _stockColor(product.stock),
                              ),
                            ),
                            const SizedBox(width: 18),
                            SizedBox(
                              width: 360,
                              child: _BuyBox(
                                enabled: inStock && !_adding,
                                priceText:
                                    'COP ${_formatCurrency(product.price)}',
                                stockText: _stockLabel(product.stock),
                                stockColor: _stockColor(product.stock),
                                qty: _qty,
                                maxQty: maxQty,
                                onQtyChanged: (v) => setState(() => _qty = v),
                                adding: _adding,
                                onAdd: () => _addToCart(
                                  product: product,
                                  token: token,
                                  role: role,
                                ),
                                onBuy: inStock ? () {} : null,
                              ),
                            ),
                          ],
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _GalleryPanel(
                              images: images,
                              hasImages: hasImages,
                              selectedIndex: selectedImageIndex,
                              onSelect: (i) =>
                                  setState(() => selectedImageIndex = i),
                            ),
                            const SizedBox(height: 14),
                            _InfoPanel(
                              productName: product.name,
                              category: product.category,
                              updatedAt: product.updatedAt,
                              priceText:
                                  'COP ${_formatCurrency(product.price)}',
                              stockText: _stockLabel(product.stock),
                              stockColor: _stockColor(product.stock),
                            ),
                            const SizedBox(height: 14),
                            _BuyBox(
                              enabled: inStock && !_adding,
                              priceText:
                                  'COP ${_formatCurrency(product.price)}',
                              stockText: _stockLabel(product.stock),
                              stockColor: _stockColor(product.stock),
                              qty: _qty,
                              maxQty: maxQty,
                              onQtyChanged: (v) => setState(() => _qty = v),
                              adding: _adding,
                              onAdd: () => _addToCart(
                                product: product,
                                token: token,
                                role: role,
                              ),
                              onBuy: inStock ? () {} : null,
                            ),
                          ],
                        ),

                      const SizedBox(height: 24),

                      // =========================
                      // TRUST / BENEFITS STRIP
                      // =========================
                      _BenefitsStrip(isDesktop: isDesktop),
                      const SizedBox(height: 24),

                      // =========================
                      // DETAILS SECTION (Descripción + Specs)
                      // =========================
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 7,
                            child: _SectionCard(
                              title: 'Descripción',
                              child: Text(
                                product.description.isNotEmpty
                                    ? product.description
                                    : 'Sin descripción disponible.',
                                style: const TextStyle(
                                    fontSize: 15.5, height: 1.7),
                              ),
                            ),
                          ),
                          if (isDesktop) ...[
                            const SizedBox(width: 18),
                            Expanded(
                              flex: 5,
                              child: _SectionCard(
                                title: 'Especificaciones',
                                child: _SpecsList(
                                  category: product.category,
                                  stock: product.stock,
                                  updatedAt: product.updatedAt,
                                  boxCount: product.box.length,
                                  productId: product.id,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),

                      if (!isDesktop) ...[
                        const SizedBox(height: 18),
                        _SectionCard(
                          title: 'Especificaciones',
                          child: _SpecsList(
                            category: product.category,
                            stock: product.stock,
                            updatedAt: product.updatedAt,
                            boxCount: product.box.length,
                            productId: product.id,
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // =========================
                      // FULL IMAGES (like your screenshot)
                      // =========================
                      _SectionCard(
                        title: 'Imágenes del producto',
                        child: Column(
                          children: hasImages
                              ? images
                                  .map(
                                    (img) => Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 18),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(14),
                                        child: AspectRatio(
                                          aspectRatio: 16 / 9,
                                          child: Image.network(
                                            img,
                                            fit: BoxFit.contain,
                                            errorBuilder: (_, __, ___) =>
                                                const Center(
                                                    child: Icon(
                                                        Icons.broken_image,
                                                        size: 60)),
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList()
                              : [
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    child: Text(
                                        'Este producto no tiene imágenes.'),
                                  )
                                ],
                        ),
                      ),

                      const SizedBox(height: 26),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// ============================
/// COMPONENTES UI (Premium)
/// ============================

class _Breadcrumb extends StatelessWidget {
  final String category;
  final String title;

  const _Breadcrumb({
    required this.category,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Colors.black54,
          fontSize: 12.5,
        );

    return Row(
      children: [
        Text('Inicio', style: muted),
        const SizedBox(width: 6),
        const Icon(Icons.chevron_right, size: 16, color: Colors.black45),
        const SizedBox(width: 6),
        Text(category.isNotEmpty ? category : 'Categoría', style: muted),
        const SizedBox(width: 6),
        const Icon(Icons.chevron_right, size: 16, color: Colors.black45),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: muted,
          ),
        ),
      ],
    );
  }
}

class _GalleryPanel extends StatelessWidget {
  final List<String> images;
  final bool hasImages;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const _GalleryPanel({
    required this.images,
    required this.hasImages,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbs
            SizedBox(
              width: 86,
              child: Column(
                children: List.generate(
                  hasImages ? images.length : 1,
                  (i) {
                    final active = i == selectedIndex;
                    final thumb = hasImages ? images[i] : '';
                    return GestureDetector(
                      onTap: hasImages ? () => onSelect(i) : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: active ? Colors.blue : Colors.black12,
                            width: active ? 2 : 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: hasImages
                                ? Image.network(
                                    thumb,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Center(
                                      child: Icon(Icons.broken_image),
                                    ),
                                  )
                                : Container(
                                    color: Colors.black12,
                                    child: const Icon(Icons.image, size: 26),
                                  ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Main image
            Expanded(
              child: Column(
                children: [
                  AspectRatio(
                    aspectRatio: 1,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        color: Colors.white,
                        child: hasImages
                            ? Image.network(
                                images[selectedIndex],
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Center(
                                  child: Icon(Icons.broken_image, size: 70),
                                ),
                              )
                            : const Center(child: Icon(Icons.image, size: 70)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (hasImages)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        images.length,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          width: i == selectedIndex ? 18 : 7,
                          height: 7,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: i == selectedIndex
                                ? Colors.blue
                                : Colors.black26,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  final String productName;
  final String category;
  final DateTime? updatedAt;
  final String priceText;
  final String stockText;
  final Color stockColor;

  const _InfoPanel({
    required this.productName,
    required this.category,
    required this.updatedAt,
    required this.priceText,
    required this.stockText,
    required this.stockColor,
  });

  @override
  Widget build(BuildContext context) {
    final subtitle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Colors.black54,
          height: 1.4,
        );

    return _GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category chip
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Pill(
                  icon: Icons.category,
                  label: category.isNotEmpty ? category : 'Categoría',
                ),
                _Pill(
                  icon: Icons.verified,
                  label: 'Compra segura',
                ),
              ],
            ),
            const SizedBox(height: 12),

            Text(
              productName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                const Icon(Icons.star, size: 18, color: Colors.amber),
                const SizedBox(width: 6),
                Text('4.9', style: subtitle),
                const SizedBox(width: 8),
                Text('•', style: subtitle),
                const SizedBox(width: 8),
                Text('Top ventas', style: subtitle),
              ],
            ),

            const SizedBox(height: 16),

            Text(
              priceText,
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.4,
              ),
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: stockColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  stockText,
                  style: TextStyle(
                    color: stockColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Text(
              updatedAt != null
                  ? 'Actualizado: ${updatedAt!.toLocal().toString().split(".").first}'
                  : 'Actualizado recientemente',
              style: subtitle,
            ),

            const SizedBox(height: 18),

            // Micro-copy
            Text(
              'Envío rápido en Colombia • Soporte UD Electronics',
              style: subtitle,
            ),
          ],
        ),
      ),
    );
  }
}

class _BuyBox extends StatelessWidget {
  final bool enabled;
  final String priceText;
  final String stockText;
  final Color stockColor;

  final int qty;
  final int maxQty;
  final ValueChanged<int> onQtyChanged;

  final bool adding;
  final VoidCallback onAdd;
  final VoidCallback? onBuy;

  const _BuyBox({
    required this.enabled,
    required this.priceText,
    required this.stockText,
    required this.stockColor,
    required this.qty,
    required this.maxQty,
    required this.onQtyChanged,
    required this.adding,
    required this.onAdd,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tu compra',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: Text(
                    priceText,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w900),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: stockColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    stockText,
                    style: TextStyle(
                      color: stockColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Qty selector premium
            Row(
              children: [
                const Text('Cantidad',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                const Spacer(),
                _QtySelector(
                  value: qty,
                  max: maxQty,
                  enabled: enabled,
                  onChanged: onQtyChanged,
                ),
              ],
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: enabled ? onBuy : null,
                icon: const Icon(Icons.flash_on),
                label: const Text('Comprar ahora'),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  textStyle: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton.icon(
                onPressed: (!enabled || adding) ? null : onAdd,
                icon: adding
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_shopping_cart),
                label: Text(adding ? 'Agregando...' : 'Agregar a la cesta'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  textStyle: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),

            const SizedBox(height: 14),

            const Divider(),

            const SizedBox(height: 10),

            _MiniTrustRow(
                icon: Icons.lock, text: 'Pago seguro / contraentrega'),
            const SizedBox(height: 8),
            _MiniTrustRow(
                icon: Icons.local_shipping, text: 'Envíos a todo el país'),
            const SizedBox(height: 8),
            _MiniTrustRow(
                icon: Icons.support_agent,
                text: 'Soporte técnico UD Electronics'),
          ],
        ),
      ),
    );
  }
}

class _MiniTrustRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MiniTrustRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.black54),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
                color: Colors.black54, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _BenefitsStrip extends StatelessWidget {
  final bool isDesktop;

  const _BenefitsStrip({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    final items = const [
      (Icons.verified_user, 'Garantía', 'Respaldo en tienda'),
      (Icons.inventory_2, 'Stock real', 'Actualizado en sistema'),
      (Icons.handshake, 'Soporte', 'Te asesoramos en tu compra'),
      (Icons.local_shipping, 'Envío', 'A toda Colombia'),
    ];

    return _GlassCard(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 14,
          vertical: isDesktop ? 14 : 12,
        ),
        child: Wrap(
          spacing: 14,
          runSpacing: 12,
          children: items.map((e) {
            return SizedBox(
              width: isDesktop ? 280 : double.infinity,
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(e.$1, color: Colors.blue),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.$2,
                            style:
                                const TextStyle(fontWeight: FontWeight.w900)),
                        const SizedBox(height: 2),
                        Text(e.$3,
                            style: const TextStyle(color: Colors.black54)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _SpecsList extends StatelessWidget {
  final String category;
  final int stock;
  final DateTime? updatedAt;
  final int boxCount;
  final String productId;

  const _SpecsList({
    required this.category,
    required this.stock,
    required this.updatedAt,
    required this.boxCount,
    required this.productId,
  });

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String)>[
      ('Categoría', category.isNotEmpty ? category : '—'),
      ('Stock', stock.toString()),
      ('Componentes en caja', boxCount.toString()),
      ('ID', productId),
      (
        'Actualización',
        updatedAt != null
            ? updatedAt!.toLocal().toString().split('.').first
            : '—'
      ),
    ];

    return Column(
      children: rows
          .map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      r.$1,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      r.$2,
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;

  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Pill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.04),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.black54),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _QtySelector extends StatelessWidget {
  final int value;
  final int max;
  final bool enabled;
  final ValueChanged<int> onChanged;

  const _QtySelector({
    required this.value,
    required this.max,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final canDec = enabled && value > 1;
    final canInc = enabled && value < max;

    Widget btn(IconData icon, VoidCallback? onTap) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color:
                onTap != null ? Colors.black.withOpacity(0.04) : Colors.black12,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black12),
          ),
          child: Icon(icon, size: 18, color: Colors.black87),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        btn(Icons.remove, canDec ? () => onChanged(value - 1) : null),
        const SizedBox(width: 10),
        Container(
          width: 56,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black12),
          ),
          child: Text(
            value.toString(),
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
          ),
        ),
        const SizedBox(width: 10),
        btn(Icons.add, canInc ? () => onChanged(value + 1) : null),
      ],
    );
  }
}

class _MobileStickyBar extends StatelessWidget {
  final bool enabled;
  final String priceText;
  final String stockText;
  final Color stockColor;
  final VoidCallback onAdd;

  const _MobileStickyBar({
    required this.enabled,
    required this.priceText,
    required this.stockText,
    required this.stockColor,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border:
              Border(top: BorderSide(color: Colors.black.withOpacity(0.08))),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 18,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(priceText,
                      style: const TextStyle(
                          fontWeight: FontWeight.w900, fontSize: 16)),
                  const SizedBox(height: 2),
                  Text(
                    stockText,
                    style: TextStyle(
                        color: stockColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 12.5),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              height: 44,
              child: ElevatedButton.icon(
                onPressed: enabled ? onAdd : null,
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text('Agregar'),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  textStyle: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
