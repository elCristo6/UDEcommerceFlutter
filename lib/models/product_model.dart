class Product {
  final String id;
  final String name;
  final double price;
  final String description;
  final List<int> box;
  final String imageUrl;
  final int stock;
  final String category;
  int quantity;
  final DateTime? updatedAt;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    this.box = const [],
    required this.imageUrl,
    required this.stock,
    required this.category,
    this.quantity = 1,
    this.updatedAt,
  });

  // Método copyWith para crear una copia modificada del producto
  Product copyWith({
    String? id,
    String? name,
    double? price,
    String? description,
    String? imageUrl,
    int? stock,
    String? category,
    int? quantity,
    List<int>? box,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      stock: stock ?? this.stock,
      box: box ?? this.box,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      price: (json['price'] != null)
          ? double.tryParse(json['price'].toString()) ?? 0.0
          : 0.0,
      description: json['description'] ?? '',
      box: json['box'] != null
          ? (json['box'] as List<dynamic>)
              .where((element) => element != null)
              .map((e) => int.tryParse(e.toString()) ?? 0)
              .toList()
          : [],
      imageUrl: json['imageUrl'] ?? '',
      stock: json['stock'] != null
          ? int.tryParse(json['stock'].toString()) ?? 0
          : 0,
      category: json['category'] ?? 'Unknown',
      quantity: json['quantity'] != null
          ? int.tryParse(json['quantity'].toString()) ?? 1
          : 1,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'price': price,
      'description': description,
      'box': box,
      'imageUrl': imageUrl,
      'stock': stock,
      'category': category,
      'quantity': quantity,
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
