import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:inventivo/core/constants/api_config.dart';

class ChatbotService {
  
  // Llama a la API pública de consulta de plantas
  Future<Map<String, dynamic>> searchPlantInventory({
    required int idEmpresa,
    required String plantName,
  }) async {
    try {
      // Construye la URL de consulta con los parámetros codificados
      final response = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}/public/chatbot_search.php?nombre=${Uri.encodeComponent(plantName)}&id_empresa=$idEmpresa'
        ),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'success': false, 'message': 'Error de conexión HTTP: ${response.statusCode}'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Excepción de red: $e'};
    }
  }
}