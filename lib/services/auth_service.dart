import 'package:inventivo/core/constants/api_config.dart';
import 'package:inventivo/services/api_services.dart';

class AuthService {
  final ApiService _apiService = ApiService();


// Registro Propietario (Reemplaza registroAdmin)
  Future<Map<String, dynamic>> registrarPropietario({
    required String nombre,
    required String apellido,
    required String correo,
    required String password,
    required String nombreEmpresa,
    required String nit,
    required String direccionEmpresa,
    required String telefonos
    // (Opcional) Puedes añadir latitud/longitud aquí
  }) async {
    final data = {
      "nombre": nombre,
      "apellido": apellido,
      "correo": correo,
      "password": password,
      "nombre_empresa": nombreEmpresa,
      "nit": nit,
      "direccion_empresa": direccionEmpresa,
      "telefonos": telefonos, 
    };

    return await _apiService.postData(ApiConfig.registroPropietario, data);
  }

  // Registro de Personal (Hecho por un Admin/Propietario logueado)
  Future<Map<String, dynamic>> registrarPersonal({
    required String nombre,
    required String apellido,
    required String correo,
    required String password,
    required int idSede,
    required String rol, // 'ADMINISTRADOR' o 'TRABAJADOR'
  }) async {
    final data = {
      "nombre": nombre,
      "apellido": apellido,
      "correo": correo,
      "password": password,
      "id_sede": idSede.toString(),
      "rol": rol, 
    };

    return await _apiService.postData(ApiConfig.registroPersonal, data);
  }

  //Login por roles (Actualizado para manejar nueva respuesta)
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
        'usuario': response['data'], 
      };
    } else {
      return {
        'success': false,
        'message': response['message'] ?? 'Error desconocido',
      };
    }
  }
}