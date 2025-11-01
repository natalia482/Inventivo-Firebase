import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:inventivo/core/constants/api_config.dart';
import 'package:inventivo/models/remision.dart'; // Importar el modelo renombrado

class RemisionService {
  
  // Obtener productos disponibles (usa el endpoint de plantas)
  Future<List<ProductoDisponible>> obtenerProductosDisponibles(int idSede) async {
    try {
      // ✅ CORRECCIÓN: Llamar a la función ApiConfig.listarPlantas
      final response = await http.get(
        Uri.parse(ApiConfig.listarPlantas(idSede)), 
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          // Filtrar solo las que tienen stock > 0
          return (data['data'] as List)
              .where((item) => (int.tryParse(item['stock']?.toString() ?? '0') ?? 0) > 0)
              .map((json) => ProductoDisponible.fromJson(json))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('Error obteniendo productos: $e');
      return [];
    }
  }

  // Obtener el siguiente número de remisión
  Future<int> obtenerSiguienteNumeroFactura(int idSede) async {
    try {
      // ✅ CORRECCIÓN: Llamar a la función ApiConfig
      final response = await http.get(
        Uri.parse(ApiConfig.siguienteNumeroRemision(idSede)),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['siguiente_numero'] != null) {
          return data['siguiente_numero'];
        }
      }
      return 1; 
    } catch (e) {
      print('Error obteniendo siguiente número de factura: $e');
      return 1; 
    }
  }


  // Crear remisión
  Future<Map<String, dynamic>> crearRemision(Remision remision) async {
    try {
      final body = remision.toJson();
      
      print('📤 Enviando Remisión: ${jsonEncode(body)}');
      
      final response = await http.post(
        Uri.parse(ApiConfig.registrarRemision),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      print('📥 Respuesta del servidor: ${response.body}');
      
      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      print('❌ Error creando remisión: $e');
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }

  // Listar remisiones
  Future<List<Remision>> listarRemisiones(int idSede) async {
    try {
      // ✅ CORRECCIÓN: Llamar a la función ApiConfig
      final response = await http.get(
        Uri.parse(ApiConfig.listarRemisiones(idSede)), 
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return (data['data'] as List)
              .map((json) => Remision.fromJson(json))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('Error listando remisiones: $e');
      return [];
    }
  }

  // Eliminar remisión
  Future<bool> eliminarRemision(int id) async {
    try {
      // (Asumiendo que eliminar.php acepta DELETE o POST/GET con id)
      final response = await http.post(
        Uri.parse(ApiConfig.eliminarRemision),
         headers: {"Content-Type": "application/json"},
        body: jsonEncode({"id": id}) // (Asumiendo que PHP lee JSON)
      );

      final data = jsonDecode(response.body);
      return data['success'] == true;
    } catch (e) {
      print('Error eliminando remisión: $e');
      return false;
    }
  }

  // Obtener detalle de remisión
  Future<List<DetalleRemision>> obtenerDetalleRemision(int idRemision) async {
    try {
      // ✅ CORRECCIÓN: Llamar a la función ApiConfig
      final response = await http.get(
        Uri.parse(ApiConfig.verDetalleRemision(idRemision)),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return (data['data'] as List)
              .map((json) => DetalleRemision.fromJson(json))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('Error obteniendo detalle: $e');
      return [];
    }
  }
}