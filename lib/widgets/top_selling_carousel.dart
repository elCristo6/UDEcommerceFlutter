import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/product_provider.dart';
import 'product_card.dart';

class TopSellingCarousel extends StatelessWidget {
  const TopSellingCarousel({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductProvider>(
      builder: (context, provider, child) {
        if (provider.isLoadingTopSelling) {
          return const Center(child: CircularProgressIndicator());
        }

        final products = provider.topSellingProducts;

        if (products.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                'Más vendidos',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(
              height: 250,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: products.length,
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
