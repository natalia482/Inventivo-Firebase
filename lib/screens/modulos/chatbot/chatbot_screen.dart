import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:inventivo/core/constants/api_config.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _plantNameController = TextEditingController();
  // Asumimos un ID de empresa para pruebas, o puedes pedirlo al usuario.
  // Usaremos el ID de la empresa de prueba (7) como constante de ejemplo.
  static const int ID_EMPRESA_PRUEBA = 1; 
  
  String _responseMessage = 'Hola! Soy InventiBot 🌱. Pregúntame si tenemos alguna planta en stock (ej: Veranera).';
  bool _isLoading = false;

  Future<void> _searchPlant() async {
    final plantName = _plantNameController.text.trim();

    if (plantName.isEmpty) {
      setState(() => _responseMessage = "Por favor, ingresa el nombre de la planta.");
      return;
    }

    setState(() {
      _isLoading = true;
      _responseMessage = 'Buscando "$plantName"...';
    });

    try {
      // Usar la nueva función de ApiConfig para construir la URL de la consulta
      final url = ApiConfig.chatbotSearch(plantName, ID_EMPRESA_PRUEBA);
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          // Mostrar el mensaje preformateado que viene del backend
          setState(() => _responseMessage = data['message'] ?? 'Respuesta vacía.');
        } else {
          setState(() => _responseMessage = "Error del servidor: ${data['message']}");
        }
      } else {
        setState(() => _responseMessage = "Error HTTP: No se pudo conectar con la API.");
      }
    } catch (e) {
      setState(() => _responseMessage = "Error de conexión inesperado: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("InventiBot - Consulta Pública"),
        backgroundColor: const Color(0xFF2E7D32),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 🤖 Área de Mensajes del Chatbot
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.lightGreen.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    _responseMessage,
                    style: TextStyle(
                      fontSize: 16,
                      color: _isLoading ? Colors.grey : Colors.black87,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // ⌨️ Área de Entrada
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _plantNameController,
                    decoration: const InputDecoration(
                      hintText: "Escribe el nombre de la planta...",
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                    ),
                    onSubmitted: (_) => _searchPlant(), // Permite buscar al presionar Enter
                  ),
                ),
                const SizedBox(width: 8),
                _isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(),
                      )
                    : IconButton(
                        icon: const Icon(Icons.search, size: 30, color: Color(0xFF2E7D32)),
                        onPressed: _searchPlant,
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}