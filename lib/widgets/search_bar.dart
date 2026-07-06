// search_bar.dart
/*import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ud_store_flutter_app/main.dart';

import '../providers/cart_provider.dart';
import '../providers/product_provider.dart';
import 'user_dropdown_menu.dart';

class SearchBar extends StatelessWidget implements PreferredSizeWidget {
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  const SearchBar({
    Key? key,
    this.hintText = 'Buscar...',
    this.onChanged,
    this.onSubmitted,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 850;

    return isMobile
        ? MobileSearchBar(
            hintText: hintText,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
          )
        : SearchBarDesktop(
            hintText: hintText,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
          );
  }

  @override
  Size get preferredSize => const Size.fromHeight(135);
}

/// ============================================================================
/// COMPONENTE MÓVIL OPTIMIZADO CRO (UNIFICADO Y BLINDADO)
/// ============================================================================

class MobileSearchBar extends StatefulWidget implements PreferredSizeWidget {
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  const MobileSearchBar({
    Key? key,
    this.hintText = 'Buscar...',
    this.onChanged,
    this.onSubmitted,
  }) : super(key: key);

  @override
  State<MobileSearchBar> createState() => _MobileSearchBarState();

  @override
  Size get preferredSize => const Size.fromHeight(135);
}

class _MobileSearchBarState extends State<MobileSearchBar> {
  final FocusNode _mobileFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _mobileFocusNode.addListener(() {
      if (!_mobileFocusNode.hasFocus) {
        FocusManager.instance.primaryFocus?.unfocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppBar(
          backgroundColor: Colors.black,
          elevation: 4.0,
          automaticallyImplyLeading: false,
          title: Row(
            children: [
              // Logo Profesional E-commerce Adaptado a Móviles
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/home'),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.16,
                  height: 44,
                  alignment: Alignment.center,
                  child: Image.asset(
                    'assets/UDElectronics.com.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(Icons.flash_on, color: Colors.amber, size: 24),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Barra de Búsqueda Centrada
              Expanded(
                child: Container(
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 12),
                      const Icon(Icons.search, color: Colors.black54, size: 18),
                      const SizedBox(width: 6),
                      Expanded(
                        child: TextField(
                          focusNode: _mobileFocusNode,
                          onChanged: widget.onChanged,
                          onSubmitted: widget.onSubmitted,
                          style: const TextStyle(color: Colors.black, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: widget.hintText,
                            hintStyle: const TextStyle(color: Colors.black54, fontSize: 14),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 6),
              const UserDropdownMenu(),
              const SizedBox(width: 4),
              _iconButton(context, Icons.receipt_long_outlined, '', '/sales'),
              const SizedBox(width: 4),
              _cartIcon(context),
            ],
          ),
        ),

        // Categorías Horizontales
        Container(
          color: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: const SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: BouncingScrollPhysics(),
            child: Row(
              children: [
                SizedBox(width: 15),
                Text('Ofertas', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
                SizedBox(width: 18),
                Text('Novedades', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
                SizedBox(width: 18),
                Text('Servicios', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
                SizedBox(width: 18),
                Text('Robótica', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
                SizedBox(width: 18),
                Text('Kits Educativos', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
                SizedBox(width: 18),
                Text('Amplificadores', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
                SizedBox(width: 18),
                Text('Impresión 3D', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
                SizedBox(width: 18),
                Text('Ventas', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
                SizedBox(width: 15),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _iconButton(BuildContext context, IconData icon, String label, String route) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, route),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            if (label.isNotEmpty)
              Text(label, style: const TextStyle(color: Colors.white, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _cartIcon(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final itemCount = cartProvider.totalItems;

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/cesta'),
      child: Padding(
        padding: const EdgeInsets.only(right: 4),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              height: 38,
              width: 38,
              decoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.shopping_cart, color: Colors.white, size: 20),
            ),
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text(
                  itemCount.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ============================================================================
/// COMPONENTE ESCRITORIO OPTIMIZADO CRO (UNIFICADO)
/// ============================================================================

class SearchBarDesktop extends StatefulWidget implements PreferredSizeWidget {
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  const SearchBarDesktop({
    Key? key,
    this.hintText = 'Buscar...',
    this.onChanged,
    this.onSubmitted,
  }) : super(key: key);

  @override
  _SearchBarDesktopState createState() => _SearchBarDesktopState();

  @override
  Size get preferredSize => const Size.fromHeight(140);
}

class _SearchBarDesktopState extends State<SearchBarDesktop> {
  final FocusNode _focusNode = FocusNode();
  final GlobalKey _textFieldKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  bool _hoveringOverlay = false;

  void _showOverlay() {
    final renderBox = _textFieldKey.currentContext!.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    int hoverIndex = -1; 

    _overlayEntry = OverlayEntry(
      builder: (_) => Positioned(
        left: offset.dx,
        top: offset.dy + size.height,
        width: size.width,
        child: MouseRegion(
            onEnter: (_) => _hoveringOverlay = true,
            onExit: (_) => _hoveringOverlay = false,
            child: Material(
              elevation: 10,
              borderRadius: BorderRadius.circular(14),
              child: StatefulBuilder(
                builder: (context, setOverlayState) {
                  return Container(
                    constraints: const BoxConstraints(maxHeight: 320),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Consumer<ProductProvider>(
                      builder: (context, provider, _) {
                        final products = provider.filteredProducts;

                        if (products.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('No se encontraron productos.'),
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
                                onTap: () {
                                  _removeOverlay();
                                  _focusNode.unfocus();

                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    final targetRoute = product.slug.isNotEmpty 
                                        ? '/${product.slug}' 
                                        : '/${product.name.toLowerCase().trim().replaceAll(' ', '-')}';
                                    
                                    navigatorKey.currentState?.pushNamed(targetRoute);
                                  });
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 140),
                                  curve: Curves.easeOut,
                                  padding: const EdgeInsets.all(12),
                                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isHover ? const Color(0xFFF2F7FF) : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isHover ? Colors.blue : Colors.transparent,
                                      width: 1.2,
                                    ),
                                    boxShadow: isHover
                                        ? [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.10),
                                              blurRadius: 16,
                                              offset: const Offset(0, 10),
                                            )
                                          ]
                                        : [],
                                  ),
                                  child: Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: product.images.isNotEmpty
                                            ? Image.network(
                                                Uri.encodeFull(product.images.first),
                                                width: 56,
                                                height: 56,
                                                fit: BoxFit.cover,
                                              )
                                            : Container(
                                                width: 56,
                                                height: 56,
                                                color: Colors.grey[300],
                                                child: const Icon(Icons.image, size: 28),
                                              ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          product.name,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: isHover ? FontWeight.w800 : FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      if (isHover)
                                        const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.blue),
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
            )),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _showOverlay();
      } else {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (!mounted) return;
          if (!_hoveringOverlay) { 
            _removeOverlay();
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);

    return Stack(
      children: [
        Container(
          color: Colors.black,
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/home'),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.09,
                  height: 200,
                  decoration: const BoxDecoration(
                    border: Border(
                      right: BorderSide(color: Colors.white, width: 0.2),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Image.asset(
                    'assets/UDElectronics.com.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.menu, color: Colors.white, size: 30),
                              SizedBox(width: 5),
                              Text(
                                'Categorías',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 27.5,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Roboto',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Container(
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(30.0),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      key: _textFieldKey,
                                      focusNode: _focusNode,
                                      onChanged: (value) {
                                        productProvider.filterProducts(value);
                                        setState(() {});
                                      },
                                      onSubmitted: widget.onSubmitted,
                                      decoration: const InputDecoration(
                                        hintText: 'Buscar...',
                                        hintStyle: TextStyle(color: Colors.black54),
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(horizontal: 30.0, vertical: 15),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    margin: const EdgeInsets.only(right: 5.0),
                                    height: 35,
                                    width: 50,
                                    decoration: BoxDecoration(
                                      color: Colors.black,
                                      borderRadius: BorderRadius.circular(30.0),
                                    ),
                                    child: const Icon(Icons.search, color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const UserDropdownMenu(),
                          const SizedBox(width: 10),
                          _navItem(context, '/cesta', Icons.shopping_cart, '', showBadge: true),
                        ],
                      ),
                    ),
                    const Divider(color: Colors.white, thickness: 1.7),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: const [
                            Padding(padding: EdgeInsets.symmetric(horizontal: 14.0), child: Text('Ofertas', style: _menuStyle)),
                            Padding(padding: EdgeInsets.symmetric(horizontal: 14.0), child: Text('Novedades', style: _menuStyle)),
                            Padding(padding: EdgeInsets.symmetric(horizontal: 14.0), child: Text('Servicios', style: _menuStyle)),
                            Padding(padding: EdgeInsets.symmetric(horizontal: 14.0), child: Text('Robótica', style: _menuStyle)),
                            Padding(padding: EdgeInsets.symmetric(horizontal: 14.0), child: Text('Kits Educativos', style: _menuStyle)),
                            Padding(padding: EdgeInsets.symmetric(horizontal: 14.0), child: Text('Amplificadores', style: _menuStyle)),
                            Padding(padding: EdgeInsets.symmetric(horizontal: 14.0), child: Text('Impresión 3D', style: _menuStyle)),
                            Padding(padding: EdgeInsets.symmetric(horizontal: 14.0), child: Text('Ventas', style: _menuStyle)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static const TextStyle _menuStyle = TextStyle(
    color: Colors.white,
    fontSize: 20,
    fontFamily: 'Roboto',
    fontWeight: FontWeight.w500,
  );

  Widget _navItem(
      BuildContext context, String route, IconData icon, String label,
      {bool showBadge = false}) {
    final cartProvider = Provider.of<CartProvider>(context);
    final itemCount = cartProvider.totalItems;
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, route),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: 45,
                width: 45,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 30),
              ),
              if (showBadge)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      itemCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 5),
        Text(label, style: _menuStyle),
      ],
    );
  }
}*/

