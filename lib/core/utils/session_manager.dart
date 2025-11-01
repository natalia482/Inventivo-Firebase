import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const _keyUser = "userData";

   Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_keyUser);
    if (data == null) return null;
    return jsonDecode(data);
  }

  Future<void> saveUser(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    // Guardamos 'id', 'rol', 'id_sede', 'id_empresa', 'nombre'
    await prefs.setString(_keyUser, jsonEncode(userData));
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUser);
  }

  // --- Helpers de Roles y Sedes ---

  Future<int?> getIdSede() async {
    final user = await getUser();
    if (user == null || user['id_sede'] == null) return null;
    return int.tryParse(user['id_sede'].toString());
  }
  
  Future<int?> getIdEmpresa() async {
    final user = await getUser();
    if (user == null || user['id_empresa'] == null) return null;
    return int.tryParse(user['id_empresa'].toString());
  }

  Future<String?> getRole() async {
    final user = await getUser();
    return user?['rol']?.toString().toUpperCase();
  }

  Future<bool> isAdminOrOwner() async {
    final rol = await getRole();
    return rol == 'PROPIETARIO' || rol == 'ADMINISTRADOR';
  }

  Future<bool> isOwner() async {
    final rol = await getRole();
    return rol == 'PROPIETARIO';
  }
}
