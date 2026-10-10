import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/product_provider.dart';
import '../widgets/category_sidebar.dart';
import '../widgets/image_carousel.dart';
import '../widgets/least_selling_carousel.dart';
import '../widgets/search_bar.dart' as custom;
import '../widgets/store_footer.dart';
import '../widgets/top_selling_carousel.dart';
import '../widgets/whatsapp_logo_widget.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<void> _refresh() async {
    await context.read<ProductProvider>().fetchProducts();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 850;

    return Scaffold(
      backgroundColor: const Color(0xFF02060D),
appBar: custom.SearchBar(
  onSubmitted: (query) {
    final normalizedQuery = query.trim();

    if (normalizedQuery.isEmpty) {
      return;
    }

    final provider =
        context.read<ProductProvider>();

    provider.filterProducts(
      normalizedQuery,
    );

    Navigator.pushNamed(
      context,
      '/infoProducts',
      arguments: {
        'type': 'search',
        'query': normalizedQuery,
      },
    );
  },
),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const ClampingScrollPhysics(),
          children: [
            if (isDesktop)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 32, 18),
                child: SizedBox(
                  height: 430,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                    CategorySidebar(
  onCategoryTap: (category) async {
    final authProvider = context.read<AuthProvider>();
    final productProvider = context.read<ProductProvider>();

    // Filtramos por el ID real de la categoría.
    await productProvider.filterProductsByCategory(
      categoryId: category.id,
      categoryName: category.name,
    );

    if (!context.mounted) return;

    // ADMINISTRADOR
    if (authProvider.isAdmin) {
      Navigator.pushNamed(
        context,
        '/infoProducts',
        arguments: {
          'type': 'category',
          'categoryId': category.id,
          'categoryName': category.name,
        },
      );
    } else {
      // VISITANTE O USUARIO SIN PERMISOS ADMINISTRATIVOS
      Navigator.pushNamed(
        context,
        '/search',
        arguments: category.name,
      );
    }
  },
),
                      const SizedBox(width: 18),
                      const Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.all(Radius.circular(14)),
                          child: ImageCarousel(),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              const AspectRatio(
                aspectRatio: 2.7,
                child: ImageCarousel(),
              ),

            const SizedBox(height: 18),
            const TopSellingCarousel(),
            const SizedBox(height: 18),
            const LeastSellingCarousel(),
            const SizedBox(height: 36),
            const StoreFooter(),
          ],
        ),
      ),
      floatingActionButton: const WhatsAppLogoWidget(),
    );
  }
}