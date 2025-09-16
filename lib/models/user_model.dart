class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String nit;
  final String role;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.nit,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: (json['phone'] ?? json['phoneNumber'] ?? '').toString(),
      nit: (json['nit'] ?? json['cc'] ?? '').toString(),
      role: json['role']?.toString() ?? 'user',
    );
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? nit,
    String? role,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      nit: nit ?? this.nit,
      role: role ?? this.role,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'nit': nit,
      'role': role,
    };
  }
}