// search_bar.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ud_store_flutter_app/main.dart';

import '../providers/cart_provider.dart';
import '../providers/product_provider.dart';
import 'user_dropdown_menu.dart';

class SearchBar extends StatelessWidget implements PreferredSizeWidget {
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  const SearchBar({
    Key? key,
    this.hintText = 'Buscar productos, Marca y más...',
    this.onChanged,
    this.onSubmitted,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 850;

    return Material(
      color: const Color(0xFF02060D),
      elevation: 0,
      child: isMobile
          ? MobileSearchBar(
              hintText: hintText,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
            )
          : SearchBarDesktop(
              hintText: hintText,
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
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  const MobileSearchBar({
    Key? key,
    this.hintText = 'Buscar...',
    this.onChanged,
    this.onSubmitted,
  }) : super(key: key);

  @override
  State<MobileSearchBar> createState() => _MobileSearchBarState();

  @override
  Size get preferredSize => const Size.fromHeight(76);
}

class _MobileSearchBarState extends State<MobileSearchBar> {
  final FocusNode _mobileFocusNode = FocusNode();

  @override
  void dispose() {
    _mobileFocusNode.dispose();
    super.dispose();
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
            _mobileLogo(context),
            const SizedBox(width: 8),
            Expanded(child: _mobileSearchInput()),
            const SizedBox(width: 8),
            const UserDropdownMenu(),
            const SizedBox(width: 6),
            _mobileCartIcon(context),
          ],
        ),
      ),
    );
  }

