import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/product_provider.dart';
import '../widgets/image_carousel.dart';
import '../widgets/product_card.dart';
import '../widgets/search_bar.dart'
    as custom; // Usar alias para el widget SearchBar

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const custom.SearchBar(), // Usar el alias custom.SearchBar
      body: Column(
        children: [
          //CategoryBar(categories: categories), // Añadir el widget CategoryBar
          Container(
            height: MediaQuery.of(context).size.height *
                0.3, // 40% de la altura de la pantalla
            child: ImageCarousel(),
          ),
          Expanded(
            child: Consumer<ProductProvider>(
              builder: (context, productProvider, child) {
                if (productProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (productProvider.products.isEmpty) {
                  return const Center(child: Text('No products available'));
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(10.0),
                  itemCount: productProvider.products.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 3 / 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemBuilder: (context, index) {
                    final product = productProvider.products[index];
                    return ProductCard(product: product);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
