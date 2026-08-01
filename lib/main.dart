// main.dart
/*import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:provider/provider.dart';

import 'models/product_model.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/invoice_provider.dart';
import 'providers/product_provider.dart';
import 'screens/stock_screen.dart'; 
//import 'screens/UnderConstructionScreen.dart';
import 'screens/cesta_screen.dart';
import 'screens/home_screen.dart';
import 'screens/product_detail_screen.dart';
import 'screens/product_info_list.dart';
import 'screens/sales_screen.dart';
import 'providers/category_provider.dart';

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
        ),
        ChangeNotifierProvider(
        create: (_) => CategoryProvider()..fetchCategories(),
        ),
      ],
      child: GestureDetector(
        onTap: () {
          // ✅ SOLUCIÓN GLOBAL: Si el usuario hace clic en cualquier parte de la pantalla,
          // quitamos el foco del teclado, forzando al buscador a replegarse de inmediato.
          final currentFocus = FocusScope.of(context);
          if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
            FocusManager.instance.primaryFocus?.unfocus();
          }
        },
        child: MaterialApp(
          navigatorKey: navigatorKey,
          title: 'UD Electronics: Tienda de Robotica-Electronica-Impresion 3D',
          theme: ThemeData(
            primarySwatch: Colors.deepPurple,
            visualDensity: VisualDensity.adaptivePlatformDensity,
            fontFamily: 'Raleway',
            textTheme: const TextTheme(
              displayLarge: TextStyle(fontSize: 32.0, fontWeight: FontWeight.bold),
              bodyLarge: TextStyle(fontSize: 16.0),
            ),
          ),
          
          // Saneamos la ruta inicial de arranque
          initialRoute: '/home',

          // Centralizamos TODO el enrutamiento aquí para evitar colisiones de rutas web
          onGenerateRoute: (settings) {
            final String routeName = settings.name ?? '';

            // 1. Procesamos las pantallas estáticas fijas del sistema
            if (routeName == '/home' || routeName == '/' || routeName.isEmpty) {
              return MaterialPageRoute(settings: settings, builder: (_) => const HomeScreen());
            }
            if (routeName == '/cesta') {
              return MaterialPageRoute(settings: settings, builder: (_) => const CestaScreen());
            }
            if (routeName == '/sales') {
              return MaterialPageRoute(settings: settings, builder: (_) => const SalesScreen());
            }
            if (routeName == '/infoProducts') {
              return MaterialPageRoute(settings: settings, builder: (_) => const ProductInfoScreen());
            }
            if (routeName == '/stock') {
              return MaterialPageRoute(settings: settings, builder: (_) => const StockScreen());
            }

            // Compatibilidad por si alguna tarjeta vieja envía el objeto clásico
            if (routeName == '/productDetail') {
              final product = settings.arguments as Product;
              return MaterialPageRoute(
                settings: settings,
                builder: (_) => ProductDetailScreen(product: product),
              );
            }

            // Ignoramos solicitudes de archivos o recursos con punto (.)
            if (routeName.contains('.')) return null;

            // 2. Fallback Maestro: Cualquier otra palabra en la raíz es tratada como un Slug Puro de producto
            final cleanSlug = routeName.startsWith('/') ? routeName.substring(1) : routeName;

            return MaterialPageRoute(
              settings: settings, // Mantiene la URL hermosa reflejada en la barra de Chrome
              builder: (_) => ProductDetailScreen(productSlug: cleanSlug),
            );
          },
        ),
      ), // ✅ CORREGIDO: Añadido paréntesis de cierre correspondiente al MultiProvider
    );
  }
}*/

// main.dart
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:provider/provider.dart';

import 'models/product_model.dart';
import 'config/api_config.dart';
import 'services/loan_service.dart';
import 'providers/loan_provider.dart';

import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/category_provider.dart';
import 'providers/invoice_provider.dart';
import 'providers/product_provider.dart';

import 'screens/cesta_screen.dart';
import 'screens/home_screen.dart';
import 'screens/product_detail_screen.dart';
import 'screens/product_info_list.dart';
import 'screens/sales_screen.dart';
import 'screens/stock_screen.dart';
import 'screens/loans_main_screen.dart';

void main() {
  setUrlStrategy(PathUrlStrategy());
  runApp(const MyApp());
}

final GlobalKey<NavigatorState> navigatorKey =
    GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ProductProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => InvoiceProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => CartProvider()..initGuest(),
        ),
        ChangeNotifierProvider(
          create: (_) => CategoryProvider()..fetchCategories(),
        ),
        ChangeNotifierProvider(
          create: (_) => LoanProvider(
            loanService: LoanService(baseUrl: ApiConfig.baseUrl),
          ),
        ),
      ],
      child: GestureDetector(
        onTap: () {
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: MaterialApp(
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          title:
              'UD Electronics: Tienda de Robótica, Electrónica e Impresión 3D',
          theme: ThemeData(
            primarySwatch: Colors.deepPurple,
            visualDensity: VisualDensity.adaptivePlatformDensity,
            fontFamily: 'Raleway',
            textTheme: const TextTheme(
              displayLarge: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
              bodyLarge: TextStyle(fontSize: 16),
            ),
          ),
          initialRoute: '/home',
          onGenerateRoute: (settings) {
            final routeName = settings.name ?? '';

            if (routeName == '/home' ||
                routeName == '/' ||
                routeName.isEmpty) {
              return MaterialPageRoute(
                settings: settings,
                builder: (_) => const HomeScreen(),
              );
            }

            if (routeName == '/cesta') {
              return MaterialPageRoute(
                settings: settings,
                builder: (_) => const CestaScreen(),
              );
            }

            if (routeName == '/sales') {
              return MaterialPageRoute(
                settings: settings,
                builder: (_) => const SalesScreen(),
              );
            }

            if (routeName == '/infoProducts') {
              return MaterialPageRoute(
                settings: settings,
                builder: (_) => const ProductInfoScreen(),
              );
            }

            if (routeName == '/stock') {
              return MaterialPageRoute(
                settings: settings,
                builder: (_) => const StockScreen(),
              );
            }
            if (routeName == '/loans') {
              return MaterialPageRoute(
                settings: settings,
                builder: (_) =>  LoansMainScreen(),
              );
            }
            if (routeName == '/productDetail') {
              final product = settings.arguments as Product;

              return MaterialPageRoute(
                settings: settings,
                builder: (_) => ProductDetailScreen(
                  product: product,
                ),
              );
            }

            if (routeName.contains('.')) {
              return null;
            }

            final cleanSlug = routeName.startsWith('/')
                ? routeName.substring(1)
                : routeName;

            return MaterialPageRoute(
              settings: settings,
              builder: (_) => ProductDetailScreen(
                productSlug: cleanSlug,
              ),
            );
          },
        ),
      ),
    );
  }
}