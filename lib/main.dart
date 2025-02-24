import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/invoice_provider.dart';
import 'providers/product_provider.dart';
import 'screens/cesta_screen.dart';
import 'screens/home_screen.dart';
import 'screens/sales_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (context) => ProductProvider()..fetchProducts()),
        ChangeNotifierProvider(create: (_) => InvoiceProvider()),
      ],
      child: MaterialApp(
        title: 'UD Electronics',
        theme: ThemeData(
          primarySwatch: Colors.deepPurple,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          fontFamily: 'Raleway',
          textTheme: const TextTheme(
            headlineLarge: TextStyle(
                fontSize: 32.0,
                fontWeight: FontWeight.bold), // Usar la nomenclatura correcta
            bodyLarge:
                TextStyle(fontSize: 16.0), // Usar la nomenclatura correcta
          ),
        ),

        //home: const UnderConstructionScreen(),
        initialRoute: '/home', // Ruta inicial
        routes: {
          '/home': (context) => const HomeScreen(), // Pantalla principal
          '/cesta': (context) => const CestaScreen(), // Pantalla de la cesta
          '/sales': (context) => const SalesScreen(),
        },
      ),
    );
  }
}
