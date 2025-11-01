import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:inventivo/core/constants/api_config.dart';

// --------------------------------------------------------
// MODELO PLANTA (Actualizado para usar idSede)
// --------------------------------------------------------
class Planta {
  final int? id;
  final String nombrePlantas;
  final String numeroBolsa;
  final double precio;
  final String categoria;
  final int stock;
  final String estado;
  final String fechaCreacion;
  final int idSede; // Modificado

  Planta({
    this.id,
    required this.nombrePlantas,
    required this.numeroBolsa,
    required this.precio,
    required this.categoria,
    required this.stock,
    required this.estado,
    required this.fechaCreacion,
    required this.idSede, // Modificado
  });

  factory Planta.fromJson(Map<String, dynamic> json) {
    return Planta(
      id: int.tryParse(json['id'].toString()),
      nombrePlantas: json['nombre_plantas'] ?? '',
      numeroBolsa: json['numero_bolsa'] ?? '',
      precio: double.tryParse(json['precio'].toString()) ?? 0.0,
      categoria: json['categoria'] ?? '',
      stock: int.tryParse(json['stock'].toString()) ?? 0,
      estado: json['estado'] ?? 'disponible',
      fechaCreacion: json['fecha_creacion'] ?? '',
      idSede: int.tryParse(json['id_sede']?.toString() ?? '0') ?? 0, // Modificado
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "nombre_plantas": nombrePlantas,
      "numero_bolsa": numeroBolsa,
      "precio": precio.toString(),
      "categoria": categoria,
      "stock": stock.toString(),
      "estado": estado,
      "fecha_creacion": fechaCreacion,
      "id_sede": idSede.toString(), // Modificado
    };
  }
}

// --------------------------------------------------------
// SERVICIO DE PLANTAS (Actualizado)
// --------------------------------------------------------
class PlantaService {
  
  // Listar plantas
  Future<List<Planta>> obtenerPlantas(int idSede, {String filtro = ''}) async {
    try {
      // ✅ CORRECCIÓN: Llamar a ApiConfig.listarPlantas COMO UNA FUNCIÓN
      final url = Uri.parse(ApiConfig.listarPlantas(idSede, filtro: filtro));
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          List plantas = data['data'];
          // El backend ya filtra, pero mantenemos el filtro local por si acaso
          if (filtro.isNotEmpty) {
            plantas = plantas.where((p) {
              final nombre = p['nombre_plantas'].toString().toLowerCase();
              return nombre.contains(filtro.toLowerCase());
            }).toList();
          }

          return plantas.map((e) => Planta.fromJson(e)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error en obtenerPlantas: $e');
      return [];
    }
  }

  // AGREGAR PLANTA
  Future<bool> registrarPlanta(Planta planta, int idUsuario, int idSede) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.registrarPlantas),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "nombre_plantas": planta.nombrePlantas,
          "numero_bolsa": planta.numeroBolsa,
          "precio": planta.precio.toString(),
          "categoria": planta.categoria,
          "stock": planta.stock.toString(),
          "id_sede": planta.idSede.toString(), // Modificado
          "id_usuario": idUsuario.toString(),// Para Auditoría (PENDIENTE)
        }),
      );
      final data = jsonDecode(response.body);
      return data['success'] == true;
    } catch (e) {
      print('Error en registrarPlanta: $e');
      return false;
    }
  }

  // ACTUALIZAR PLANTA
  Future<bool> actualizarPlanta(Planta planta, int idUsuario, int idSede) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.editarPlantas),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "id": planta.id,
          "nombre_plantas": planta.nombrePlantas,
          "numero_bolsa": planta.numeroBolsa,
          "precio": planta.precio,
          "categoria": planta.categoria,
          "stock": planta.stock,
          "estado": planta.estado,
          "id_sede": planta.idSede, // Modificado
          "id_usuario": idUsuario, // Para auditoría
        }),
      );

      print("🔹 Respuesta del backend (actualizar): ${response.body}");

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json["success"] == true;
      } else {
        print("⚠️ Error HTTP: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("❌ Error en actualizarPlanta: $e");
      return false;
    }
  }

  // Eliminar planta
  Future<bool> eliminarPlanta(int id, int idUsuario, int idSede ) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.eliminarPlantas),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': id,
          'id_usuario': idUsuario, // Para auditoría
          'id_sede': idSede // Para auditoría
          }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      } else {
        print('Error HTTP: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error al eliminar planta: $e');
      return false;
    }
  }
}