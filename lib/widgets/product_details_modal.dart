import 'package:flutter/material.dart';

import '../models/product_model.dart';

class ProductDetailsModal extends StatelessWidget {
  final Product product;

  const ProductDetailsModal({Key? key, required this.product})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título con el nombre del producto
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Descripción del producto
                  Text(
                    product.description,
                    style: const TextStyle(fontSize: 16),
                  ),
                  // Aquí puedes agregar más detalles si lo deseas
                ],
              ),
            ),
          ),
          // Botón de cierre en la esquina superior derecha
          Positioned(
            right: 0,
            top: 0,
            child: IconButton(
              icon: const Icon(Icons.close, size: 24, color: Colors.black),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ),
        ],
      ),
    );
  }
}
