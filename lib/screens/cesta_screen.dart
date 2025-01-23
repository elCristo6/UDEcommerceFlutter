import 'package:flutter/material.dart';

import '../widgets/cart_summary.dart';
import '../widgets/product_list.dart';
import '../widgets/search_bar.dart' as custom;

class CestaScreen extends StatelessWidget {
  const CestaScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const custom.SearchBar(),
      body: Row(
        children: [
          // Primera columna: Lista de productos
          const Expanded(
            flex: 2,
            child: ProductList(),
          ),
          // Segunda columna: Resumen de la cesta
          const Expanded(
            flex: 1,
            child: CartSummary(),
          ),
        ],
      ),
    );
  }
}
