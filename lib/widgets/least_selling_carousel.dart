import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/product_provider.dart';
import 'product_card.dart';

class LeastSellingCarousel extends StatelessWidget {
  const LeastSellingCarousel({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        if (provider.isLoadingLeastSelling) {
          return const Center(child: CircularProgressIndicator());
        }

        final products = provider.leastSellingProducts;

        if (products.isEmpty) {
          return const Center(child: Text('No hay productos disponibles.'));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: Text(
                'Promociones',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(
              height: 260,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                itemCount: products.length,
                separatorBuilder: (context, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  return SizedBox(
                    width: 160,
                    child: ProductCard(product: products[index]),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
