import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:inventivo/core/constants/api_config.dart';
import 'package:inventivo/models/remision.dart'; 

class RemisionService {
  
  Future<List<ProductoDisponible>> obtenerProductosDisponibles(int idSede) async {
    try {
      // Usa la función listarPlantas de ApiConfig (que acepta idSede)
      final response = await http.get(
        Uri.parse(ApiConfig.listarPlantas(idSede)), 
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          // Filtra stock > 0
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

  Future<int> obtenerSiguienteNumeroFactura(int idSede) async {
    try {
      // Usa la función siguienteNumeroRemision de ApiConfig (que acepta idSede)
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

  Future<Map<String, dynamic>> crearRemision(Remision remision) async {
    try {
      final body = remision.toJson();
      final response = await http.post(
        Uri.parse(ApiConfig.registrarRemision),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  Future<List<Remision>> listarRemisiones(int idSede) async {
    try {
      // Usa la función listarRemisiones de ApiConfig (que acepta idSede)
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
  
  Future<bool> eliminarRemision(int id) async {
     try {
        final response = await http.post(
          Uri.parse(ApiConfig.eliminarRemision),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"id": id}) 
        );

        final data = jsonDecode(response.body);
        return data['success'] == true;
      } catch (e) {
        print('Error eliminando remisión: $e');
        return false;
      }
  }
  
  Future<List<DetalleRemision>> obtenerDetalleRemision(int idRemision) async {
    try {
      // Usa la función verDetalleRemision de ApiConfig
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