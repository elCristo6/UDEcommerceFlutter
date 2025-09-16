/*import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import 'login_modal.dart';

class UserDropdownMenu extends StatefulWidget {
  const UserDropdownMenu({super.key});

  @override
  State<UserDropdownMenu> createState() => _UserDropdownMenuState();
}

class _UserDropdownMenuState extends State<UserDropdownMenu> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isHovered = false;
  void _showMenu() {
    if (_overlayEntry != null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // ✅ Capa para detectar clics fuera del menú
          GestureDetector(
            onTap: () => _hideMenu(),
            behavior: HitTestBehavior.translucent,
            child: Container(
              color: Colors.transparent,
            ),
          ),
          // Menú real
          Positioned(
            width: 250,
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: const Offset(0, 60),
              child: MouseRegion(
                onEnter: (_) => _setHover(true),
                onExit: (_) => _setHover(false),
                child: Material(
                  color: Colors.white,
                  elevation: 4,
                  borderRadius: BorderRadius.circular(12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.receipt_long_outlined),
                        title: const Text("Mis Pedidos"),
                        onTap: () {
                          Navigator.pushNamed(context, '/orders');
                          _hideMenu();
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.add_circle_outline),
                        title: const Text("Mis monedas"),
                        onTap: () {
                          Navigator.pushNamed(context, '/coins');
                          _hideMenu();
                        },
                      ),
                      ListTile(
                        leading: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.message_outlined),
                            SizedBox(width: 6),
                            Text(
                              "(139)",
                              style: TextStyle(color: Colors.redAccent),
                            )
                          ],
                        ),
                        title: const Text("Centro de Mensajes"),
                        onTap: () {
                          Navigator.pushNamed(context, '/messages');
                          _hideMenu();
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.credit_card_outlined),
                        title: const Text("Pago"),
                        onTap: () {
                          Navigator.pushNamed(context, '/payment');
                          _hideMenu();
                        },
                      ),
                      const Divider(),
                      ListTile(
                        leading:
                            const Icon(Icons.logout, color: Colors.redAccent),
                        title: const Text("Cerrar sesión"),
                        onTap: () {
                          Provider.of<AuthProvider>(context, listen: false)
                              .logout();
                          _hideMenu();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideMenu() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _setHover(bool hovering) {
    if (hovering != _isHovered) {
      setState(() => _isHovered = hovering);
      if (!hovering) {
        Future.delayed(const Duration(milliseconds: 250), () {
          if (!_isHovered) _hideMenu();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    if (auth.user == null) {
      return GestureDetector(
        onTap: () {
          showDialog(
            context: context,
            barrierDismissible: true,
            builder: (_) => const LoginModal(),
          );
        },
        child: const Row(
          children: [
            Icon(Icons.person_outline, color: Colors.white, size: 48),
            SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('¡Bienvenido!',
                    style: TextStyle(color: Colors.white, fontSize: 12)),
                Text('Identifícate / Regístrate',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
              ],
            ),
          ],
        ),
      );
    }

    return CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(
        onEnter: (_) => _showMenu(),
        onExit: (_) => _setHover(false),
        child: Row(
          children: [
            const Icon(Icons.person, color: Colors.white, size: 48),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Hola,',
                    style: TextStyle(color: Colors.white, fontSize: 12)),
                Text(auth.user!.name.split(" ").first,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
*/

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import 'login_modal.dart';

class UserDropdownMenu extends StatefulWidget {
  const UserDropdownMenu({super.key});

  @override
  State<UserDropdownMenu> createState() => _UserDropdownMenuState();
}

class _UserDropdownMenuState extends State<UserDropdownMenu> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isHovering = false;
  void _showMenu() {
    if (_overlayEntry != null) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final isAdmin = auth.user?.role == 'admin';

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: 250,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 60),
          child: MouseRegion(
            onEnter: (_) => _setHover(true),
            onExit: (_) => _setHover(false),
            child: Material(
              color: Colors.white,
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isAdmin) ...[
                    ListTile(
                      leading: const Icon(Icons.receipt_long_outlined),
                      title: const Text("Ventas"),
                      onTap: () {
                        Navigator.pushNamed(context, '/sales');
                        _hideMenu();
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.add_circle_outline),
                      title: const Text("Info productos"),
                      onTap: () {
                        Navigator.pushNamed(context, '/infoProducts');
                        _hideMenu();
                      },
                    ),
                    const Divider(),
                  ],
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.redAccent),
                    title: const Text("Cerrar sesión"),
                    onTap: () {
                      Provider.of<AuthProvider>(context, listen: false)
                          .logout();
                      _hideMenu();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideMenu() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _setHover(bool hover) {
    _isHovering = hover;
    if (!hover) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!_isHovering) _hideMenu();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    if (auth.user == null) {
      return GestureDetector(
        onTap: () {
          showDialog(
            context: context,
            barrierDismissible: true,
            builder: (_) => const LoginModal(),
          );
        },
        child: const Row(
          children: [
            Icon(Icons.person_outline, color: Colors.white, size: 48),
            SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('¡Bienvenido!',
                    style: TextStyle(color: Colors.white, fontSize: 12)),
                Text('Identifícate / Regístrate',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
              ],
            ),
          ],
        ),
      );
    }

    return CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(
        onEnter: (_) {
          _setHover(true);
          _showMenu();
        },
        onExit: (_) => _setHover(false),
        child: Row(
          children: [
            const Icon(Icons.person, color: Colors.white, size: 48),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Hola,',
                    style: TextStyle(color: Colors.white, fontSize: 12)),
                Text(auth.user!.name.split(" ").first,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
