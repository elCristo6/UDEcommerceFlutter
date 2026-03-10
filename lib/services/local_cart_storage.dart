import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/local_cart_item_model.dart';

class LocalCartStorage {
  static const _key = 'ud_cart_local_v1';

  Future<List<LocalCartItem>> read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => LocalCartItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> write(List<LocalCartItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final data = items.map((e) => e.toJson()).toList();
    await prefs.setString(_key, jsonEncode(data));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}