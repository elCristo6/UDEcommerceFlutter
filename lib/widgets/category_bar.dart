import 'package:flutter/material.dart';

class CategoryBar extends StatefulWidget {
  final List<String> categories;

  // ignore: use_super_parameters
  const CategoryBar({Key? key, required this.categories}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _CategoryBarState createState() => _CategoryBarState();
}

class _CategoryBarState extends State<CategoryBar> {
  Map<String, bool> _isHovering = {};
  bool _isMenuOpen = false;
  OverlayEntry? _overlayEntry;
  final GlobalKey _buttonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // ignore: avoid_function_literals_in_foreach_calls
    widget.categories.forEach((category) {
      _isHovering[category] = false;
    });
  }

  OverlayEntry _createOverlayEntry(BuildContext context) {
    final renderBox =
        _buttonKey.currentContext!.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    double menuWidth =
        size.width; // Ajusta el ancho del menú para que coincida con el botón

    return OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx,
        top: offset.dy + size.height,
        width: menuWidth, // Usar el ancho ajustado
        child: MouseRegion(
          onEnter: (_) {
            setState(() {
              _isMenuOpen = true;
            });
          },
          onExit: (_) {
            Future.delayed(const Duration(milliseconds: 300), () {
              if (!_isHovering.values.contains(true)) {
                _overlayEntry?.remove();
                _overlayEntry = null;
                setState(() {
                  _isMenuOpen = false;
                });
              }
            });
          },
          child: Material(
            elevation: 8.0,
            borderRadius: BorderRadius.circular(20.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Divider(),
                  _buildMenuItem(Icons.adb, 'Robotica'),
                  _buildMenuItem(Icons.face, 'Impresion 3D'),
                  _buildMenuItem(Icons.accessibility, 'Kits educativos'),
                  _buildMenuItem(Icons.watch, 'Microcontroladores'),
                  _buildMenuItem(Icons.electric_bike, 'Electrónica'),
                  _buildMenuItem(Icons.lightbulb, 'Sensores'),
                  _buildMenuItem(Icons.kitchen, 'Comunicaciones'),
                  _buildMenuItem(Icons.motorcycle, 'Motores'),
                  _buildMenuItem(Icons.battery_6_bar_sharp, 'Baterias'),
                  _buildMenuItem(Icons.shopping_bag, 'Fuentes de Voltaje'),
                  _buildMenuItem(Icons.shopping_bag, 'Display'),
                  _buildMenuItem(Icons.surround_sound_outlined, 'Sonido'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String text) {
    return MouseRegion(
      onEnter: (_) {
        setState(() {
          _isHovering[text] = true;
        });
      },
      onExit: (_) {
        Future.delayed(const Duration(milliseconds: 300), () {
          setState(() {
            _isHovering[text] = false;
          });
        });
      },
      child: ListTile(
        leading: Icon(icon),
        title: Text(text),
        onTap: () {
          // Acción del menú
        },
      ),
    );
  }

  void _showMenu(BuildContext context) {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
    }
    _overlayEntry = _createOverlayEntry(context);
    Overlay.of(context).insert(_overlayEntry!);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double
          .infinity, // Asegurar que el contenedor ocupe todo el ancho de la pantalla
      color: Colors.black,
      padding: const EdgeInsets.symmetric(vertical: 8.0), // Ajustar la altura
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: MouseRegion(
                onEnter: (_) {
                  setState(() {
                    _isMenuOpen = true;
                    _showMenu(context);
                  });
                },
                onExit: (_) {
                  Future.delayed(const Duration(milliseconds: 300), () {
                    if (!_isHovering.values.contains(true)) {
                      _overlayEntry?.remove();
                      _overlayEntry = null;
                      setState(() {
                        _isMenuOpen = false;
                      });
                    }
                  });
                },
                child: ElevatedButton.icon(
                  key: _buttonKey,
                  onPressed: () {},
                  icon: const Icon(Icons.menu, color: Colors.white),
                  label: Row(
                    children: [
                      const Text(
                        'Todas las categorías',
                        style: TextStyle(color: Colors.white),
                      ),
                      Icon(
                        _isMenuOpen
                            ? Icons.arrow_drop_up
                            : Icons.arrow_drop_down,
                        color: Colors.white,
                      ),
                    ],
                  ),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    disabledForegroundColor: Colors.white.withOpacity(0.38),
                    disabledBackgroundColor: Colors.white.withOpacity(0.12),
                    shadowColor: Colors.transparent,
                    elevation: 0,
                    backgroundColor: Colors.grey[800],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12.0, vertical: 15.0),
                  ),
                ),
              ),
            ),
            Row(
              children: widget.categories.map((category) {
                return MouseRegion(
                  onEnter: (_) {
                    setState(() {
                      _isHovering[category] = true;
                    });
                  },
                  onExit: (_) {
                    setState(() {
                      _isHovering[category] = false;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 5.0),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20.0, vertical: 10.0),
                    decoration: BoxDecoration(
                      color: _isHovering[category]!
                          ? Colors.grey[700]
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: Text(
                      category,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
