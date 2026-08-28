import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/loan_provider.dart';
import '../providers/auth_provider.dart';
import '../models/loan_model.dart';
import '../widgets/search_bar.dart' as custom;
import '../widgets/loan_product_list.dart';
import '../widgets/loan_summary_card.dart';

class LoansMainScreen extends StatefulWidget {
  const LoansMainScreen({Key? key}) : super(key: key);

  @override
  State<LoansMainScreen> createState() => _LoansMainScreenState();
}

class _LoansMainScreenState extends State<LoansMainScreen> with TickerProviderStateMixin {
  TabController? _tabController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final token = Provider.of<AuthProvider>(context, listen: false).token ?? '';
      Provider.of<LoanProvider>(context, listen: false).fetchStoresAndLoans(token);
    });
  }

  void _syncTabController(int length) {
    if (length == 0) return;

    if (_currentIndex >= length) {
      _currentIndex = length - 1;
    }

    if (_tabController == null || _tabController!.length != length) {
      _tabController?.dispose();
      _tabController = TabController(
        length: length,
        vsync: this,
        initialIndex: _currentIndex,
      );

      _tabController!.addListener(() {
        if (!_tabController!.indexIsChanging) {
          _currentIndex = _tabController!.index;
        }
      });
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  // =========================================================
  // MODAL PARA CREAR UN NUEVO CLIENTE "STORE"
  // =========================================================
  void _showAddStoreDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final detailsCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.storefront, color: Colors.blue),
              SizedBox(width: 8),
              Text('Nuevo Local Comercial'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del Local / Cliente',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: detailsCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Detalles (ej: Local 103 - CC)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancelar', style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('Guardar'),
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final phone = phoneCtrl.text.trim();
                final details = detailsCtrl.text.trim();

                if (name.isEmpty || phone.isEmpty) {
                  ScaffoldMessenger.of(dialogCtx).showSnackBar(
                    const SnackBar(content: Text('Por favor completa nombre y teléfono')),
                  );
                  return;
                }

                final token = context.read<AuthProvider>().token ?? '';

                // Llamamos a la función del provider
                final success = await context.read<LoanProvider>().addStore(
                  token,
                  name: name,
                  phone: phone,
                  detalles: details,
                );

                if (dialogCtx.mounted) {
                  Navigator.pop(dialogCtx);
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('¡Cliente "$name" creado exitosamente!')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Error al crear el usuario. Verifica los datos.')),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }
// =========================================================
  // MODAL PARA CONFIRMAR ELIMINACIÓN DE UN LOCAL
  // =========================================================
  void _showDeleteStoreDialog(BuildContext context, String storeId, String storeName) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red),
              SizedBox(width: 8),
              Text('Eliminar Local'),
            ],
          ),
          content: Text('¿Estás seguro de que deseas eliminar permanentemente el local "$storeName"? Esta acción no se puede deshacer.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                final token = context.read<AuthProvider>().token ?? '';
                final success = await context.read<LoanProvider>().deleteStore(token, storeId);
                
                if (dialogCtx.mounted) {
                  Navigator.pop(dialogCtx);
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Local "$storeName" eliminado con éxito.')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Error al eliminar el local.')),
                    );
                  }
                }
              },
              child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    return Consumer<LoanProvider>(
      builder: (context, loanProvider, child) {
        if (loanProvider.isLoading && loanProvider.stores.isEmpty) {
          return const Scaffold(
            appBar: custom.SearchBar(),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final stores = loanProvider.stores;

        if (stores.isNotEmpty) {
          _syncTabController(stores.length);
        }

        return Scaffold(
          backgroundColor: Colors.grey[200],
          appBar: const custom.SearchBar(),
          body: stores.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.store_outlined, size: 80, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        'No hay locales registrados con rol "store".',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Crear Primer Local Comercial'),
                        onPressed: () => _showAddStoreDialog(context),
                      )
                    ],
                  ),
                )
              : Column(
                  children: [
                    // ==========================================
                    // BARRA DE PESTAÑAS + BOTÓN MÁS EN LA DERECHA
                    // ==========================================
                    Material(
                      color: Colors.white,
                      child: Row(
                        children: [
                          Expanded(
                            child: TabBar(
                              controller: _tabController,
                              isScrollable: true,
                              labelColor: Colors.blue,
                              unselectedLabelColor: Colors.grey,
                              indicatorColor: Colors.blue,
                              labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                             tabs: stores.map((store) {
  final activeLoan = loanProvider.getActiveLoanForClient(store.id);
  final hasActiveLoan = activeLoan != null && activeLoan.items.any((i) => i.pendingQty > 0);

  return Tab(
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.storefront,
          color: hasActiveLoan ? Colors.orange : Colors.grey,
        ),
        const SizedBox(width: 8),
        Text(store.name),
        if (hasActiveLoan) ...[
          const SizedBox(width: 6),
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.redAccent,
              shape: BoxShape.circle,
            ),
          )
        ],
        // ✅ AQUÍ ESTÁ LA NUEVA EQUIS 'X'
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () {
             // Previene que se seleccione la pestaña si solo queríamos borrarla
             _showDeleteStoreDialog(context, store.id, store.name);
          },
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.close, size: 16, color: Colors.red),
          ),
        ),
      ],
    ),
  );
}).toList(),
                            ),
                          ),

                          // ✅ BOTÓN (+) PARA AGREGAR NUEVO LOCAL/STORE DIRECTAMENTE
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () => _showAddStoreDialog(context),
                              child: Container(
                                padding: const EdgeInsets.all(8.0),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.add_business,
                                  color: Colors.blue,
                                  size: 22,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ==========================================
                    // CONTENIDO DE LAS PESTAÑAS (2 COLUMNAS)
                    // ==========================================
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: stores.map((store) {
                          final activeLoan = loanProvider.getActiveLoanForClient(store.id);

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch, 
                            children: [
                              Expanded(
                                flex: 2,
                                child: LoanProductList(
                                  loan: activeLoan,
                                  client: store,
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: LoanSummaryCard(
                                  loan: activeLoan,
                                  client: store,
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}