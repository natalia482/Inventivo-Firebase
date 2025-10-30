import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:inventivo/core/constants/api_config.dart';
import 'package:inventivo/models/factura.dart';

class FacturaService {
  // Obtener productos disponibles (usa el endpoint de plantas)
  Future<List<ProductoDisponible>> obtenerProductosDisponibles(int idEmpresa) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.listarPlantas}?id_empresa=$idEmpresa'),
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

  // Crear factura
  Future<Map<String, dynamic>> crearFactura(Factura factura) async {
    try {
      final body = factura.toJson();
      
      // Debug: Imprimir lo que se está enviando
      print('📤 Enviando factura: ${jsonEncode(body)}');
      
      final response = await http.post(
        Uri.parse(ApiConfig.registrarFactura),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      print('📥 Respuesta del servidor: ${response.body}');
      
      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      print('❌ Error creando factura: $e');
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }

  // Listar facturas
  Future<List<Factura>> listarFacturas(int idEmpresa) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.listarFacturas}?id_empresa=$idEmpresa'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return (data['data'] as List)
              .map((json) => Factura.fromJson(json))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('Error listando facturas: $e');
      return [];
    }
  }

  // Eliminar factura
  Future<bool> eliminarFactura(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.eliminarFactura}?id=$id'),
      );

      final data = jsonDecode(response.body);
      return data['success'] == true;
    } catch (e) {
      print('Error eliminando factura: $e');
      return false;
    }
  }

  // Obtener detalle de factura
  Future<List<DetalleFactura>> obtenerDetalleFactura(int idFactura) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.verDetalleFactura}?id_factura=$idFactura'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return (data['data'] as List)
              .map((json) => DetalleFactura.fromJson(json))
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