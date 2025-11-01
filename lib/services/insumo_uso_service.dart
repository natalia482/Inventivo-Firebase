import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:inventivo/core/constants/api_config.dart';

class ActividadService {
  Future<Map<String, dynamic>> registrarActividad({
    required int idInsumo,
    required double cantidadUsada,
    required String dosificacion,
    required String objetivo,
    required String responsable,
    required int idSede,
  }) async {
    final response = await http.post(
      Uri.parse(ApiConfig.registrarUsoInsumo),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "id_insumo": idInsumo,
        "cantidad_utilizada": cantidadUsada,
        "dosificacion": dosificacion,
        "objetivo": objetivo,
        "responsable": responsable,
        "id_empresa": idSede,
      }),
    );

    return jsonDecode(response.body);
  }
}
