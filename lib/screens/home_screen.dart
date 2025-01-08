/*import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/product_provider.dart';
import '../widgets/image_carousel.dart';
import '../widgets/product_card.dart';
import '../widgets/search_bar.dart' as custom;

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const custom.SearchBar(), // Mantener el AppBar fijo
      body: CustomScrollView(
        slivers: [
          // Carrusel de imágenes
          SliverToBoxAdapter(
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.3,
              child: ImageCarousel(),
            ),
          ),
          // Espaciado entre el carrusel y los productos
          SliverToBoxAdapter(
            child: const SizedBox(height: 10),
          ),
          // Grid de productos
          Consumer<ProductProvider>(
            builder: (context, productProvider, child) {
              if (productProvider.isLoading) {
                return const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (productProvider.products.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Center(child: Text('No hay productos disponibles')),
                );
              }

              return SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6, // Seis productos por fila
                  childAspectRatio: 0.75, // Relación de aspecto ajustada
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final product = productProvider.products[index];
                    return ProductCard(product: product);
                  },
                  childCount: productProvider.products.length,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
*/
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/product_provider.dart';
import '../widgets/image_carousel.dart';
import '../widgets/product_card.dart';
import '../widgets/search_bar.dart' as custom;

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const custom.SearchBar(),
      body: ListView(
        children: [
          // Carrusel de imágenes
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.3,
            child: ImageCarousel(),
          ),
          const SizedBox(
              height: 10), // Espaciado entre el carrusel y los productos

          // Productos destacados
          Consumer<ProductProvider>(
            builder: (context, productProvider, child) {
              if (productProvider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (productProvider.products.isEmpty) {
                return const Center(
                    child: Text('No hay productos disponibles'));
              }

              // Limitar productos a mostrar a 24 (4 filas de 6 productos)
              final visibleProducts =
                  productProvider.products.take(24).toList();

              return GridView.builder(
                shrinkWrap:
                    true, // Permitir que el GridView se ajuste a su contenido
                physics:
                    const NeverScrollableScrollPhysics(), // Desactivar el scroll interno
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                itemCount:
                    visibleProducts.length, // Mostrar solo productos limitados
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6, // Seis productos por fila
                  childAspectRatio: 0.75, // Relación de aspecto ajustada
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemBuilder: (context, index) {
                  final product = visibleProducts[index];
                  return ProductCard(product: product);
                },
              );
            },
          ),

          // Espaciado antes del footer
          const SizedBox(height: 20),

          // Pie de página o footer
          Container(
            color: Colors.black,
            padding: const EdgeInsets.all(16.0),
            child: const Center(
              child: Text(
                '© 2025 UD Electronics. Todos los derechos reservados.',
                style: TextStyle(fontSize: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
