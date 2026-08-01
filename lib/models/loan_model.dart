// loan_model.dart

class LoanItem {
  final String id;
  final String productId;
  final String productName;
  final String image;
  final double productPrice; // Precio real del catálogo
  double customPrice;       // Precio asignado (modificado o heredado)
  final int qtyBorrowed;
  final int qtyReturned;
  final DateTime? createdAt;

  LoanItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.image,
    required this.productPrice,
    required this.customPrice,
    required this.qtyBorrowed,
    required this.qtyReturned,
    this.createdAt,
  });

  int get pendingQty => qtyBorrowed - qtyReturned;

  factory LoanItem.fromJson(Map<String, dynamic> json) {
    final prod = json['product'];
    String pId = '';
    String pName = 'Producto sin nombre';
    String pImage = '';
    double pPrice = 0.0;

    if (prod is String) {
      pId = prod;
    } else if (prod is Map<String, dynamic>) {
      pId = prod['_id']?.toString() ?? '';
      pName = prod['name']?.toString() ?? 'Producto sin nombre';
      pPrice = (prod['price'] as num?)?.toDouble() ?? 0.0;

      // Captura la primera imagen enviada por la API
      if (prod['images'] != null && prod['images'] is List && prod['images'].isNotEmpty) {
        pImage = prod['images'][0].toString();
      }
    }

    // ✅ LÓGICA CLAVE:
    // Si json['customPrice'] NO es null, toma el modificado.
    // Si ES null (nunca se editó), toma el precio real del catálogo (pPrice).
    final double? backendCustomPrice = (json['customPrice'] as num?)?.toDouble();
    final double activePrice = backendCustomPrice ?? pPrice;

    return LoanItem(
      id: json['_id']?.toString() ?? '',
      productId: pId,
      productName: pName,
      image: pImage,
      productPrice: pPrice,
      customPrice: activePrice,
      qtyBorrowed: json['qtyBorrowed'] ?? 0,
      qtyReturned: json['qtyReturned'] ?? 0,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
    );
  }
}

class LoanClient {
  final String id;
  final String name;
  final String phone;
  final String detalles;

  LoanClient({
    required this.id,
    required this.name,
    required this.phone,
    required this.detalles,
  });

  factory LoanClient.fromJson(Map<String, dynamic> json) {
    return LoanClient(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Cliente',
      phone: json['phone']?.toString() ?? '',
      detalles: json['detalles']?.toString() ?? '',
    );
  }
}

class LoanModel {
  final String id;
  final LoanClient? client;
  final List<LoanItem> items;
  final String status;
  final DateTime? createdAt;

  LoanModel({
    required this.id,
    this.client,
    required this.items,
    required this.status,
    this.createdAt,
  });

  String get clientName => client?.name ?? 'Local Comercial';

  factory LoanModel.fromJson(Map<String, dynamic> json) {
    var itemsList = json['items'] as List? ?? [];
    List<LoanItem> parsedItems = itemsList.map((i) => LoanItem.fromJson(i)).toList();

    return LoanModel(
      id: json['_id']?.toString() ?? '',
      client: json['client'] != null ? LoanClient.fromJson(json['client']) : null,
      items: parsedItems,
      status: json['status']?.toString() ?? 'open',
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
    );
  }
}