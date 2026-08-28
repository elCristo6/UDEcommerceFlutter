
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product_model.dart';
import '../providers/product_provider.dart';
import '../widgets/search_bar.dart' as custom;
import '../providers/auth_provider.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  String selectedView = 'lowStock';
  String searchQuery = '';

  static const Color _darkText = Color(0xFF0F172A);
  static const Color _mutedText = Color(0xFF64748B);
  static const Color _panelBorder = Color(0xFFE2E8F0);

  @override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Si no es un administrador autenticado y válido (o el token venció), se saca inmediatamente
    if (!authProvider.isAdmin) {
      Navigator.pushReplacementNamed(context, '/infoProducts');
    }
  });
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: custom.SearchBar(
        onSubmitted: (query) {
          context.read<ProductProvider>().filterProducts(query);
          Navigator.pushNamed(
            context,
            '/infoProducts',
            arguments: query,
          );
        },
      ),
      body: Consumer<ProductProvider>(
        builder: (context, provider, child) {
          final products = _applySearch(_getProductsByView(provider));

          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFF8FAFF),
                  Color(0xFFF1F5FF),
                  Color(0xFFEFF6FF),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: RefreshIndicator(
              onRefresh: provider.fetchInventoryDashboard,
              color: const Color(0xFF00B8D9),
              backgroundColor: Colors.white,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  _header(),
                  const SizedBox(height: 24),
                  _dashboardCards(provider),
                  const SizedBox(height: 22),
                  _searchBox(),
                  const SizedBox(height: 16),
                  _viewSelector(),
                  const SizedBox(height: 24),
                  if (_isLoading(provider))
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(48),
                        child: CircularProgressIndicator(
                          color: Color(0xFF00B8D9),
                        ),
                      ),
                    )
                  else if (products.isEmpty)
                    _emptyState()
                  else
                    ...products.map(_productCard),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF00E5FF),
                Color(0xFF7C3AED),
              ],
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00E5FF).withOpacity(0.35),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: const Icon(
            Icons.auto_graph_rounded,
            color: Colors.white,
            size: 34,
          ),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Inventario Inteligente',
                style: TextStyle(
                  color: _darkText,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.3,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Control visual de stock, rotación y productos críticos',
                style: TextStyle(
                  color: _mutedText,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _dashboardCards(ProductProvider provider) {
    final totalProducts = provider.products.length;
    final noStock = provider.products.where((p) => p.stock <= 0).length;
    final lowStock =
        provider.products.where((p) => p.stock > 0 && p.stock <= 5).length;
    final totalUnits =
        provider.products.fold<int>(0, (sum, p) => sum + p.stock);

    return Wrap(
      spacing: 14,
      runSpacing: 14,
      children: [
        _summaryCard(
          'Productos',
          totalProducts.toString(),
          Icons.inventory_2_rounded,
          const Color(0xFF0284C7),
        ),
        _summaryCard(
          'Agotados',
          noStock.toString(),
          Icons.error_outline_rounded,
          const Color(0xFFE11D48),
        ),
        _summaryCard(
          'Stock crítico',
          lowStock.toString(),
          Icons.warning_amber_rounded,
          const Color(0xFFF59E0B),
        ),
        _summaryCard(
          'Unidades',
          totalUnits.toString(),
          Icons.warehouse_rounded,
          const Color(0xFF16A34A),
        ),
      ],
    );
  }

  Widget _summaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: 245,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.96),
                Colors.white.withOpacity(0.78),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.withOpacity(0.20)),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.18),
                blurRadius: 26,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.045),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: _mutedText,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      color: color,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _searchBox() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 700),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.95),
            Colors.white.withOpacity(0.78),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _panelBorder),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00B8D9).withOpacity(0.09),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: TextField(
        onChanged: (value) {
          setState(() => searchQuery = value);
        },
        style: const TextStyle(
          color: _darkText,
          fontWeight: FontWeight.w600,
        ),
        cursorColor: const Color(0xFF00B8D9),
        decoration: InputDecoration(
          hintText: 'Buscar producto, categoría o ID...',
          hintStyle: TextStyle(color: _mutedText.withOpacity(0.75)),
          prefixIcon: const Icon(
            Icons.search,
            color: Color(0xFF00B8D9),
          ),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
                  onPressed: () => setState(() => searchQuery = ''),
                  icon: const Icon(
                    Icons.close,
                    color: _mutedText,
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _viewSelector() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _filterButton('lowStock', 'Stock crítico', Icons.bolt_rounded),
        _filterButton('leastStock', 'Menor stock', Icons.trending_down),
        _filterButton('highStock', 'Mayor stock', Icons.trending_up),
        _filterButton(
            'topSelling', 'Más vendidos', Icons.local_fire_department),
        _filterButton('leastSelling', 'Menos vendidos', Icons.hourglass_empty),
        _filterButton('newArrivals', 'Nuevos', Icons.new_releases_outlined),
        _filterButton('all', 'Todos', Icons.grid_view_rounded),
      ],
    );
  }

  Widget _filterButton(String value, String label, IconData icon) {
    final isSelected = selectedView == value;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        gradient: isSelected
            ? const LinearGradient(
                colors: [
                  Color(0xFF00CFFF),
                  Color(0xFF7C3AED),
                ],
              )
            : LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.95),
                  Colors.white.withOpacity(0.78),
                ],
              ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isSelected
              ? const Color(0xFF00E5FF).withOpacity(0.55)
              : _panelBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? const Color(0xFF00E5FF).withOpacity(0.25)
                : Colors.black.withOpacity(0.045),
            blurRadius: isSelected ? 20 : 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => setState(() => selectedView = value),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : const Color(0xFF475569),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF334155),
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                  fontSize: 14.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Product> _applySearch(List<Product> products) {
    if (searchQuery.trim().isEmpty) return products;

    final query = searchQuery.toLowerCase().trim();

    return products.where((product) {
      return product.name.toLowerCase().contains(query) ||
          product.category.toLowerCase().contains(query) ||
          product.id.toLowerCase().contains(query);
    }).toList();
  }

  List<Product> _getProductsByView(ProductProvider provider) {
    switch (selectedView) {
      case 'lowStock':
        return provider.lowStockProducts;
      case 'leastStock':
        return provider.leastStockProducts;
      case 'highStock':
        return provider.highStockProducts;
      case 'topSelling':
        return provider.topSellingProducts;
      case 'leastSelling':
        return provider.leastSellingProducts;
      case 'newArrivals':
        return provider.newArrivalsProducts;
      case 'all':
      default:
        final list = List<Product>.from(provider.products);
        list.sort((a, b) => a.stock.compareTo(b.stock));
        return list;
    }
  }

  bool _isLoading(ProductProvider provider) {
    switch (selectedView) {
      case 'lowStock':
        return provider.isLoadingLowStock;
      case 'leastStock':
        return provider.isLoadingLeastStock;
      case 'highStock':
        return provider.isLoadingHighStock;
      case 'topSelling':
        return provider.isLoadingTopSelling;
      case 'leastSelling':
        return provider.isLoadingLeastSelling;
      case 'newArrivals':
        return provider.isLoadingNewArrivals;
      case 'all':
      default:
        return provider.isLoading;
    }
  }

  Widget _productCard(Product product) {
    final stockColor = _stockColor(product.stock);
    final stockStatus = _stockStatus(product.stock);

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.98),
                Colors.white.withOpacity(0.82),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: stockColor.withOpacity(0.22)),
            boxShadow: [
              BoxShadow(
                color: stockColor.withOpacity(0.10),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.045),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _image(product),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _darkText,
                        fontSize: 17.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _chip(
                          Icons.attach_money,
                          'Precio: \$${product.price.toStringAsFixed(0)}',
                          const Color(0xFF0284C7),
                        ),
                        _chip(
                          Icons.inventory_2_outlined,
                          'Stock: ${product.stock}',
                          stockColor,
                        ),
                        _chip(
                          Icons.warning_amber_rounded,
                          stockStatus,
                          stockColor,
                        ),
                        _chip(
                          Icons.category_outlined,
                          product.category,
                          const Color(0xFF7C3AED),
                        ),
                      ],
                    ),
                    const SizedBox(height: 11),
                    Text(
                      'ID: ${product.id}',
                      style: TextStyle(
                        color: _mutedText.withOpacity(0.80),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: stockColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  product.stock <= 0
                      ? Icons.error_outline_rounded
                      : Icons.insights_rounded,
                  color: stockColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _image(Product product) {
    return Container(
      width: 92,
      height: 92,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _panelBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: product.images.isNotEmpty
            ? Image.network(
                Uri.encodeFull(product.images.first),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _imagePlaceholder(),
              )
            : _imagePlaceholder(),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: const Color(0xFFF1F5F9),
      child: const Icon(
        Icons.image_not_supported_outlined,
        color: Color(0xFF94A3B8),
      ),
    );
  }

  Widget _chip(
    IconData icon,
    String text,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      margin: const EdgeInsets.only(top: 42),
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.95),
            Colors.white.withOpacity(0.78),
          ],
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: _panelBorder),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00B8D9).withOpacity(0.10),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.radar_rounded,
            color: const Color(0xFF00B8D9).withOpacity(0.85),
            size: 74,
          ),
          const SizedBox(height: 16),
          const Text(
            'No hay productos para mostrar',
            style: TextStyle(
              color: _darkText,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Cambia el filtro o verifica que el endpoint esté devolviendo información.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _mutedText,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Color _stockColor(int stock) {
    if (stock <= 0) return const Color(0xFFE11D48);
    if (stock <= 5) return const Color(0xFFF59E0B);
    if (stock <= 15) return const Color(0xFFEAB308);
    return const Color(0xFF16A34A);
  }

  String _stockStatus(int stock) {
    if (stock <= 0) return 'Agotado';
    if (stock <= 5) return 'Stock crítico';
    if (stock <= 15) return 'Stock bajo';
    return 'Disponible';
  }
}
