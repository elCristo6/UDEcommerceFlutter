import 'package:flutter/material.dart';

class SearchBar extends StatelessWidget implements PreferredSizeWidget {
  final String hintText;
  final ValueChanged<String>? onChanged;

  const SearchBar({
    Key? key,
    this.hintText = 'Buscar...',
    this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black, // Fondo negro para la AppBar
      child: Row(
        children: [
          // Primera columna: Logo con borde blanco
          GestureDetector(
            onTap: () {
              // Al presionar el logo, vuelve a la pantalla principal
              Navigator.pushNamed(context, '/home');
            },
            child: Container(
              width: MediaQuery.of(context).size.width *
                  0.09, // 10% del ancho total
              height: 200, // Altura fija ajustada
              decoration: const BoxDecoration(
                border: Border(
                  // Borde blanco
                  right: BorderSide(color: Colors.white, width: 0.2),
                ),
              ),
              alignment: Alignment.center,
              child: Image.asset(
                'assets/UDlogo copy.jpeg', // Asegúrate de que la ruta es correcta
                fit: BoxFit.contain,
              ),
            ),
          ),
          // Segunda columna: Resto del contenido
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Primera fila: Categorías, barra de búsqueda y botones
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Texto "Categorías"
                      const Row(
                        children: [
                          Icon(Icons.menu, color: Colors.white, size: 30),
                          SizedBox(width: 5),
                          Text(
                            'Categorías',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 27.5, // Ajuste del tamaño de la fuente
                              fontWeight:
                                  FontWeight.w600, // Peso similar al ejemplo
                              fontFamily:
                                  'Roboto', // Tipografía similar al diseño
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 15),
                      // Barra de búsqueda
                      Expanded(
                        child: Container(
                          height: 40, // Altura de la barra de búsqueda
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30.0),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  onChanged: onChanged,
                                  onSubmitted: onChanged,
                                  decoration: const InputDecoration(
                                    hintText: 'Buscar...',
                                    hintStyle: TextStyle(color: Colors.black54),
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
                      // Iconos a la derecha
                      Row(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  // Al presionar el icono de la cesta, navega a la página de la cesta
                                  Navigator.pushNamed(context, '/infoProducts');
                                },
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
                                      child: const Icon(Icons.person,
                                          color: Colors.white, size: 30),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 5),
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Productos',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(width: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  // Al presionar el icono de la cesta, navega a la página de la cesta
                                  Navigator.pushNamed(context, '/sales');
                                },
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
                                      child: const Icon(Icons.person,
                                          color: Colors.white, size: 30),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 5),
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Ventas',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(width: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  // Al presionar el icono de la cesta, navega a la página de la cesta
                                  Navigator.pushNamed(context, '/cesta');
                                },
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
                                      child: const Icon(Icons.shopping_cart,
                                          color: Colors.white, size: 30),
                                    ),
                                    Positioned(
                                      right: 4,
                                      top: 4,
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        constraints: const BoxConstraints(
                                          minWidth: 16,
                                          minHeight: 16,
                                        ),
                                        child: const Text(
                                          '0',
                                          style: TextStyle(
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
                              const Text(
                                'Cesta',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontFamily: 'Roboto',
                                    fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white, thickness: 1.7),
                // Segunda fila: Menú
                const Padding(
                  padding: EdgeInsets.only(left: 8.0, right: 8.0, top: 0.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text(
                        'Ofertas',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20, // Ajuste del tamaño
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w500),
                      ),
                      Text(
                        'Novedades',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20, // Ajuste del tamaño
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w500),
                      ),
                      Text(
                        'Servicios',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20, // Ajuste del tamaño
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w500),
                      ),
                      Text(
                        'Robótica',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20, // Ajuste del tamaño
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w500),
                      ),
                      Text(
                        'Kits Educativos',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20, // Ajuste del tamaño
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w500),
                      ),
                      Text(
                        'Amplificadores',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20, // Ajuste del tamaño
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w500),
                      ),
                      Text(
                        'Impresión 3D',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20, // Ajuste del tamaño
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w500),
                      ),
                      Text(
                        'Ventas',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20, // Ajuste del tamaño
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize =>
      const Size.fromHeight(120); // Ajusta la altura de la AppBar
}
