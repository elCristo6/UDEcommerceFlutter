// loans_main_screen.dart
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

  void _syncTabController(int storesLength) {
    if (storesLength == 0) return;

    if (_currentIndex >= storesLength) {
      _currentIndex = storesLength - 1;
    }

    if (_tabController == null || _tabController!.length != storesLength) {
      _tabController?.dispose();
      _tabController = TabController(
        length: storesLength,
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
        final dummyClient = LoanClient(id: '', name: 'Nueva Cesta', phone: '', detalles: '');

        if (stores.isNotEmpty) {
          _syncTabController(stores.length);
        }

        return Scaffold(
          backgroundColor: Colors.grey[200],
          appBar: const custom.SearchBar(),
          body: stores.isEmpty
              ? Column(
                  children: [
                    Container(
                      color: Colors.white,
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      child: const Center(
                        child: Text(
                          'Sin Locales Registrados',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            flex: 2, 
                            child: LoanProductList(
                              loan: null, 
                              client: dummyClient,
                              onItemPriceChanged: () => setState(() {}),
                            ),
                          ),
                          Expanded(flex: 1, child: LoanSummaryCard(loan: null, client: dummyClient)),
                        ],
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    Material(
                      color: Colors.white,
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
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
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
                                  // ✅ Conecta el refresco entre componentes
                                  onItemPriceChanged: () => setState(() {}),
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