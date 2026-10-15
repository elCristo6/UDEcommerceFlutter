
class ProjectDetails {
  final String description;
  final double advancePayment;
  final DateTime? deliveryDate;

  const ProjectDetails({
    this.description = '',
    this.advancePayment = 0,
    this.deliveryDate,
  });

  double balance(double totalPrice) {
    return totalPrice - advancePayment;
  }

  bool isValid(double totalPrice) {
    return advancePayment > 0 &&
        advancePayment <= totalPrice &&
        description.trim().isNotEmpty &&
        deliveryDate != null;
  }

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'advancePayment': advancePayment,
      'deliveryDate': deliveryDate?.toIso8601String(),
    };
  }

  factory ProjectDetails.fromJson(Map<String, dynamic> json) {
    final rawDate = json['deliveryDate'];

    return ProjectDetails(
      description: json['description']?.toString() ?? '',
      advancePayment:
          (json['advancePayment'] as num?)?.toDouble() ?? 0,
      deliveryDate: rawDate == null
          ? null
          : DateTime.tryParse(rawDate.toString()),
    );
  }

  ProjectDetails copyWith({
    String? description,
    double? advancePayment,
    DateTime? deliveryDate,
    bool clearDeliveryDate = false,
  }) {
    return ProjectDetails(
      description: description ?? this.description,
      advancePayment: advancePayment ?? this.advancePayment,
      deliveryDate:
          clearDeliveryDate ? null : deliveryDate ?? this.deliveryDate,
    );
  }
}
