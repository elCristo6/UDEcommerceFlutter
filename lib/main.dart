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
import 'screens/product_search_screen.dart';
import 'screens/sales_screen.dart';
import 'screens/stock_screen.dart';
import 'screens/loans_main_screen.dart';

void main() {
  setUrlStrategy(PathUrlStrategy());
  runApp(const MyApp());
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => InvoiceProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()..initGuest()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()..fetchCategories()),
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
          title: 'UD Electronics: Tienda de Robótica, Electrónica e Impresión 3D',
          theme: ThemeData(
            primarySwatch: Colors.deepPurple,
            visualDensity: VisualDensity.adaptivePlatformDensity,
            fontFamily: 'Raleway',
            textTheme: const TextTheme(
              displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              bodyLarge: TextStyle(fontSize: 16),
            ),
          ),
          initialRoute: '/home',
          onGenerateRoute: (settings) {
            final routeName = settings.name ?? '';
            final authProvider = Provider.of<AuthProvider>(
              navigatorKey.currentContext!,
              listen: false,
            );

            // 1. Pantallas Públicas Básicas
            if (routeName == '/home' || routeName == '/' || routeName.isEmpty) {
              return MaterialPageRoute(settings: settings, builder: (_) => const HomeScreen());
            }

            if (routeName == '/cesta') {
              return MaterialPageRoute(settings: settings, builder: (_) => const CestaScreen());
            }

            if (routeName == '/sales') {
              return MaterialPageRoute(settings: settings, builder: (_) => const SalesScreen());
            }
            if (routeName == '/search') {
              final query = settings.arguments as String? ?? '';
              return MaterialPageRoute(
                settings: settings,
                builder: (_) => ProductSearchScreen(searchQuery: query),
              );
            }
            // Ruta de información pública / catálogo general
            if (routeName == '/infoProducts') {
              return MaterialPageRoute(settings: settings, builder: (_) => const ProductInfoScreen());
            }

            // 2. 🛡️ PROTECCIÓN DE RUTAS ADMINISTRATIVAS (/stock y /loans)
            if (routeName == '/stock') {
              if (!authProvider.isAdmin) {
                // Si no es admin o el token expiró, redirige al catálogo público
                return MaterialPageRoute(settings: settings, builder: (_) => const ProductInfoScreen());
              }
              return MaterialPageRoute(settings: settings, builder: (_) => const StockScreen());
            }

            if (routeName == '/loans') {
              if (!authProvider.isAdmin) {
                return MaterialPageRoute(settings: settings, builder: (_) => const HomeScreen());
              }
              return MaterialPageRoute(settings: settings, builder: (_) => const LoansMainScreen());
            }

            // 3. Detalle de Producto
            if (routeName == '/productDetail') {
              final product = settings.arguments as Product;
              return MaterialPageRoute(settings: settings, builder: (_) => ProductDetailScreen(product: product));
            }

            if (routeName.contains('.')) {
              return null;
            }

            final cleanSlug = routeName.startsWith('/') ? routeName.substring(1) : routeName;

            return MaterialPageRoute(
              settings: settings,
              builder: (_) => ProductDetailScreen(productSlug: cleanSlug),
            );
          },
        ),
      ),
    );
  }
}