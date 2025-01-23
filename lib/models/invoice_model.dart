import 'user_model.dart'; // Importa el modelo de usuario
import 'product_model.dart'; // Importa el modelo de producto

class Invoice {
  final String id;
  final User user; // Usuario asociado a la factura
  final List<Product> products; // Lista de productos asociados
  final double totalAmount; // Monto total de la factura
  final DateTime date; // Fecha de emisión de la factura

  Invoice({
    required this.id,
    required this.user,
    required this.products,
    required this.totalAmount,
    required this.date,
  });

  // Método para deserializar desde JSON
  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['_id'] ?? '',
      user: User.fromJson(json['user']),
      products: (json['products'] as List)
          .map((product) => Product.fromJson(product))
          .toList(),
      totalAmount: json['totalAmount']?.toDouble() ?? 0.0,
      date: DateTime.parse(json['date']),
    );
  }

  // Método para serializar a JSON
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'user': user.toJson(),
      'products': products.map((product) => product.toJson()).toList(),
      'totalAmount': totalAmount,
      'date': date.toIso8601String(),
    };
  }
}
