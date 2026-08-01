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
      builder: (_) => Positioned(
        width: 250,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(-120, 82),
          child: MouseRegion(
            onEnter: (_) => _setHover(true),
            onExit: (_) => _setHover(false),
            child: Material(
              color: const Color(0xFF07111F),
              elevation: 12,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF07111F),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF1B3248),
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isAdmin) ...[
                      _menuItem(Icons.inventory_2_outlined, 'Inventario', '/stock'),
                      _menuItem(Icons.receipt_long_outlined, 'Ventas', '/sales'),
                      _menuItem(Icons.add_circle_outline, 'Info productos', '/infoProducts'),
                      _menuItem(Icons.handshake_outlined, 'Préstamos B2B', '/loans'),
                      const Divider(color: Color(0xFF253449)),
                    ],
                    ListTile(
                      leading: const Icon(Icons.logout, color: Colors.redAccent),
                      title: const Text(
                        'Cerrar sesión',
                        style: TextStyle(color: Colors.white),
                      ),
                      onTap: () {
                        Provider.of<AuthProvider>(context, listen: false).logout();
                        _hideMenu();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  Widget _menuItem(IconData icon, String title, String route) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF168CFF)),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: () {
        Navigator.pushNamed(context, route);
        _hideMenu();
      },
    );
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
    child: Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF168CFF),
          width: 1.1,
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.login,
            color: Color(0xFF168CFF),
            size: 22,
          ),
          SizedBox(width: 10),
          Text(
            'Iniciar sesión',
            style: TextStyle(
              color: Color(0xFF168CFF),
              fontSize: 15.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}
    final name = auth.user!.name;
    final initials = _getInitials(name);

    return CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(
        onEnter: (_) {
          _setHover(true);
          _showMenu();
        },
        onExit: (_) => _setHover(false),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF0D47A1),
                    Color(0xFF1E40AF),
                  ],
                ),
              ),
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Icon(
              Icons.keyboard_arrow_down,
              color: Color(0xFFC8D2E0),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name
        .trim()
        .split(' ')
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) return 'UD';
    if (parts.length == 1) return parts.first[0].toUpperCase();

    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}