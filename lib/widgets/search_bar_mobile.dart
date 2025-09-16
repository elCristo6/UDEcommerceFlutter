import 'package:flutter/material.dart';

class MobileSearchBar extends StatelessWidget implements PreferredSizeWidget {
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
              // Logo
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/home'),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.13,
                  height: 50,
                  decoration: const BoxDecoration(
                    border: Border(
                      right: BorderSide(color: Colors.white, width: 0.2),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Image.asset(
                    'assets/flayers instagram (5).png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Search Field
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 10),
                      const Icon(Icons.search, color: Colors.black54),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          onChanged: onChanged,
                          onSubmitted: onSubmitted,
                          style: const TextStyle(color: Colors.black),
                          decoration: InputDecoration(
                            hintText: hintText,
                            hintStyle: const TextStyle(color: Colors.black54),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Acciones a la derecha
              const SizedBox(width: 5),
              _iconButton(context, Icons.person, '', '/infoProducts'),
              const SizedBox(width: 8),
              _iconButton(context, Icons.person, '', '/sales'),
              const SizedBox(width: 8),
              _cartIcon(context),
            ],
          ),
        ),

        // Categorías horizontales
        Container(
          color: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: const SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                SizedBox(width: 15),
                Text('Ofertas',
                    style: TextStyle(color: Colors.white, fontSize: 16)),
                SizedBox(width: 15),
                Text('Novedades',
                    style: TextStyle(color: Colors.white, fontSize: 16)),
                SizedBox(width: 15),
                Text('Servicios',
                    style: TextStyle(color: Colors.white, fontSize: 16)),
                SizedBox(width: 15),
                Text('Robótica',
                    style: TextStyle(color: Colors.white, fontSize: 16)),
                SizedBox(width: 15),
                Text('Kits Educativos',
                    style: TextStyle(color: Colors.white, fontSize: 16)),
                SizedBox(width: 15),
                Text('Amplificadores',
                    style: TextStyle(color: Colors.white, fontSize: 16)),
                SizedBox(width: 15),
                Text('Impresión 3D',
                    style: TextStyle(color: Colors.white, fontSize: 16)),
                SizedBox(width: 15),
                Text('Ventas',
                    style: TextStyle(color: Colors.white, fontSize: 16)),
                SizedBox(width: 15),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _iconButton(
      BuildContext context, IconData icon, String label, String route) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, route),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 24),
          Text(label,
              style: const TextStyle(color: Colors.white, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _cartIcon(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/cesta'),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: const BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
            child:
                const Icon(Icons.shopping_cart, color: Colors.white, size: 24),
          ),
          Positioned(
            right: 2,
            top: 2,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
              child: const Text(
                '0',
                style: TextStyle(color: Colors.white, fontSize: 10),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(90);
}
