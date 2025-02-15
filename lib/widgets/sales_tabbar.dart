import 'package:flutter/material.dart';

class SalesTabBar extends StatelessWidget {
  final TabController tabController;

  const SalesTabBar({
    Key? key,
    required this.tabController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: TabBar(
        controller: tabController,
        // Color de texto cuando está seleccionada la pestaña
        labelColor: Colors.black,
        // Color de texto cuando está sin seleccionar
        unselectedLabelColor: Colors.grey,

        // Estilos:
        labelStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold, // Texto en negrita al seleccionar
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal, // Texto normal si no está seleccionado
        ),

        tabs: const [
          Tab(text: "Ventas HOY"),
          Tab(text: "Ventas Mensuales"),
          Tab(text: "Ventas Anuales"),
        ],
      ),
    );
  }
}
