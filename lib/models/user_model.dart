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

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'email': email,
      'phoneNumber': phone,
      'nit': nit,
    };
  }
}
