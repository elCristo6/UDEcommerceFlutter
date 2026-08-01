
import '../models/product_model.dart';
import '../models/user_model.dart';

class Invoice {
  final String id;
  final User? user;
  final String? userId;
  final List<Product> products;
  final double totalAmount;
  final String medioPago;
  final double pagaCon;
  final double cambio;
  final int? consecutivo;
  final DateTime createdAt;
  final DateTime updatedAt;

  Invoice({
    required this.id,
    this.user,
    this.userId,
    required this.products,
    required this.totalAmount,
    required this.medioPago,
    required this.pagaCon,
    required this.cambio,
    this.consecutivo,
    required this.createdAt,
    required this.updatedAt,
  });

  // ---- Helpers robustos ----
  static String? _extractUserId(dynamic userField) {
    if (userField == null) return null;
    if (userField is String && userField.trim().isNotEmpty) return userField;
    if (userField is Map<String, dynamic>) {
      if (userField['_id'] is String &&
          (userField['_id'] as String).isNotEmpty) {
        return userField['_id'];
      }
      if (userField[r'$oid'] is String &&
          (userField[r'$oid'] as String).isNotEmpty) {
        return userField[r'$oid'];
      }
    }
    return null;
  }

  static DateTime _parseDate(dynamic v) {
    if (v == null) return DateTime.now();
    if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
    if (v is Map<String, dynamic>) {
      final s = v[r'$date']?.toString();
      if (s != null) return DateTime.tryParse(s) ?? DateTime.now();
    }
    return DateTime.now();
  }

  factory Invoice.fromJson(Map<String, dynamic> json) {
    final userField = json['user'];
    return Invoice(
      id: json['_id']?.toString() ?? '',
      user: userField is Map<String, dynamic> ? User.fromJson(userField) : null,
      userId: _extractUserId(userField),
      medioPago: json['medioPago']?.toString() ?? 'Efectivo',
      pagaCon: (json['pagaCon'] as num?)?.toDouble() ?? 0.0,
      cambio: (json['cambio'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      consecutivo: (json['consecutivo'] is int)
          ? json['consecutivo'] as int
          : int.tryParse(json['consecutivo']?.toString() ?? ''),
      products: (json['products'] as List<dynamic>? ?? []).map((item) {
        final productValue = item['product'];
        final int quantity = item['quantity'] as int? ?? 1;
        final double appliedPrice =
            (item['appliedPrice'] as num?)?.toDouble() ?? 0.0;

        String resolvedProductId = '';
        if (productValue is String) {
          resolvedProductId = productValue;
        } else if (productValue is Map<String, dynamic>) {
          if (productValue[r'$oid'] is String) {
            resolvedProductId = productValue[r'$oid'];
          } else if (productValue['_id'] is String) {
            resolvedProductId = productValue['_id'];
          }
        }

        if (productValue is Map<String, dynamic>) {
          return Product.fromJson(productValue).copyWith(
            quantity: quantity,
            price: appliedPrice > 0 ? appliedPrice : null,
          );
        } else {
          return Product(
            id: resolvedProductId.isNotEmpty
                ? resolvedProductId
                : 'Desconocido',
            name: item['name']?.toString() ?? 'Producto sin detalles',
            price: appliedPrice,
            description: item['description']?.toString() ?? '',
            stock: item['stock'] is int ? item['stock'] : 0,
            category: item['category']?.toString() ?? '',
            quantity: quantity,
          );
        }
      }).toList(),
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'user': user != null ? user!.toJson() : userId,
      'products': products.map((product) => product.toJson()).toList(),
      'totalAmount': totalAmount,
      'medioPago': medioPago,
      'pagaCon': pagaCon,
      'cambio': cambio,
      'consecutivo': consecutivo,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Invoice copyWith({
    String? id,
    User? user,
    String? userId,
    List<Product>? products,
    double? totalAmount,
    String? medioPago,
    double? pagaCon,
    double? cambio,
    int? consecutivo,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Invoice(
      id: id ?? this.id,
      user: user ?? this.user,
      userId: userId ?? this.userId,
      products: products ?? this.products,
      totalAmount: totalAmount ?? this.totalAmount,
      medioPago: medioPago ?? this.medioPago,
      pagaCon: pagaCon ?? this.pagaCon,
      cambio: cambio ?? this.cambio,
      consecutivo: consecutivo ?? this.consecutivo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
