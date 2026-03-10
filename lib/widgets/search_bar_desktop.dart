// search_bar_desktop.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ud_store_flutter_app/main.dart';

import '../providers/cart_provider.dart';
import '../providers/product_provider.dart';
import '../widgets/user_dropdown_menu.dart';

class SearchBarDesktop extends StatefulWidget implements PreferredSizeWidget {
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  // ignore: use_super_parameters
  const SearchBarDesktop({
    Key? key,
    this.hintText = 'Buscar...',
    this.onChanged,
    this.onSubmitted,
  }) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _SearchBarDesktopState createState() => _SearchBarDesktopState();

  @override
  Size get preferredSize => const Size.fromHeight(140);
}

class _SearchBarDesktopState extends State<SearchBarDesktop> {
  final FocusNode _focusNode = FocusNode();
  final GlobalKey _textFieldKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  bool _hoveringOverlay = false;
  /*
  void _showOverlay() {
    final renderBox =
        _textFieldKey.currentContext!.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (_) => Positioned(
        left: offset.dx,
        top: offset.dy + size.height,
        width: size.width,
        child: Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 300),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
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
                  shrinkWrap: true,
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return InkWell(
                      onTap: () {
                        final p = product;

                        // 1) Cierra overlay y teclado/foco
                        _removeOverlay();
                        _focusNode.unfocus();

                        // 2) Navega usando el router centralizado (más estable)
                        Future.microtask(() {
                          navigatorKey.currentState?.pushNamed(
                            '/productDetail',
                            arguments: p,
                          );
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: product.images.isNotEmpty
                                  ? Image.network(
                                      Uri.encodeFull(product.images.first),
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      width: 100,
                                      height: 100,
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.image, size: 50),
                                    ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                product.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }
*/
  void _showOverlay() {
    final renderBox =
        _textFieldKey.currentContext!.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    int hoverIndex = -1; // ✅ estado local del overlay

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
                              onEnter: (_) =>
                                  setOverlayState(() => hoverIndex = index),
                              onExit: (_) =>
                                  setOverlayState(() => hoverIndex = -1),
                              child: InkWell(
                                onTap: () {
                                  final p = product;
                                  _removeOverlay();
                                  _focusNode.unfocus();

                                  WidgetsBinding.instance
                                      .addPostFrameCallback((_) {
                                    navigatorKey.currentState?.pushNamed(
                                      '/productDetail',
                                      arguments: p,
                                    );
                                  });
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 140),
                                  curve: Curves.easeOut,
                                  padding: const EdgeInsets.all(12),
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isHover
                                        ? const Color(0xFFF2F7FF)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isHover
                                          ? Colors.blue
                                          : Colors.transparent,
                                      width: 1.2,
                                    ),
                                    boxShadow: isHover
                                        ? [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withOpacity(0.10),
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
                                                Uri.encodeFull(
                                                    product.images.first),
                                                width: 56,
                                                height: 56,
                                                fit: BoxFit.cover,
                                              )
                                            : Container(
                                                width: 56,
                                                height: 56,
                                                color: Colors.grey[300],
                                                child: const Icon(Icons.image,
                                                    size: 28),
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
                                            fontWeight: isHover
                                                ? FontWeight.w800
                                                : FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      if (isHover)
                                        const Icon(Icons.arrow_forward_ios,
                                            size: 16, color: Colors.blue),
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
        return;
      }

      // 👇 Espera un instante: si el click fue sobre el overlay,
      // no lo cierres antes de que se dispare el onTap del InkWell.
      Future.delayed(const Duration(milliseconds: 80), () {
        if (!mounted) return;
        if (_hoveringOverlay) return; // ✅ el mouse está en overlay, no cierres
        _removeOverlay();
      });
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 12.0),
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
                                        hintStyle:
                                            TextStyle(color: Colors.black54),
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(
                                            horizontal: 30.0, vertical: 15),
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
                                    child: const Icon(Icons.search,
                                        color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // _navItem(context, '/infoProducts', Icons.person, ''),
                          // _loginButton(context),
                          const UserDropdownMenu(),
                          //const SizedBox(width: 10),
                          // _navItem(context, '/sales', Icons.person, ''),
                          const SizedBox(width: 10),
                          _navItem(context, '/cesta', Icons.shopping_cart, '',
                              showBadge: true),
                        ],
                      ),
                    ),
                    const Divider(color: Colors.white, thickness: 1.7),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Text('Ofertas', style: _menuStyle),
                          Text('Novedades', style: _menuStyle),
                          Text('Servicios', style: _menuStyle),
                          Text('Robótica', style: _menuStyle),
                          Text('Kits Educativos', style: _menuStyle),
                          Text('Amplificadores', style: _menuStyle),
                          Text('Impresión 3D', style: _menuStyle),
                          Text('Ventas', style: _menuStyle),
                        ],
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

    //final itemCount = cartProvider.cart?.items.length ?? 0;
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

              // 🔥 SIEMPRE mostrar badge cuando showBadge == true
              if (showBadge)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: itemCount > 0
                          ? Colors.red
                          : Colors.red, // rojo o gris
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      itemCount.toString(), // ← muestra 0 si está vacío
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
}
