class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String nit;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.nit,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phoneNumber'] ?? '',
      nit: json['nit'] ?? '',
    );
  }
  User copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? nit,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      nit: nit ?? this.nit,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id.isNotEmpty ? id : "N/A",
      'name': name.isNotEmpty ? name : "Cliente",
      'email': email,
      'phone': phone,
      'nit': nit,
    };
  }
}
