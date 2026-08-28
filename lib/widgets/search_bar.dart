

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ud_store_flutter_app/main.dart';

import '../models/product_model.dart';
import '../providers/cart_provider.dart';
import '../providers/product_provider.dart';
import 'user_dropdown_menu.dart';
import '../providers/auth_provider.dart';

class SearchBar extends StatelessWidget implements PreferredSizeWidget {
  final String hintText;
  final String initialQuery;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  const SearchBar({
    super.key,
    this.hintText = 'Buscar productos, marcas y más...',
    this.initialQuery = '',
    this.onChanged,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 850;

    return Material(
      color: const Color(0xFF02060D),
      elevation: 0,
      child: isMobile
          ? MobileSearchBar(
              hintText: hintText,
              initialQuery: initialQuery,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
            )
          : SearchBarDesktop(
              hintText: hintText,
              initialQuery: initialQuery,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
            ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(78);
}

/// ============================================================================
/// MÓVIL
/// ============================================================================

class MobileSearchBar extends StatefulWidget implements PreferredSizeWidget {
  final String hintText;
  final String initialQuery;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  const MobileSearchBar({
    super.key,
    this.hintText = 'Buscar productos...',
    this.initialQuery = '',
    this.onChanged,
    this.onSubmitted,
  });

  @override
  State<MobileSearchBar> createState() => _MobileSearchBarState();

  @override
  Size get preferredSize => const Size.fromHeight(76);
}

class _MobileSearchBarState extends State<MobileSearchBar> {
  final FocusNode _mobileFocusNode = FocusNode();
  final TextEditingController _mobileSearchController = TextEditingController();
  OverlayEntry? _mobileOverlayEntry;
  String _currentQuery = '';

  @override
  void initState() {
    super.initState();
    _currentQuery = widget.initialQuery;
    _mobileSearchController.text = widget.initialQuery;
    _mobileSearchController.selection = TextSelection.collapsed(
      offset: _mobileSearchController.text.length,
    );
    _mobileFocusNode.addListener(_handleMobileFocusChange);
  }

  @override
  void didUpdateWidget(covariant MobileSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialQuery != widget.initialQuery) {
      _currentQuery = widget.initialQuery;
      _mobileSearchController.text = widget.initialQuery;
      _mobileSearchController.selection = TextSelection.collapsed(
        offset: _mobileSearchController.text.length,
      );
      if (mounted) setState(() {});
    }
  }

  void _handleMobileFocusChange() {
    if (_mobileFocusNode.hasFocus) {
      if (_currentQuery.trim().isNotEmpty) {
        _showMobileOverlay();
      }
      return;
    }

    Future.delayed(const Duration(milliseconds: 180), () {
      if (!mounted) return;
      _removeMobileOverlay();
    });
  }

  @override
  void dispose() {
    _removeMobileOverlay();
    _mobileFocusNode.removeListener(_handleMobileFocusChange);
    _mobileFocusNode.dispose();
    _mobileSearchController.dispose();
    super.dispose();
  }

  void _handleMobileSearchChanged(String value) {
    setState(() {
      _currentQuery = value;
    });

    context.read<ProductProvider>().filterProducts(value);
    widget.onChanged?.call(value);

    if (value.trim().isEmpty) {
      _removeMobileOverlay();
      return;
    }

    if (_mobileOverlayEntry == null) {
      _showMobileOverlay();
    } else {
      _mobileOverlayEntry?.markNeedsBuild();
    }
  }
  
void _submitMobileSearch(String value) {
  final query = value.trim();
  if (query.isEmpty) return;

  _removeMobileOverlay();
  _mobileFocusNode.unfocus();

  context.read<ProductProvider>().filterProducts(query);
  widget.onSubmitted?.call(query);

  // ✅ Verificación de sesión en tiempo real
  final authProvider = context.read<AuthProvider>();

  if (authProvider.isAuth) {
    // Si SÍ está logueado -> Va a /infoProducts
    navigatorKey.currentState?.pushNamed('/infoProducts', arguments: query);
  } else {
    // Si NO está logueado -> Va a la nueva pantalla pública de búsqueda
    navigatorKey.currentState?.pushNamed('/search', arguments: query);
  }
}

  void _clearMobileSearch() {
    if (_mobileSearchController.text.isEmpty && _currentQuery.isEmpty) return;

    setState(() {
      _currentQuery = '';
    });

    _mobileSearchController.clear();
    context.read<ProductProvider>().clearSearch();
    widget.onChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      color: const Color(0xFF02060D),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            _buildMobileLogo(context),
            const SizedBox(width: 8),
            Expanded(child: _buildMobileSearchInput()),
            const SizedBox(width: 8),
            const UserDropdownMenu(),
            const SizedBox(width: 6),
            _buildMobileCartIcon(context),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLogo(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _removeMobileOverlay();
        _clearMobileSearch();
        Navigator.pushNamed(context, '/home');
      },
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF58C2FF).withOpacity(.55),
              blurRadius: 10,
            ),
          ],
        ),
        child: ClipOval(
          child: Image.asset(
            'assets/UDElectronics.com.png',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Icon(Icons.flash_on, color: Colors.blue),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileSearchInput() {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFF050A13),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF007BFF), width: 1),
      ),
      child: Row(
        children: [
          const SizedBox(width: 10),
          const Icon(Icons.search, color: Color(0xFFB8C2D4), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _mobileSearchController,
              focusNode: _mobileFocusNode,
              onChanged: _handleMobileSearchChanged,
              onSubmitted: _submitMobileSearch,
              textInputAction: TextInputAction.search,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: const TextStyle(color: Color(0xFFB8C2D4), fontSize: 13),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          if (_currentQuery.isNotEmpty)
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
              onPressed: () {
                _removeMobileOverlay();
                _clearMobileSearch();
                _mobileFocusNode.requestFocus();
              },
              icon: const Icon(Icons.close, color: Colors.white70, size: 17),
            ),
        ],
      ),
    );
  }

  Widget _buildMobileCartIcon(BuildContext context) {
    final itemCount = context.watch<CartProvider>().totalItems;

    return GestureDetector(
      onTap: () {
        _removeMobileOverlay();
        _clearMobileSearch();
        Navigator.pushNamed(context, '/cesta');
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 26),
          Positioned(
            right: -7,
            top: -8,
            child: _cartBadge(itemCount, fontSize: 9, padding: 4),
          ),
        ],
      ),
    );
  }

  void _showMobileOverlay() {
    if (_mobileOverlayEntry != null || _currentQuery.trim().isEmpty) return;

    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox) return;

    final size = renderObject.size;
    final offset = renderObject.localToGlobal(Offset.zero);

    _mobileOverlayEntry = OverlayEntry(
      builder: (overlayContext) {
        return Positioned(
          left: 10,
          right: 10,
          top: offset.dy + size.height + 4,
          child: Material(
            color: Colors.transparent,
            elevation: 12,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 310),
              decoration: BoxDecoration(
                color: const Color(0xFF07111F),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF1B3248)),
              ),
              child: Consumer<ProductProvider>(
                builder: (context, provider, child) {
                  if (_currentQuery.trim().isEmpty) return const SizedBox.shrink();

                  final products = provider.filteredProducts;

                  if (provider.isLoading) {
                    return const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (products.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No se encontraron productos.', style: TextStyle(color: Colors.white70)),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return ListTile(
                        leading: _productImage(product.images, size: 42),
                        title: Text(
                          product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        onTap: () => _openMobileProduct(product),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        );
      },
    );

    Overlay.of(context).insert(_mobileOverlayEntry!);
  }

  void _openMobileProduct(Product product) {
    final targetRoute = product.slug.trim().isNotEmpty
        ? '/${product.slug}'
        : '/${_generateSlug(product.name)}';

    _removeMobileOverlay();
    setState(() => _currentQuery = '');
    _mobileSearchController.clear();
    context.read<ProductProvider>().clearSearch();
    _mobileFocusNode.unfocus();

    navigatorKey.currentState?.pushNamed(targetRoute);
  }

  void _removeMobileOverlay() {
    _mobileOverlayEntry?.remove();
    _mobileOverlayEntry = null;
  }
}

/// ============================================================================
/// ESCRITORIO
/// ============================================================================

class SearchBarDesktop extends StatefulWidget implements PreferredSizeWidget {
  final String hintText;
  final String initialQuery;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  const SearchBarDesktop({
    super.key,
    this.hintText = 'Buscar productos, marca y más...',
    this.initialQuery = '',
    this.onChanged,
    this.onSubmitted,
  });

  @override
  State<SearchBarDesktop> createState() => _SearchBarDesktopState();

  @override
  Size get preferredSize => const Size.fromHeight(78);
}

class _SearchBarDesktopState extends State<SearchBarDesktop> {
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey _textFieldKey = GlobalKey();

  OverlayEntry? _overlayEntry;
  bool _hoveringOverlay = false;
  String _currentQuery = '';

  @override
  void initState() {
    super.initState();
    _currentQuery = widget.initialQuery;
    _searchController.text = widget.initialQuery;
    _searchController.selection = TextSelection.collapsed(
      offset: _searchController.text.length,
    );
    _focusNode.addListener(_handleDesktopFocusChange);
  }

  @override
  void didUpdateWidget(covariant SearchBarDesktop oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialQuery != widget.initialQuery) {
      _currentQuery = widget.initialQuery;
      _searchController.text = widget.initialQuery;
      _searchController.selection = TextSelection.collapsed(
        offset: _searchController.text.length,
      );
      if (mounted) setState(() {});
    }
  }

  void _handleDesktopFocusChange() {
    if (_focusNode.hasFocus) {
      if (_currentQuery.trim().isNotEmpty) {
        _showOverlay();
      }
      return;
    }

    Future.delayed(const Duration(milliseconds: 180), () {
      if (!mounted) return;
      if (!_hoveringOverlay) {
        _removeOverlay();
      }
    });
  }

  @override
  void dispose() {
    _removeOverlay();
    _focusNode.removeListener(_handleDesktopFocusChange);
    _focusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _handleDesktopSearchChanged(String value) {
    setState(() {
      _currentQuery = value;
    });

    context.read<ProductProvider>().filterProducts(value);
    widget.onChanged?.call(value);

    if (value.trim().isEmpty) {
      _removeOverlay();
      return;
    }

    if (_overlayEntry == null) {
      _showOverlay();
    } else {
      _overlayEntry?.markNeedsBuild();
    }
  }

void _submitDesktopSearch(String value) {
  final query = value.trim();
  if (query.isEmpty) return;

  _removeOverlay();
  _focusNode.unfocus();

  context.read<ProductProvider>().filterProducts(query);
  widget.onSubmitted?.call(query);

  // ✅ Verificación de sesión en tiempo real
  final authProvider = context.read<AuthProvider>();

  if (authProvider.isAuth) {
    // Si SÍ está logueado -> Va a /infoProducts
    navigatorKey.currentState?.pushNamed('/infoProducts', arguments: query);
  } else {
    // Si NO está logueado -> Va a la nueva pantalla pública de búsqueda
    navigatorKey.currentState?.pushNamed('/search', arguments: query);
  }
}
  void _clearDesktopSearch() {
    if (_searchController.text.isEmpty && _currentQuery.isEmpty) return;

    setState(() {
      _currentQuery = '';
    });

    _searchController.clear();
    context.read<ProductProvider>().clearSearch();
    widget.onChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    final itemCount = context.watch<CartProvider>().totalItems;

    return Container(
      height: 78,
      color: const Color(0xFF02060D),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22),
        decoration: BoxDecoration(
          color: const Color(0xFF07111F).withOpacity(0.94),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF008CFF).withOpacity(0.13),
              blurRadius: 22,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildBrandLogo(context),
            const SizedBox(width: 24),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: _buildDesktopSearchInput(),
                ),
              ),
            ),
            const SizedBox(width: 24),
            _buildCartButton(context, itemCount),
            const SizedBox(width: 20),
            Container(height: 38, width: 1, color: const Color(0xFF253449)),
            const SizedBox(width: 20),
            const UserDropdownMenu(),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandLogo(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _removeOverlay();
        _clearDesktopSearch();
        Navigator.pushNamed(context, '/home');
      },
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4DB6FF).withOpacity(0.72),
              blurRadius: 12,
            ),
          ],
        ),
        child: ClipOval(
          child: Image.asset(
            'assets/UDElectronics.com.png',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Icon(Icons.flash_on, color: Colors.blue),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopSearchInput() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFF050A13),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF007BFF), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF007BFF).withOpacity(0.16),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          const Icon(Icons.search, color: Color(0xFFB8C2D4), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              key: _textFieldKey,
              controller: _searchController,
              focusNode: _focusNode,
              onChanged: _handleDesktopSearchChanged,
              onSubmitted: _submitDesktopSearch,
              textInputAction: TextInputAction.search,
              style: const TextStyle(color: Colors.white, fontSize: 15.5),
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: const TextStyle(color: Color(0xFFB8C2D4), fontSize: 15.5),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          if (_currentQuery.isNotEmpty)
            IconButton(
              onPressed: () {
                _removeOverlay();
                _clearDesktopSearch();
                _focusNode.requestFocus();
              },
              icon: const Icon(Icons.close, color: Colors.white70, size: 18),
              tooltip: 'Limpiar búsqueda',
            ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildCartButton(BuildContext context, int itemCount) {
    return GestureDetector(
      onTap: () {
        _removeOverlay();
        _clearDesktopSearch();
        Navigator.pushNamed(context, '/cesta');
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 28),
          Positioned(
            right: -7,
            top: -8,
            child: _cartBadge(itemCount, fontSize: 9, padding: 4),
          ),
        ],
      ),
    );
  }

  void _showOverlay() {
    if (_overlayEntry != null || _currentQuery.trim().isEmpty) return;

    final fieldContext = _textFieldKey.currentContext;
    if (fieldContext == null) return;

    final renderObject = fieldContext.findRenderObject();
    if (renderObject is! RenderBox) return;

    final size = renderObject.size;
    final offset = renderObject.localToGlobal(Offset.zero);
    int hoverIndex = -1;

    _overlayEntry = OverlayEntry(
      builder: (overlayContext) {
        return Positioned(
          left: offset.dx,
          top: offset.dy + size.height + 8,
          width: size.width,
          child: MouseRegion(
            onEnter: (_) => _hoveringOverlay = true,
            onExit: (_) => _hoveringOverlay = false,
            child: Material(
              color: Colors.transparent,
              elevation: 12,
              borderRadius: BorderRadius.circular(14),
              child: StatefulBuilder(
                builder: (context, setOverlayState) {
                  return Container(
                    constraints: const BoxConstraints(maxHeight: 300),
                    decoration: BoxDecoration(
                      color: const Color(0xFF07111F),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF1B3248)),
                    ),
                    child: Consumer<ProductProvider>(
                      builder: (context, provider, child) {
                        if (_currentQuery.trim().isEmpty) return const SizedBox.shrink();

                        if (provider.isLoading) {
                          return const Padding(
                            padding: EdgeInsets.all(20),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        final products = provider.filteredProducts;

                        if (products.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('No se encontraron productos.', style: TextStyle(color: Colors.white70)),
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: products.length,
                          itemBuilder: (context, index) {
                            final product = products[index];
                            final isHover = hoverIndex == index;

                            return MouseRegion(
                              cursor: SystemMouseCursors.click,
                              onEnter: (_) => setOverlayState(() => hoverIndex = index),
                              onExit: (_) => setOverlayState(() => hoverIndex = -1),
                              child: InkWell(
                                onTap: () => _openDesktopProduct(product),
                                borderRadius: BorderRadius.circular(12),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 130),
                                  padding: const EdgeInsets.all(10),
                                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isHover ? const Color(0xFF10233B) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isHover ? const Color(0xFF168CFF) : Colors.transparent,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      _productImage(product.images, size: 46),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          product.name,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: isHover ? FontWeight.w700 : FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      if (isHover)
                                        const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF168CFF)),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _openDesktopProduct(Product product) {
    final targetRoute = product.slug.trim().isNotEmpty
        ? '/${product.slug}'
        : '/${_generateSlug(product.name)}';

    _removeOverlay();
    setState(() => _currentQuery = '');
    _searchController.clear();
    context.read<ProductProvider>().clearSearch();
    _focusNode.unfocus();

    navigatorKey.currentState?.pushNamed(targetRoute);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}

/// ============================================================================
/// HELPERS
/// ============================================================================

Widget _productImage(List<String> images, {required double size}) {
  if (images.isEmpty) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF253449),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.image_outlined, color: Colors.white54),
    );
  }

  return ClipRRect(
    borderRadius: BorderRadius.circular(8),
    child: Image.network(
      images.first,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) {
        return Container(
          width: size,
          height: size,
          color: const Color(0xFF253449),
          child: const Icon(Icons.broken_image_outlined, color: Colors.white54),
        );
      },
    ),
  );
}

String _generateSlug(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^\w\s-]'), '')
      .replaceAll(RegExp(r'\s+'), '-')
      .replaceAll(RegExp(r'-+'), '-');
}

Widget _cartBadge(int itemCount, {required double fontSize, required double padding}) {
  return Container(
    padding: EdgeInsets.all(padding),
    decoration: const BoxDecoration(
      color: Color(0xFF168CFF),
      shape: BoxShape.circle,
    ),
    constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
    child: Text(
      itemCount.toString(),
      style: TextStyle(
        color: Colors.white,
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
      ),
      textAlign: TextAlign.center,
    ),
  );
}