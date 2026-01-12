/*import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/product_provider.dart';
import '../widgets/image_carousel.dart';
import '../widgets/least_selling_carousel.dart';
import '../widgets/product_card.dart';
import '../widgets/search_bar.dart' as custom;
import '../widgets/top_selling_carousel.dart'; // Importar
import '../widgets/whatsapp_logo_widget.dart'; // Asegúrate de importar el widget creado

class HomeScreen extends StatelessWidget {
  // ignore: use_super_parameters
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: const custom.SearchBar(),
      appBar: custom.SearchBar(
        onSubmitted: (query) {
          Provider.of<ProductProvider>(context, listen: false)
              .filterProducts(query);
          Navigator.pushNamed(
            context,
            '/infoProducts',
            arguments: query,
          );
        },
      ),

      body: ListView(
        children: [
          // Carrusel de imágenes

          SizedBox(
            height: MediaQuery.of(context).size.height * 0.3,
            child: ImageCarousel(),
          ),
          const SizedBox(
              height: 10), // Espaciado entre el carrusel y los productos
          const TopSellingCarousel(),

          const SizedBox(height: 10),
          const LeastSellingCarousel(),
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
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent:
                      180, // Cada tarjeta medirá máximo 180px de ancho
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
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
      floatingActionButton: const WhatsAppLogoWidget(),
    );
  }
}
*/

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/product_provider.dart';
import '../widgets/image_carousel.dart';
import '../widgets/least_selling_carousel.dart';
import '../widgets/product_card.dart';
import '../widgets/search_bar.dart' as custom;
import '../widgets/top_selling_carousel.dart';
import '../widgets/whatsapp_logo_widget.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: custom.SearchBar(
        onSubmitted: (query) {
          Provider.of<ProductProvider>(context, listen: false)
              .filterProducts(query);

          Navigator.pushNamed(
            context,
            '/infoProducts',
            arguments: query,
          );
        },
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Provider.of<ProductProvider>(context, listen: false)
              .fetchProducts();
        },
        child: ListView(
          children: [
            // ---------------------------
            // Carrusel principal
            // ---------------------------
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.30,
              child: const ImageCarousel(),
            ),

            const SizedBox(height: 10),

            const TopSellingCarousel(),

            const SizedBox(height: 10),

            const LeastSellingCarousel(),

            const SizedBox(height: 10),

            // ---------------------------
            // GRID DE PRODUCTOS
            // ---------------------------
            Consumer<ProductProvider>(
              builder: (context, productProvider, child) {
                if (productProvider.isLoading) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (productProvider.products.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text('No hay productos disponibles'),
                    ),
                  );
                }

                final visibleProducts =
                    productProvider.products.take(24).toList();

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  itemCount: visibleProducts.length,
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 180,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemBuilder: (_, index) {
                    final product = visibleProducts[index];
                    return ProductCard(product: product);
                  },
                );
              },
            ),

            const SizedBox(height: 20),

            // ---------------------------
            // FOOTER
            // ---------------------------
            Container(
              color: Colors.black,
              padding: const EdgeInsets.all(16.0),
              child: const Center(
                child: Text(
                  '© 2025 UD Electronics. Todos los derechos reservados.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: const WhatsAppLogoWidget(),
    );
  }
}
