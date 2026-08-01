import 'dart:typed_data';

class Product {
  final String id;
  final String name;
  final double price;
  final String description;
  final List<int> box;
  final List<String> images;
  final int stock;
  final String category;
  final List<String> categories;
  final String slug;
  int quantity;
  final DateTime? updatedAt;
  

  Uint8List? cachedImageBytes;  // bytes precargados de la miniatura

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    this.box = const [],
    this.images = const [],
    required this.stock,
    required this.category,
    this.categories = const [],
    this.slug = '',
    this.quantity = 1,
    this.updatedAt,
    this.cachedImageBytes, // nuevo
  });

  // Método copyWith para crear una copia modificada del producto
  Product copyWith({
    String? id,
    String? name,
    double? price,
    String? description,
    int? stock,
    String? category,
    String? slug,
    int? quantity,
    List<int>? box,
    List<String>? images,
    DateTime? updatedAt,
    List<String>? categories,
    Uint8List? cachedImageBytes,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      description: description ?? this.description,
      stock: stock ?? this.stock,
      box: box ?? this.box,
      images: images ?? this.images,
      category: category ?? this.category,
      categories: categories ?? this.categories,
      slug: slug ?? this.slug,
      quantity: quantity ?? this.quantity,
      updatedAt: updatedAt ?? this.updatedAt,
      cachedImageBytes: cachedImageBytes ?? this.cachedImageBytes,
    );
  }

   factory Product.fromJson(Map<String, dynamic> json) {
    // 1. Capturamos el nombre para usarlo de respaldo si el slug viene ausente o vacío
    final String productName = json['name'] ?? '';
    
    // 2. Leemos lo que envía el backend
    String backendSlug = json['slug'] ?? '';
    
    // 3. Si el backend no envió el slug (común en agregaciones como top-selling), lo generamos de forma limpia
    if (backendSlug.isEmpty && productName.isNotEmpty) {
      backendSlug = productName.toLowerCase().trim().replaceAll(' ', '-');
    }

    return Product(
      id: json['_id'] ?? json['id'] ?? '',
      name: productName,
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
      images: json['images'] != null
          ? (json['images'] as List<dynamic>).map((e) => e.toString()).toList()
          : [],
          stock: json['stock'] != null
    ? int.tryParse(json['stock'].toString()) ?? 0
    : 0,
category: json['category'] is Map<String, dynamic>
    ? json['category']['name']?.toString() ?? ''
    : json['category']?.toString() ?? '',
categories: json['categories'] != null
    ? (json['categories'] as List<dynamic>).map((e) {
        if (e is Map<String, dynamic>) {
          return e['_id']?.toString() ?? '';
        }
        return e.toString();
      }).where((id) => id.isNotEmpty).toList()
    : [],
slug: backendSlug,
      quantity: json['quantity'] != null
          ? int.tryParse(json['quantity'].toString()) ?? 1
          : 1,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'name': name,
      'price': price,
      'description': description,
      'box': box,
      'images': images,
      'stock': stock,
      'category': category,
      'categories': categories,
      'slug': slug,
      'quantity': quantity,
      'updatedAt': updatedAt?.toIso8601String(),
    };
    // Incluye '_id' solo si no es una cadena vacía.
    if (id.isNotEmpty) {
      data['_id'] = id;
    }
    return data;
  }
}
