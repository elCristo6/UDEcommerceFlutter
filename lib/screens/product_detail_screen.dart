
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product_model.dart';
import '../models/product_pdp_model.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/product_provider.dart';
import '../widgets/search_bar.dart' as custom;

class ProductDetailScreen extends StatefulWidget {
  final Product? product;        // Opcional para mantener compatibilidad interna
  final String? productSlug;     // Captura el slug limpio de la barra de navegación web

  const ProductDetailScreen({super.key, this.product, this.productSlug});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int selectedImageIndex = 0;
  bool _adding = false;
  int _qty = 1;

@override
  void initState() {
    super.initState();
    // Carga de forma asíncrona la información enriquecida real del backend
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ProductProvider>();
      
      if (widget.productSlug != null) {
        // Flujo directo desde la URL indexada (Google / Sitemap)
        provider.fetchProductDetailBySlug(widget.productSlug!);
      } else if (widget.product != null) {
        // Obtenemos EXCLUSIVAMENTE el slug puro almacenado en el documento de MongoDB
        final realSlug = widget.product!.slug;
        
        if (realSlug.isNotEmpty) {
          provider.fetchProductDetailBySlug(realSlug);
        } else {
          // Si el producto no tiene slug real en la base de datos, mostramos un error controlado
          debugPrint("Alerta crítica: El producto '${widget.product!.name}' no cuenta con un campo slug en base de datos.");
        }
      }
    });
  }




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

  // Mapea la información del modelo unificado hacia el formato plano del CartProvider
  Future<void> _addToCart({
    required ProductPdpData pdpData,
    required String token,
    required String? role,
  }) async {
    final availableStock = pdpData.stockManagement.availableQuantity;
    if (availableStock <= 0) return;
    if (_qty <= 0) return;

    final safeQty = _qty > availableStock ? availableStock : _qty;

    setState(() => _adding = true);
    final cart = context.read<CartProvider>();

    // Adaptador intermedio para no romper el flujo tradicional del carrito
    final legacyProductAdapter = Product(
      id: pdpData.id,
      name: pdpData.name,
      price: pdpData.pricing.currentPrice,
      description: pdpData.details.description,
      box: pdpData.details.box,
      images: pdpData.media.gallery,
      stock: availableStock,
      category: pdpData.details.categoryText.isNotEmpty ? pdpData.details.categoryText : 'Unknown',
    );

    await cart.addProduct(
      legacyProductAdapter,
      quantity: safeQty,
      token: token,
      role: role,
      appliedPrice: pdpData.pricing.currentPrice.toInt(),
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
    final auth = context.watch<AuthProvider>();
    final token = auth.token ?? '';
    final role = auth.role;
    final isDesktop = MediaQuery.of(context).size.width >= 1100;

    return Scaffold(
      appBar: custom.SearchBar(
        onSubmitted: (query) {
          Navigator.pushNamed(context, '/infoProducts', arguments: query);
        },
      ),
      body: Consumer<ProductProvider>(
        builder: (context, productProvider, child) {
          // 1. Loader Premium mientras el servidor responde
          if (productProvider.isLoadingPdp) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 14),
                  Text('Leyendo especificaciones técnicas...', style: TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            );
          }

          // 2. Control de Rutas inexistentes para Googlebot
          if (productProvider.currentPdpProduct == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  'El componente solicitado no se encuentra disponible.',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            );
          }

          final p = productProvider.currentPdpProduct!;
          final availableStock = p.stockManagement.availableQuantity;
          final inStock = availableStock > 0;

          final images = p.media.gallery.where((e) => e.trim().isNotEmpty).toList();
          final hasImages = images.isNotEmpty;

          final maxQty = availableStock <= 0 ? 1 : availableStock;
          if (_qty > maxQty) _qty = maxQty;
          if (_qty < 1) _qty = 1;

          return Scaffold(
            // ✅ Sticky bar exclusivo para mobile
            bottomNavigationBar: isDesktop
                ? null
                : _MobileStickyBar(
                    enabled: inStock && !_adding,
                    priceText: 'COP ${_formatCurrency(p.pricing.currentPrice)}',
                    stockText: _stockLabel(availableStock),
                    stockColor: _stockColor(availableStock),
                    onAdd: () => _addToCart(pdpData: p, token: token, role: role),
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
                            // TOP: Breadcrumb
                            // =========================
                            _Breadcrumb(
                              category: p.details.categoryText.isNotEmpty ? p.details.categoryText : 'Electrónica',
                              title: p.name,
                            ),
                            const SizedBox(height: 14),

                            // =========================
                            // HERO AREA (Distribución de Paneles Premium)
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
                                      onSelect: (i) => setState(() => selectedImageIndex = i),
                                    ),
                                  ),
                                  const SizedBox(width: 18),
                                  Expanded(
                                    flex: 4,
                                    child: _InfoPanel(
                                      productName: p.name,
                                      category: p.details.categoryText.isNotEmpty ? p.details.categoryText : 'Componente',
                                      badge: p.marketingTriggers.badge,
                                      viewers: p.marketingTriggers.viewersRightNow,
                                      salesCount: p.marketingTriggers.totalSalesCount,
                                      priceText: 'COP ${_formatCurrency(p.pricing.currentPrice)}',
                                      originalPriceText: 'COP ${_formatCurrency(p.pricing.originalPrice)}',
                                      discountPercent: p.pricing.discountPercentage,
                                      stockText: _stockLabel(availableStock),
                                      stockColor: _stockColor(availableStock),
                                    ),
                                  ),
                                  const SizedBox(width: 18),
                                  SizedBox(
                                    width: 360,
                                    child: _BuyBox(
                                      enabled: inStock && !_adding,
                                      priceText: 'COP ${_formatCurrency(p.pricing.currentPrice)}',
                                      stockText: _stockLabel(availableStock),
                                      stockColor: _stockColor(availableStock),
                                      qty: _qty,
                                      maxQty: maxQty,
                                      onQtyChanged: (v) => setState(() => _qty = v),
                                      adding: _adding,
                                      onAdd: () => _addToCart(pdpData: p, token: token, role: role),
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
                                    onSelect: (i) => setState(() => selectedImageIndex = i),
                                  ),
                                  const SizedBox(height: 14),
                                  _InfoPanel(
                                    productName: p.name,
                                    category: p.details.categoryText.isNotEmpty ? p.details.categoryText : 'Componente',
                                    badge: p.marketingTriggers.badge,
                                    viewers: p.marketingTriggers.viewersRightNow,
                                    salesCount: p.marketingTriggers.totalSalesCount,
                                    priceText: 'COP ${_formatCurrency(p.pricing.currentPrice)}',
                                    originalPriceText: 'COP ${_formatCurrency(p.pricing.originalPrice)}',
                                    discountPercent: p.pricing.discountPercentage,
                                    stockText: _stockLabel(availableStock),
                                    stockColor: _stockColor(availableStock),
                                  ),
                                  const SizedBox(height: 14),
                                  _BuyBox(
                                    enabled: inStock && !_adding,
                                    priceText: 'COP ${_formatCurrency(p.pricing.currentPrice)}',
                                    stockText: _stockLabel(availableStock),
                                    stockColor: _stockColor(availableStock),
                                    qty: _qty,
                                    maxQty: maxQty,
                                    onQtyChanged: (v) => setState(() => _qty = v),
                                    adding: _adding,
                                    onAdd: () => _addToCart(pdpData: p, token: token, role: role),
                                    onBuy: inStock ? () {} : null,
                                  ),
                                ],
                              ),

                            const SizedBox(height: 24),
                            _BenefitsStrip(isDesktop: isDesktop),
                            const SizedBox(height: 24),

                            // =========================
                            // SECCIÓN DE DETALLES (Descripción + Specs)
                            // =========================
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 7,
                                  child: _SectionCard(
                                    title: 'Descripción',
                                    child: Text(
                                      p.details.description.isNotEmpty ? p.details.description : 'Sin descripción disponible.',
                                      style: const TextStyle(fontSize: 15.5, height: 1.7),
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
                                        category: p.details.categoryText.isNotEmpty ? p.details.categoryText : 'Módulo',
                                        stock: availableStock,
                                        boxCount: p.details.box.length,
                                        productId: p.id,
                                        deliveryText: p.shippingLogistics.estimatedDeliveryText,
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
                                  category: p.details.categoryText.isNotEmpty ? p.details.categoryText : 'Módulo',
                                  stock: availableStock,
                                  boxCount: p.details.box.length,
                                  productId: p.id,
                                  deliveryText: p.shippingLogistics.estimatedDeliveryText,
                                ),
                              ),
                            ],

                            const SizedBox(height: 24),

                            // =========================
                            // CARRETES DE IMÁGENES COMPLETAS
                            // =========================
                            _SectionCard(
                              title: 'Imágenes del producto',
                              child: Column(
                                children: hasImages
                                    ? images
                                        .map(
                                          (img) => Padding(
                                            padding: const EdgeInsets.only(bottom: 18),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(14),
                                              child: AspectRatio(
                                                aspectRatio: 16 / 9,
                                                child: Image.network(
                                                  img,
                                                  fit: BoxFit.contain,
                                                  errorBuilder: (_, __, ___) => const Center(
                                                    child: Icon(Icons.broken_image, size: 60),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList()
                                    : [
                                        const Padding(
                                          padding: EdgeInsets.symmetric(vertical: 16),
                                          child: Text('Este producto no tiene imágenes adicionales.'),
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
        },
      ),
    );
  }
}

/// ============================================================================
/// COMPONENTES UI ESTRUCTURALES ORIGINALES CON ADAPTACIONES CRO
/// ============================================================================

class _Breadcrumb extends StatelessWidget {
  final String category;
  final String title;

  const _Breadcrumb({required this.category, required this.title});

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
          child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: muted),
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
                                ? Image.network(thumb, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image)))
                                : Container(color: Colors.black12, child: const Icon(Icons.image, size: 26)),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 14),
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
                            ? Image.network(images[selectedIndex], fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image, size: 70)))
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
                            color: i == selectedIndex ? Colors.blue : Colors.black26,
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
  final String badge;
  final int viewers;
  final int salesCount;
  final String priceText;
  final String originalPriceText;
  final int discountPercent;
  final String stockText;
  final Color stockColor;

  const _InfoPanel({
    required this.productName,
    required this.category,
    required this.badge,
    required this.viewers,
    required this.salesCount,
    required this.priceText,
    required this.originalPriceText,
    required this.discountPercent,
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
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Pill(icon: Icons.category, label: category.isNotEmpty ? category : 'Categoría'),
                _Pill(icon: Icons.verified, label: 'Compra segura'),
                if (badge.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: Colors.amber[700], borderRadius: BorderRadius.circular(999)),
                    child: Text(badge, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(productName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, height: 1.2)),
            const SizedBox(height: 10),

            // ✅ SOLUCIÓN AL OVERFLOW: Cambiado Row por Wrap con cross alignment centrado
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Icon(Icons.star, size: 18, color: Colors.amber),
                Text('4.9', style: subtitle),
                Text('•', style: subtitle),
                const Icon(Icons.local_fire_department, size: 16, color: Colors.orange),
                Text('$viewers viendo ahora', style: subtitle?.copyWith(color: Colors.orange, fontWeight: FontWeight.bold)),
                Text('•', style: subtitle),
                Text('$salesCount exitosos', style: subtitle),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(priceText, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: -0.4, color: Colors.purple)),
                const SizedBox(width: 10),
                if (discountPercent > 0) ...[
                  Text(originalPriceText, style: subtitle?.copyWith(decoration: TextDecoration.lineThrough, fontSize: 16)),
                  const SizedBox(width: 8),
                  Text('-$discountPercent% OFF', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(color: stockColor, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text(stockText, style: TextStyle(color: stockColor, fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 18),
            Text('Envío rápido en Colombia • Soporte UD Electronics', style: subtitle),
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
            Text(
              'Tu compra',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900) ?? 
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: Text(priceText, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: stockColor.withOpacity(0.12), borderRadius: BorderRadius.circular(999)),
                  child: Text(stockText, style: TextStyle(color: stockColor, fontWeight: FontWeight.w900, fontSize: 12.5)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Text('Cantidad', style: TextStyle(fontWeight: FontWeight.w700)),
                const Spacer(),
                _QtySelector(value: qty, max: maxQty, enabled: enabled, onChanged: onQtyChanged),
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
                style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), textStyle: const TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton.icon(
                onPressed: (!enabled || adding) ? null : onAdd,
                icon: adding ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.add_shopping_cart),
                label: Text(adding ? 'Agregando...' : 'Agregar a la cesta'),
                style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), textStyle: const TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(height: 14),
            const Divider(),
            const SizedBox(height: 10),
            _MiniTrustRow(icon: Icons.lock, text: 'Pago seguro / contraentrega'),
            const SizedBox(height: 8),
            _MiniTrustRow(icon: Icons.local_shipping, text: 'Envíos a todo el país'),
            const SizedBox(height: 8),
            _MiniTrustRow(icon: Icons.support_agent, text: 'Soporte técnico UD Electronics'),
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
        Expanded(child: Text(text, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w600))),
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
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: isDesktop ? 14 : 12),
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
                    decoration: BoxDecoration(color: Colors.blue.withOpacity(0.10), borderRadius: BorderRadius.circular(12)),
                    child: Icon(e.$1, color: Colors.blue),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.$2, style: const TextStyle(fontWeight: FontWeight.w900)),
                        const SizedBox(height: 2),
                        Text(e.$3, style: const TextStyle(color: Colors.black54)),
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
  final int boxCount;
  final String productId;
  final String deliveryText;

  const _SpecsList({
    required this.category,
    required this.stock,
    required this.boxCount,
    required this.productId,
    required this.deliveryText,
  });

  @override
  Widget build(BuildContext context) {
    final rows = <String, String>{
      'Categoría': category.isNotEmpty ? category : '—',
      'Stock Real': stock.toString(),
      'Componentes en caja': '$boxCount unidades',
      'Logística': deliveryText.isNotEmpty ? deliveryText : 'Despacho inmediato',
      'ID de Catálogo': productId,
    };

    return Column(
      children: rows.entries
          .map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: Text(r.key, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w700))),
                  const SizedBox(width: 10),
                  Expanded(child: Text(r.value, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w800))),
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
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 18, offset: const Offset(0, 10))],
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
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.04), borderRadius: BorderRadius.circular(999), border: Border.all(color: Colors.black12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.black54),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
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

  const _QtySelector({required this.value, required this.max, required this.enabled, required this.onChanged});

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
          decoration: BoxDecoration(color: onTap != null ? Colors.black.withOpacity(0.04) : Colors.black12, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black12)),
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
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black12)),
          child: Text(value.toString(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
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

  const _MobileStickyBar({required this.enabled, required this.priceText, required this.stockText, required this.stockColor, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.black.withOpacity(0.08))),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 18, offset: const Offset(0, -6))],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(priceText, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  const SizedBox(height: 2),
                  Text(stockText, style: TextStyle(color: stockColor, fontWeight: FontWeight.w900, fontSize: 12.5)),
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
                style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), textStyle: const TextStyle(fontWeight: FontWeight.w900)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}