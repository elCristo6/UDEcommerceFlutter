import 'package:flutter/material.dart';

import '../widgets/cart_summary.dart';
import '../widgets/product_list.dart';
import '../widgets/search_bar.dart' as custom;

class CestaScreen extends StatelessWidget {
  // ignore: use_super_parameters
  const CestaScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: custom.SearchBar(),
      body: Row(
        children: [
          // Primera columna: Lista de productos
          Expanded(
            flex: 2,
            child: ProductList(),
          ),
          // Segunda columna: Resumen de la cesta
          Expanded(
            flex: 1,
            child: CartSummary(),
          ),
        ],
      ),
    );
  }
}
