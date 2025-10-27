import 'package:inventivo/core/constants/api_config.dart';
import 'package:inventivo/services/api_services.dart';

class AuthService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> registrarAdmin({
    required String nombre,
    required String apellido,
    required String correo,
    required String password,
  }) async {
    final data = {
      "nombre": nombre,
      "apellido": apellido,
      "correo": correo,
      "password": password,
      "rol": "ADMINISTRADOR"
    };

    return await _apiService.postData(ApiConfig.registroAdmin, data);
  }

  //Login
  Future<Map<String, dynamic>> login({
    required String correo,
    required String password,
  }) async {
    final data = {"correo": correo, "password": password};
    final response = await _apiService.postData(ApiConfig.login, data);

    // Validar y devolver formato uniforme
    if (response['success'] == true && response['data'] != null) {
      return {
        'success': true,
        'message': response['message'],
        'usuario': response['data'], // 🔹 Reetiquetamos aquí
      };
    } else {
      return {
        'success': false,
        'message': response['message'] ?? 'Error desconocido',
      };
    }
  }

  //Registro trabajador
  Future<Map<String, dynamic>> registrarTrabajador({
    required String nombre,
    required String apellido,
    required String correo,
    required String password,
    required String idEmpresa,
    required String nombreEmpresa,
  }) async {
    final data = {
      "nombre": nombre,
      "apellido": apellido,
      "correo": correo,
      "password": password,
      "id_empresa": idEmpresa,
      "nombre_empresa": nombreEmpresa,
    };

    return await _apiService.postData(ApiConfig.registroTrabajador, data);
  }
}