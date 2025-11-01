import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:inventivo/core/constants/api_config.dart';
import '../models/insumo.dart';

class InsumoService {
  
  Future<bool> registrarInsumo(Insumo insumo) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.registrarInsumo),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(insumo.toJson()), // toJson() ya envía idSede
      );

      final data = jsonDecode(response.body);
      return data['success'] == true;
    } catch (e) {
      print("Error registrando insumo: $e");
      return false;
    }
  }

  Future<List<Insumo>> listarInsumos(int idSede, {String? filtro}) async {
    try {
      final url = ApiConfig.listarInsumos(idSede, filtro: filtro);
      final response = await http.get(Uri.parse(url));
      final data = jsonDecode(response.body);

      if (data['success'] == true && data['data'] != null) {
        return List<Insumo>.from(
          data['data'].map((i) => Insumo.fromJson(i)),
        );
      } else {
        return [];
      }
    } catch (e) {
      print("Error listando insumos: $e");
      return [];
    }
  }
}