  Widget _mobileLogo(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/home'),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF58C2FF).withOpacity(.55),
              blurRadius: 10,
              spreadRadius: 0,
            ),
          ],
        ),
        child: ClipOval(
          child: Image.asset(
            'assets/UDElectronics.com.png',
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Widget _mobileSearchInput() {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFF050A13),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF007BFF),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 10),
          const Icon(Icons.search, color: Color(0xFFB8C2D4), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              focusNode: _mobileFocusNode,
              onChanged: widget.onChanged,
              onSubmitted: widget.onSubmitted,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: const TextStyle(
                  color: Color(0xFFB8C2D4),
                  fontSize: 13,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mobileCartIcon(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final itemCount = cartProvider.totalItems;

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/cesta'),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(
            Icons.shopping_cart_outlined,
            color: Colors.white,
            size: 26,
          ),
          Positioned(
            right: -7,
            top: -8,
            child: _cartBadge(itemCount, fontSize: 9, padding: 4),
          ),
        ],
      ),
    );
  }
}

/// ============================================================================
/// ESCRITORIO
/// ============================================================================

class SearchBarDesktop extends StatefulWidget implements PreferredSizeWidget {
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  const SearchBarDesktop({
    Key? key,
    this.hintText = 'Buscar productos, Marca y más...',
    this.onChanged,
    this.onSubmitted,
  }) : super(key: key);

  @override
  State<SearchBarDesktop> createState() => _SearchBarDesktopState();

  @override
  Size get preferredSize => const Size.fromHeight(78);
}

class _SearchBarDesktopState extends State<SearchBarDesktop> {
  final FocusNode _focusNode = FocusNode();
  final GlobalKey _textFieldKey = GlobalKey();

