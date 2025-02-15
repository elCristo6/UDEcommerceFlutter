import 'package:flutter/material.dart';

class InvoiceListItem extends StatelessWidget {
  const InvoiceListItem({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          // "crossAxisAlignment: CrossAxisAlignment.start"
          // si quieres alinear todo arriba
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ================== COLUMNA 1 ==================
            Expanded(
              flex: 1, // Ajusta según el espacio que desees
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Factura (más pequeño)
                  Text(
                    "Factura 2132",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Nombre en negrita
                  const Text(
                    "Nombre: Ardurobotic",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // TOTAL en negrita
                  const Text(
                    "TOTAL: \$50.000",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // ================== COLUMNA 2 ==================
            Expanded(
              flex: 3, // Más ancho para que quepan varios productos
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text("- Motor N20"),
                  Text("- Elevador xl4015 ..."),
                  // Agrega más líneas si lo deseas
                ],
              ),
            ),

            // ================== COLUMNA 3 ==================
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text("Paga con: 100.000"),
                  Text("Cambio: 50.000"),
                ],
              ),
            ),

            // ================== COLUMNA 4 (Íconos) ==================
            Expanded(
              flex: 1,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.print),
                    iconSize: 30.0,
                    onPressed: () {
                      // Lógica para imprimir
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    iconSize: 30.0,
                    onPressed: () {
                      // Lógica para eliminar
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    iconSize: 30.0,
                    onPressed: () {
                      // Lógica para editar
                    },
                  ),
                ],
              ),
            ),

            // ================== COLUMNA 5 (Medio de pago) ==================
            Expanded(
              flex: 1,
              child: Center(
                child: Text(
                  "Nequi", // O "Efectivo", "Daviplata", etc.
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
