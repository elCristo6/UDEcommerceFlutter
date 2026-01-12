/*import 'product_model.dart';

class CartItem {
  final Product product;
  final int quantity;
  final int appliedPrice;

  CartItem({
    required this.product,
    required this.quantity,
    required this.appliedPrice,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      product: Product.fromJson(json['product']),
      quantity: json['quantity'],
      appliedPrice: json['appliedPrice'],
    );
  }
}

class Cart {
  final String id;
  final String user;
  final List<CartItem> items;
  final DateTime updatedAt;

  Cart({
    required this.id,
    required this.user,
    required this.items,
    required this.updatedAt,
  });

  factory Cart.fromJson(Map<String, dynamic> json) {
    return Cart(
      id: json['_id'],
      user: json['user'],
      items: (json['items'] as List)
          .map((item) => CartItem.fromJson(item))
          .toList(),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
  factory Cart.empty() {
    return Cart(
      id: 'local',
      user: 'guest',
      items: [],
      updatedAt: DateTime.now(),
    );
  }
}*/

// models/cart_model.dart
import '../models/product_model.dart';

class CartItem {
  final Product product;
  final int quantity;
  final int appliedPrice;

  CartItem({
    required this.product,
    required this.quantity,
    required this.appliedPrice,
  });

  /// 🔥 Necesario para actualizar cantidades o appliedPrice
  CartItem copyWith({
    Product? product,
    int? quantity,
    int? appliedPrice,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      appliedPrice: appliedPrice ?? this.appliedPrice,
    );
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      product: Product.fromJson(json['product']),
      quantity: json['quantity'] ?? 1,
      appliedPrice: json['appliedPrice'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product': product.toJson(),
      'quantity': quantity,
      'appliedPrice': appliedPrice,
    };
  }
}

class Cart {
  final String id;
  final String user;
  final List<CartItem> items;
  final DateTime updatedAt;

  Cart({
    required this.id,
    required this.user,
    required this.items,
    required this.updatedAt,
  });

  factory Cart.fromJson(Map<String, dynamic> json) {
    return Cart(
      id: json['_id'] ?? '',
      user: json['user'] ?? '',
      items: (json['items'] as List<dynamic>)
          .map((item) => CartItem.fromJson(item))
          .toList(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'user': user,
      'items': items.map((item) => item.toJson()).toList(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Para limpiar rápido en provider
  factory Cart.empty() {
    return Cart(
      id: '',
      user: '',
      items: [],
      updatedAt: DateTime.now(),
    );
  }
}
