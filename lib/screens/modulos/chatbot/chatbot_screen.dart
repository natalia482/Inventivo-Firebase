import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:inventivo/core/constants/api_config.dart';

// Modelo para manejar mensajes en el chat
class ChatMessage {
  final String text;
  final bool isUser; // true = Usuario, false = Bot
  final bool isSearching; // Muestra un indicador de carga

  ChatMessage(this.text, this.isUser, {this.isSearching = false});
}

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _textController = TextEditingController();
  
  // Usamos un ID de empresa para la búsqueda pública (el backend lo ignora si aplicaste el fix)
  
  // Lista que guarda todos los mensajes de la conversación
  final List<ChatMessage> _messages = [
    ChatMessage('Hola! Soy InventiBot 🌱. Pregúntame si tenemos alguna planta en stock (ej: Veranera).', false),
  ];
  
  // Scroll Controller para mantener el chat al final
  final ScrollController _scrollController = ScrollController();


  // Añade un mensaje a la lista y actualiza la UI
  void _addMessage(String text, {required bool isUser, bool isSearching = false}) {
    setState(() {
      _messages.add(ChatMessage(text, isUser, isSearching: isSearching));
    });
    // Asegura que se desplace al final después de añadir
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }
  
  // Función central que maneja la entrada del usuario
  Future<void> _handleUserMessage() async {
    final userText = _textController.text.trim();

    if (userText.isEmpty) return;

    // 1. Añadir el mensaje del usuario al historial
    _addMessage(userText, isUser: true);
    _textController.clear();

    // 2. Lógica Conversacional: Interceptar Saludos
    final lowerCaseText = userText.toLowerCase();

    if (lowerCaseText.contains('hola') || 
        lowerCaseText.contains('saludos') || 
        lowerCaseText == 'hola') {
      _addMessage('¡Hola! Soy InventiBot 🌱. ¿Qué planta te gustaría consultar?', isUser: false);
      return;
    }
    
    // 3. Lógica de Búsqueda (API Call)
    _addMessage('Buscando "$userText"...', isUser: false, isSearching: true);
    await _searchInventory(userText); 
  }

  // Llama a la API de búsqueda de inventario
  Future<void> _searchInventory(String plantName) async {
    // Reemplaza el mensaje de "Buscando..." con la respuesta final
    setState(() {
        _messages.removeLast();
    });

    try {
      final url = ApiConfig.chatbotSearch(plantName, 0);
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          _addMessage(data['message'] ?? 'Respuesta vacía.', isUser: false);
        } else {
          _addMessage("Error del servidor: ${data['message']}", isUser: false);
        }
      } else {
        _addMessage("Error HTTP: No se pudo conectar con la API.", isUser: false);
      }
    } catch (e) {
      _addMessage("Error de conexión inesperado: $e", isUser: false);
    } 
  }

  // Widget para construir la burbuja de chat
  Widget _buildMessage(ChatMessage message) {
    // Alineación: Derecha para el usuario, izquierda para el bot
    final alignment = message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final color = message.isUser ? Colors.green.shade100 : Colors.lightGreen.shade50;
    
    // Si es el mensaje de búsqueda, muestra el indicador de carga
    if (message.isSearching) {
        return const Center(child: Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2E7D32)),
        ));
    }
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: alignment,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12.0),
            ),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            child: SelectableText(
              message.text,
              style: const TextStyle(fontSize: 15.0, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("InventiBot - Consulta Pública"),
        backgroundColor: const Color(0xFF2E7D32),
      ),
      body: Column(
        children: <Widget>[
          // 🤖 Área de Mensajes del Chatbot (ListView.builder)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  return _buildMessage(_messages[index]);
                },
              ),
            ),
          ),
          const Divider(height: 1.0),
          
          // ⌨️ Área de Entrada
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            decoration: const BoxDecoration(color: Colors.white),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration.collapsed(
                      hintText: "Escribe el nombre de la planta o un saludo...",
                    ),
                    onSubmitted: (_) => _handleUserMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, size: 30, color: Color(0xFF2E7D32)),
                  onPressed: _handleUserMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}