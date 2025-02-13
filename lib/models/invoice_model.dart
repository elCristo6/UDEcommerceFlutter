import '../models/product_model.dart';
import '../models/user_model.dart';

class Invoice {
  final String id;
  final User? user; // Usuario completo, si está disponible
  final String?
      userId; // Solo el ID del usuario, si el servidor envía solo un ID
  final List<Product> products;
  final double totalAmount;
  final String medioPago;
  final double pagaCon;
  final double cambio;
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
    required this.createdAt,
    required this.updatedAt,
  });
  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['_id'] ?? '',
      user: json['user'] is Map<String, dynamic> // Si `user` es un objeto
          ? User.fromJson(json['user'])
          : null, // Si no es un objeto, se mantiene en `null`
      userId: json['user'] is String // Si `user` es un `String` (ID)
          ? json['user']
          : null, // Si no es un String, se mantiene en `null`
      medioPago: json['medioPago'] ?? 'Efectivo',
      pagaCon: (json['pagaCon'] as num?)?.toDouble() ?? 0.0,
      cambio: (json['cambio'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      products: (json['products'] as List<dynamic>?)
              ?.map((product) =>
                  Product.fromJson(product as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'user': user != null ? user!.toJson() : userId, // Enviar objeto o ID
      'products': products.map((product) => product.toJson()).toList(),
      'totalAmount': totalAmount,
      'medioPago': medioPago,
      'pagaCon': pagaCon,
      'cambio': cambio,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
