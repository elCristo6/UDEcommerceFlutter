import 'package:flutter/material.dart';

import '../models/product_model.dart';
import '../widgets/search_bar.dart' as custom;

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int selectedImageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    return Scaffold(
      appBar: custom.SearchBar(
        onSubmitted: (query) {
          Navigator.pushNamed(context, '/infoProducts', arguments: query);
        },
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔹 Miniaturas a la izquierda
          Container(
            width: 80,
            margin: const EdgeInsets.only(top: 20, left: 8),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: product.images.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedImageIndex = index;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: selectedImageIndex == index
                            ? Colors.blue
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Image.network(
                      product.images[index],
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.broken_image),
                    ),
                  ),
                );
              },
            ),
          ),
          // 🔹 Imagen grande al centro
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.all(20),
              child: AspectRatio(
                aspectRatio: 1,
                child: Image.network(
                  product.images[selectedImageIndex],
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.broken_image, size: 100),
                ),
              ),
            ),
          ),
          // 🔹 Panel lateral derecho
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.only(top: 30, right: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 18),
                      Text(" 5.0 | +5 vendidos"),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '\$ ${product.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text("Envío gratis a todo el país",
                      style: TextStyle(color: Colors.green)),
                  const SizedBox(height: 12),
                  const Text("¡Última disponible!",
                      style: TextStyle(color: Colors.redAccent)),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Comprar ahora
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue),
                      child: const Text("Comprar ahora"),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        // Agregar al carrito
                      },
                      child: const Text("Agregar al carrito"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
