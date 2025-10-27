import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  Future<Map<String, dynamic>> postData(String url, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(data),
    );

    print("📡 URL: $url");
    print("📤 Datos enviados: $data");
    print("📥 Respuesta: ${response.body}");

    if (response.statusCode == 200 && response.body.isNotEmpty) {
      try {
        return jsonDecode(response.body);
      } catch (e) {
        return {'success': false, 'message': 'Error al decodificar JSON: $e'};
      }
    } else {
      return {
        'success': false,
        'message': 'Error en la conexión con el servidor (${response.statusCode})'
      };
    }
  }
}