  OverlayEntry? _overlayEntry;
  bool _hoveringOverlay = false;

  @override
  void initState() {
    super.initState();

    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _showOverlay();
      } else {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (!mounted) return;
          if (!_hoveringOverlay) _removeOverlay();
        });
      }
    });
  }

  @override
  void dispose() {
    _removeOverlay();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context);
    final itemCount = cartProvider.totalItems;

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
            _brandLogo(context),
            const SizedBox(width: 24),

            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: _searchInput(productProvider),
                ),
              ),
            ),

            const SizedBox(width: 24),
            _cartButton(context, itemCount),
            const SizedBox(width: 20),

            Container(
              height: 38,
              width: 1,
              color: const Color(0xFF253449),
            ),

            const SizedBox(width: 20),
            const UserDropdownMenu(),
          ],
        ),
      ),
    );
  }

  Widget _brandLogo(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/home'),
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4DB6FF).withOpacity(0.72),
              blurRadius: 12,
              spreadRadius: 0,
            ),
          ],
        ),
        child: ClipOval(
          child: Image.asset(
            'assets/UDElectronics.com.png',
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Widget _searchInput(ProductProvider productProvider) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFF050A13),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF007BFF),
          width: 1.1,
        ),
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
          const Icon(
            Icons.search,
            color: Color(0xFFB8C2D4),
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              key: _textFieldKey,
              focusNode: _focusNode,
              onChanged: (value) {
                productProvider.filterProducts(value);
                setState(() {});
              },
              onSubmitted: widget.onSubmitted,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15.5,
              ),
              decoration: const InputDecoration(
                hintText: 'Buscar productos, Marca y más...',
                hintStyle: TextStyle(
                  color: Color(0xFFB8C2D4),
                  fontSize: 15.5,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cartButton(BuildContext context, int itemCount) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/cesta'),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(
            Icons.shopping_cart_outlined,
            color: Colors.white,
            size: 28,
          ),
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
    if (_overlayEntry != null) return;
    if (_textFieldKey.currentContext == null) return;

    final renderBox =
        _textFieldKey.currentContext!.findRenderObject() as RenderBox;

    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    int hoverIndex = -1;

    _overlayEntry = OverlayEntry(
      builder: (_) => Positioned(
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
                    border: Border.all(
                      color: const Color(0xFF1B3248),
                      width: 1,
                    ),
                  ),
                  child: Consumer<ProductProvider>(
                    builder: (context, provider, _) {
                      final products = provider.filteredProducts;

                      if (products.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'No se encontraron productos.',
                            style: TextStyle(color: Colors.white70),
                          ),
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
                            onEnter: (_) {
                              setOverlayState(() => hoverIndex = index);
                            },
                            onExit: (_) {
                              setOverlayState(() => hoverIndex = -1);
                            },
                            child: InkWell(
                              onTap: () {
                                _removeOverlay();
                                _focusNode.unfocus();

                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  final targetRoute = product.slug.isNotEmpty
                                      ? '/${product.slug}'
                                      : '/${product.name.toLowerCase().trim().replaceAll(' ', '-')}';

                                  navigatorKey.currentState
                                      ?.pushNamed(targetRoute);
                                });
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 130),
                                padding: const EdgeInsets.all(10),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isHover
                                      ? const Color(0xFF10233B)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isHover
                                        ? const Color(0xFF168CFF)
                                        : Colors.transparent,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: product.images.isNotEmpty
                                          ? Image.network(
                                              Uri.encodeFull(
                                                product.images.first,
                                              ),
                                              width: 46,
                                              height: 46,
                                              fit: BoxFit.cover,
                                            )
                                          : Container(
                                              width: 46,
                                              height: 46,
                                              color: const Color(0xFF253449),
                                              child: const Icon(
                                                Icons.image,
                                                color: Colors.white54,
                                                size: 22,
                                              ),
                                            ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        product.name,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: isHover
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    if (isHover)
                                      const Icon(
                                        Icons.arrow_forward_ios,
                                        size: 14,
                                        color: Color(0xFF168CFF),
                                      ),
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
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}

Widget _cartBadge(
  int itemCount, {
  required double fontSize,
  required double padding,
}) {
  return Container(
    padding: EdgeInsets.all(padding),
    decoration: const BoxDecoration(
      color: Color(0xFF168CFF),
      shape: BoxShape.circle,
    ),
    constraints: const BoxConstraints(
      minWidth: 15,
      minHeight: 15,
    ),
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