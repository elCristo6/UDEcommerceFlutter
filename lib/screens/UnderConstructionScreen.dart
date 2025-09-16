import 'package:flutter/material.dart';

import '../widgets/whatsapp_logo_widget.dart'; // Asegúrate de importar el widget creado

class UnderConstructionScreen extends StatelessWidget {
  const UnderConstructionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Imagen de fondo que ocupa toda la pantalla.
          Positioned.fill(
            child: Image.asset(
              'assets/loading.gif',
              fit: BoxFit.cover,
            ),
          ),
          // Botón invisible ubicado en la esquina superior derecha.
          Positioned(
            top: 20,
            right: 20,
            child: Opacity(
              opacity: 0.0, // Lo hace completamente invisible.
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/home');
                },
                child: const Text(
                  'Ir a Inicio',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: const WhatsAppLogoWidget(),
    );
  }
}
