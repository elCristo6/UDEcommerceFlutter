import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/invoice_model.dart';
import '../providers/invoice_provider.dart';
import '../widgets/invoice_list_item.dart';
import '../widgets/sales_footer.dart';
import '../widgets/sales_tabbar.dart';
import '../widgets/search_bar.dart' as custom;

class SalesScreen extends StatefulWidget {
  const SalesScreen({Key? key}) : super(key: key);

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Tenemos 3 pestañas: HOY, Mensuales, Anuales
    _tabController = TabController(length: 3, vsync: this);
    Future.microtask(() {
      Provider.of<InvoiceProvider>(context, listen: false).fetchTodaysSales();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 1) Fondo gris para toda la pantalla
      backgroundColor: Colors.grey[200],

      // 2) AppBar = SearchBar personalizada
      appBar: custom.SearchBar(),

      // 3) Contenido principal
      body: Column(
        children: [
          // TabBar
          SalesTabBar(tabController: _tabController),

          // TabBarView con 3 pestañas
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildVentasHoy(),
                _buildVentasMensuales(),
                _buildVentasAnuales(),
              ],
            ),
          ),
        ],
      ),

      // 4) Footer “flotante” como bottomNavigationBar
      bottomNavigationBar: Container(
        // Le das un margen para que no quede pegado
        margin: const EdgeInsets.all(8.0),
        // Bordes redondeados arriba, fondo azul (lo maneja SalesFooter)
        decoration: const BoxDecoration(
          color: Colors.blue, // Por si SalesFooter no aplica su color
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(10),
            topRight: Radius.circular(10),
          ),
        ),
        // Dentro de este contenedor, pones el SalesFooter
        child: const SalesFooter(),
      ),
    );
  }

  // =====================================
  // Pestaña: Ventas de HOY
  // =====================================
  Widget _buildVentasHoy() {
    return Consumer<InvoiceProvider>(
      builder: (context, invoiceProvider, child) {
        // Si aún no se han cargado las ventas de hoy, muestra un indicador
        if (invoiceProvider.todaysSales.isEmpty) {
          return const Center(child: Text("No hay ventas para hoy."));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: invoiceProvider.todaysSales.length,
          itemBuilder: (context, index) {
            final Invoice invoice = invoiceProvider.todaysSales[index];
            return InvoiceListItem(invoice: invoice);
          },
        );
      },
    );
  }

  // =====================================
  // Pestaña: Ventas Mensuales
  // =====================================
  Widget _buildVentasMensuales() {
    return Container(
      color: Colors.white,
      child: ListView(
        padding: const EdgeInsets.all(8.0),
        children: const [
          //InvoiceListItem(),
          //InvoiceListItem(),
        ],
      ),
    );
  }

  // =====================================
  // Pestaña: Ventas Anuales
  // =====================================
  Widget _buildVentasAnuales() {
    return Container(
      color: Colors.white,
      child: ListView(
        padding: const EdgeInsets.all(8.0),
        children: const [
          //InvoiceListItem(),
        ],
      ),
    );
  }
}
