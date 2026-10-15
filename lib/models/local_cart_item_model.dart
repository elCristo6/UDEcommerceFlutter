/*
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
*/

import 'project_details_model.dart';

class LocalCartItem {
  final String productId;
  final String name;
  final double price;
  final double? appliedPrice;
  final String image;
  int quantity;

  // Información opcional del proyecto
  final ProjectDetails? projectDetails;

  LocalCartItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.image,
    this.appliedPrice,
    this.quantity = 1,
    this.projectDetails,
  });

  // Precio comercial del producto o proyecto
  double get effectivePrice => appliedPrice ?? price;

  // Identifica los dos productos que permiten proyectos
  bool get isProjectProduct {
    final normalizedName = name.trim().toLowerCase();

    return normalizedName == 'servicio' ||
        normalizedName == 'impresión 3d' ||
        normalizedName == 'impresion 3d';
  }

  // Precio total acordado con el cliente
  double get commercialTotal => effectivePrice * quantity;

  // Dinero que realmente ingresa a caja
  double get amountToCollect {
    if (!isProjectProduct) {
      return commercialTotal;
    }

    return projectDetails?.advancePayment ?? 0.0;
  }

  // Saldo pendiente del proyecto
  double get pendingBalance {
    if (!isProjectProduct) return 0.0;

    return commercialTotal - (projectDetails?.advancePayment ?? 0.0);
  }

  // Verifica si el proyecto está listo para facturarse
  bool get isProjectValid {
    if (!isProjectProduct) return true;

    if (quantity != 1) return false;

    return projectDetails?.isValid(commercialTotal) ?? false;
  }

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'name': name,
        'price': price,
        'appliedPrice': appliedPrice,
        'image': image,
        'quantity': quantity,
        'projectDetails': projectDetails?.toJson(),
      };

  factory LocalCartItem.fromJson(Map<String, dynamic> json) {
    final rawProject = json['projectDetails'];

    return LocalCartItem(
      productId: json['productId'] ?? '',
      name: json['name'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      appliedPrice: (json['appliedPrice'] as num?)?.toDouble(),
      image: json['image'] ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      projectDetails: rawProject is Map
          ? ProjectDetails.fromJson(
              Map<String, dynamic>.from(rawProject),
            )
          : null,
    );
  }

  LocalCartItem copyWith({
    String? productId,
    String? name,
    double? price,
    double? appliedPrice,
    bool clearAppliedPrice = false,
    String? image,
    int? quantity,
    ProjectDetails? projectDetails,
    bool clearProjectDetails = false,
  }) {
    return LocalCartItem(
      productId: productId ?? this.productId,
      name: name ?? this.name,
      price: price ?? this.price,
      appliedPrice:
          clearAppliedPrice ? null : (appliedPrice ?? this.appliedPrice),
      image: image ?? this.image,
      quantity: quantity ?? this.quantity,
      projectDetails: clearProjectDetails
          ? null
          : (projectDetails ?? this.projectDetails),
    );
  }
}
