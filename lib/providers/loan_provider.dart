import 'package:flutter/material.dart';
import '../models/loan_model.dart';
import '../services/loan_service.dart';

class LoanProvider with ChangeNotifier {
  final LoanService loanService;

  List<LoanClient> _stores = [];
  List<LoanModel> _activeLoans = [];
  bool _isLoading = false;

  LoanProvider({required this.loanService});

  List<LoanClient> get stores => _stores;
  List<LoanModel> get activeLoans => _activeLoans;
  bool get isLoading => _isLoading;

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
}