import '../models/product_model.dart';
import '../models/user_model.dart';

class InvoicePayment {
  final String medio;
  final double monto;

  const InvoicePayment({
    required this.medio,
    required this.monto,
  });

  factory InvoicePayment.fromJson(Map<String, dynamic> json) {
    return InvoicePayment(
      medio: json['medio'] as String,
      monto: (json['monto'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'medio': medio,
        'monto': monto,
      };
}

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
  final List<InvoicePayment> pagos;

  Invoice({
    required this.id,
    this.user,
    this.userId,
    required this.products,
    required this.totalAmount,
    required this.medioPago,
    required this.pagaCon,
    required this.cambio,
    this.pagos = const [],
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
      pagos: (json['pagos'] as List<dynamic>? ?? const [])
          .map((pago) => InvoicePayment.fromJson(
                Map<String, dynamic>.from(pago as Map),
              ))
          .toList(),
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
      if (pagos.isNotEmpty)
        'pagos': pagos.map((pago) => pago.toJson()).toList(),
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
    List<InvoicePayment>? pagos,
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
      pagos: pagos ?? this.pagos,
      pagaCon: pagaCon ?? this.pagaCon,
      cambio: cambio ?? this.cambio,
      consecutivo: consecutivo ?? this.consecutivo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static String _normalizarMedio(String medio) {
    final valor = medio.trim().toLowerCase();

    if (valor == 'llave' || valor == 'bre-b' || valor == 'bre-b/llave') {
      return 'bre-b';
    }

    if (valor == 'daviplata' || valor == 'daviplatá') {
      return 'daviplata';
    }

    return valor;
  }

  double montoPorMedio(String medio) {
    final medioBuscado = _normalizarMedio(medio);

    if (pagos.isNotEmpty) {
      return pagos.fold<double>(0.0, (suma, pago) {
        return _normalizarMedio(pago.medio) == medioBuscado
            ? suma + pago.monto
            : suma;
      });
    }

    final medioOriginal = _normalizarMedio(medioPago);
    return medioOriginal != 'mixto' && medioOriginal == medioBuscado
        ? totalAmount
        : 0.0;
  }
}
