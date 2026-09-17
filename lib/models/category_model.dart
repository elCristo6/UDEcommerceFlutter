class CategoryModel {
  final String id;
  final String name;
  final String description;

  CategoryModel({
    required this.id,
    required this.name,
    this.description = '',
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
    };
  }
}