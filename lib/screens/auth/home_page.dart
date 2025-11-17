import 'package:flutter/material.dart';
import 'package:inventivo/screens/auth/login_screen.dart';
import 'package:inventivo/screens/modulos/chatbot/chatbot_screen.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Fondo con imagen
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('images/chat_bg.png'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Color.fromARGB(167, 255, 255, 255), BlendMode.dstATop),
              ),
            ),
          ),
          // Contenido principal centrado
          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // LOGO Y NOMBRE
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'images/logo.png',
                        height: 200,
                      ),
                      const SizedBox(height: 1,),
                     
                    ],
                  ),

                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 10,),
                      const Text(
                        'INVENTIVO',
                        style: TextStyle(
                          color: Color(0xFFF7C600),
                          fontSize: 52,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  // BOTONES PRINCIPALES
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 20,
                    runSpacing: 10,
                    children: [
                        _mainButton(context, 'Iniciar Sesión', const LoginScreen()),
                        _mainButton(context, 'Chatbot', const ChatbotScreen())
                    ],
                  ),

                  const SizedBox(height: 50),

                  // SECCIÓN INFORMATIVA
                  Container(
                    width: size.width > 900 ? 900 : size.width * 0.9,
                    padding: const EdgeInsets.symmetric(
                        vertical: 25, horizontal: 20),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(108, 255, 255, 255).withOpacity(0.85),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(2, 3),
                        )
                      ],
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth > 700;
                        return Flex(
                          direction: isWide ? Axis.horizontal : Axis.vertical,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          mainAxisSize: MainAxisSize.min, // 🔹 esto evita el error
                          children: [
                            Flexible(fit: FlexFit.loose, child: _buildSistema()),
                            SizedBox(height: isWide ? 0 : 30, width: 30),
                            Flexible(fit: FlexFit.loose, child: _buildBeneficios()),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Botón verde principal
  Widget _mainButton(BuildContext context, String text, Widget destination) {
  return ElevatedButton(
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => destination),
      );
    },
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.green[700],
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 40),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    child: Text(
      text,
      style: const TextStyle(fontSize: 18, color: Colors.white),
    ),
  );
}
  // Sección “Nuestro sistema”
  Widget _buildSistema() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nuestro sistema',
          style: TextStyle(
            color: Color(0xFF0E3A59),
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),
        Wrap(
          spacing: 20,
          runSpacing: 15,
          children: const [
            _InfoCard(text: 'Manejo de inventarios'),
            _InfoCard(text: 'Manejo de insumos'),
            _InfoCard(text: 'Gestión de personal'),
          ],
        ),
      ],
    );
  }

  // Sección “Beneficios claves”
  Widget _buildBeneficios() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Beneficios claves',
          style: TextStyle(
            color: Color(0xFF0E3A59),
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),
        Wrap(
          spacing: 20,
          runSpacing: 15,
          children: const [
            _InfoCard(text: 'Optimiza tiempo'),
            _InfoCard(text: 'Inventarios actualizados'),
            _InfoCard(text: 'Toma de decisiones'),
          ],
        ),
      ],
    );
  }
}

// Tarjetas de texto pequeñas
class _InfoCard extends StatelessWidget {
  final String text;
  const _InfoCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(vertical: 10, horizontal: 18),
      decoration: BoxDecoration(
        color: const Color.fromARGB(0, 219, 9, 9),
        borderRadius: BorderRadius.circular(25),
        boxShadow: const [
          BoxShadow(
            color: Color.fromARGB(0, 0, 0, 0),
            blurRadius: 4,
            offset: Offset(2, 3),
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }
}
