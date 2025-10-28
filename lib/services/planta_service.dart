import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:inventivo/core/constants/api_config.dart';

class Planta {
  final int? id;
  final String nombrePlantas;
  final String numeroBolsa;
  final double precio;
  final String categoria;
  final int stock;
  final String estado;
  final String fechaCreacion;
  final int idEmpresa;

  Planta({
    this.id,
    required this.nombrePlantas,
    required this.numeroBolsa,
    required this.precio,
    required this.categoria,
    required this.stock,
    required this.estado,
    required this.fechaCreacion,
    required this.idEmpresa,
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
      idEmpresa: int.tryParse(json['id_empresa']?.toString() ?? '0') ?? 0,
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
      "id_empresa": idEmpresa.toString(),
    };
  }
}

// Listar plantas
Future<List<Planta>> obtenerPlantas(int idEmpresa, {String filtro = ''}) async {
  try {
    final url = Uri.parse('${ApiConfig.listarPlantas}?id_empresa=$idEmpresa');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        List plantas = data['data'];

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

//  AGREGAR PLANTA
Future<bool> registrarPlanta(Planta planta) async {
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
        "id_empresa": planta.idEmpresa.toString(),
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
Future<bool> actualizarPlanta(Planta planta) async {
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

 //Eliminar planta
  Future<bool> eliminarPlanta(int id) async {
      try {
        final response = await http.post(
          Uri.parse(ApiConfig.eliminarPlantas),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'id': id}),
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

