import 'package:flutter/material.dart';
import '../models/loan_model.dart';
import '../services/loan_service.dart';

class LoanProvider with ChangeNotifier {
  final LoanService loanService;

  List<LoanClient> _stores = [];
  List<LoanModel> _activeLoans = [];
  bool _isLoading = false;

  final Map<String, bool> _itemSelections = {};

  LoanProvider({required this.loanService});

  List<LoanClient> get stores => _stores;
  List<LoanModel> get activeLoans => _activeLoans;
  bool get isLoading => _isLoading;

  // ✅ MÉTODOS PARA CHECKBOXES
  bool isItemSelected(String itemId) {
    return _itemSelections[itemId] ?? true; // Por defecto todos están seleccionados
  }

  void toggleItemSelection(String itemId, bool value) {
    _itemSelections[itemId] = value;
    notifyListeners(); // Actualiza la lista y el resumen al instante
  }

  Future<void> fetchStoresAndLoans(String token) async {
    if (token.isEmpty) return;
    
    _isLoading = true;
    notifyListeners();
    try {
      _stores = await loanService.getStoreClients(token);
      _activeLoans = await loanService.getActiveLoans(token);
    } catch (e) {
      debugPrint('Error cargando datos de préstamos: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  LoanModel? getActiveLoanForClient(String clientId) {
    try {
      return _activeLoans.firstWhere((loan) => loan.client?.id == clientId);
    } catch (_) {
      return null;
    }
  }

  Future<bool> returnProduct(String token, String loanId, String itemId, int qty) async {
    final success = await loanService.returnItem(token, loanId: loanId, itemId: itemId, qty: qty);
    if (success) await fetchStoresAndLoans(token);
    return success;
  }
  Future<bool> updateItemPrice(
  String token, {
  required String loanId,
  required String itemId,
  required double newPrice,
}) async {
  try {
    final success = await loanService.updateItemPrice(
      token,
      loanId: loanId,
      itemId: itemId,
      newPrice: newPrice,
    );
    if (success) {
      notifyListeners();
    }
    return success;
  } catch (e) {
    debugPrint("Error al actualizar precio del ítem: $e");
    return false;
  }
}

// ✅ CORREGIDO: Eliminamos el parámetro customItems de aquí también
  Future<bool> finalizeAndBill(String token, {
    required String loanId,
    required String medioPago,
    required double pagaCon,
    required List<String> selectedItemIds,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Llamamos al service solo con los 3 datos que necesita la "caja negra"
      final success = await loanService.finalizeLoan(
        token,
        loanId: loanId,
        medioPago: medioPago,
        pagaCon: pagaCon,
        selectedItemIds: selectedItemIds,
      );

      if (success) {
        // Refrescamos la lista local para que desaparezca de los "Activos"
        await fetchStoresAndLoans(token);
      }
      return success;
    } catch (e) {
      print('Error al finalizar el préstamo a factura: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

Future<bool> addStore(String token, {
    required String name,
    required String phone,
    required String detalles,
  }) async {
    final success = await loanService.createStore(
      token,
      name: name,
      phone: phone,
      detalles: detalles,
    );
    if (success) {
      // Recargamos clientes y préstamos para refrescar la lista de pestañas automáticamente
      await fetchStoresAndLoans(token);
    }
    return success;
  }
  Future<bool> deleteStore(String token, String storeId) async {
    // 1. Llama al servicio (que ya tiene http y baseUrl)
    final success = await loanService.deleteStore(token, storeId);
    
    // 2. Si el servidor respondió que todo bien, lo borramos de la pantalla
    if (success) {
      stores.removeWhere((s) => s.id == storeId);
      notifyListeners(); 
    }
    return success;
  }
}
