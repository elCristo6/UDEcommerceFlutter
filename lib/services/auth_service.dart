// lib/services/auth_service.dart
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';

import '../config/api_config.dart';
import '../models/user_model.dart';

class AuthService {
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/users/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'emailOrPhone': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['token'];

      // ✅ Decodificar el token para extraer el ID
      final decodedToken = JwtDecoder.decode(token);
      final userId = decodedToken['id'] ?? '';

      return {
        'user': User(
          id: userId,
          name: data['name'] ?? '',
          email: email,
          phone: '',
          nit: '',
          role: data['role'] ?? 'user',
        ),
        'token': token,
        'role': data['role'] ?? 'user',
      };
    } else {
      throw Exception(jsonDecode(response.body)['message'] ?? 'Error de login');
    }
  }
}
