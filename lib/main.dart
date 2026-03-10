import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:provider/provider.dart';

import 'models/product_model.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/invoice_provider.dart';
import 'providers/product_provider.dart';
//import 'screens/UnderConstructionScreen.dart';
import 'screens/cesta_screen.dart';
import 'screens/home_screen.dart';
import 'screens/product_detail_screen.dart';
import 'screens/product_info_list.dart';
import 'screens/sales_screen.dart';

void main() {
  setUrlStrategy(PathUrlStrategy());
  runApp(MyApp());
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (context) => ProductProvider()..fetchProducts()),
        ChangeNotifierProvider(create: (_) => InvoiceProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(
          create: (_) => CartProvider()..initGuest(),
        )
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'UD Electronics: Tienda de Robotica-Electronica-Impresion 3D',
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
        onGenerateRoute: (settings) {
          if (settings.name == '/productDetail') {
            final product = settings.arguments as Product;
            return MaterialPageRoute(
              builder: (_) => ProductDetailScreen(product: product),
            );
          }
          return null;
        },
        //home: const UnderConstructionScreen(),
        initialRoute: '/home', // Ruta inicial
        routes: {
          '/home': (context) => const HomeScreen(), // Pantalla principal
          '/cesta': (context) => const CestaScreen(), // Pantalla de la cesta
          '/sales': (context) => const SalesScreen(),
          '/infoProducts': (context) => const ProductInfoScreen(),
        },
      ),
    );
  }
}
