import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:inventivo/core/constants/api_config.dart';

class ChatbotService {
  /// Envía un mensaje del usuario al backend PHP y obtiene la respuesta del bot.
  static Future<String> enviarMensaje(String mensaje) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.chatbot), // endpoint PHP del bot
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"mensaje": mensaje}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["respuesta"] ?? "Sin respuesta del bot.";
      } else {
        return "Error del servidor (${response.statusCode}).";
      }
    } catch (e) {
      return "Error de conexión con el servidor: $e";
    }
  }
}
