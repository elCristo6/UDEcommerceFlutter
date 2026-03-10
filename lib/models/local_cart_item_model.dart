class LocalCartItem {
  final String productId;
  final String name;
  final double price;
  final double? appliedPrice;
  final String image;
  int quantity;

  LocalCartItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.image,
    this.appliedPrice,
    this.quantity = 1,
  });
  double get effectivePrice => appliedPrice ?? price;

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'name': name,
        'price': price,
        'appliedPrice': appliedPrice,
        'image': image,
        'quantity': quantity,
      };

  factory LocalCartItem.fromJson(Map<String, dynamic> json) => LocalCartItem(
        productId: json['productId'] ?? '',
        name: json['name'] ?? '',
        price: (json['price'] as num?)?.toDouble() ?? 0.0,
        appliedPrice: (json['appliedPrice'] as num?)?.toDouble(),
        image: json['image'] ?? '',
        quantity: json['quantity'] ?? 1,
      );
  LocalCartItem copyWith({
    String? productId,
    String? name,
    double? price,
    double? appliedPrice,
    bool clearAppliedPrice = false,
    String? image,
    int? quantity,
  }) {
    return LocalCartItem(
      productId: productId ?? this.productId,
      name: name ?? this.name,
      price: price ?? this.price,
      appliedPrice:
          clearAppliedPrice ? null : (appliedPrice ?? this.appliedPrice),
      image: image ?? this.image,
      quantity: quantity ?? this.quantity,
    );
  }
}
