import 'package:flutter/material.dart';
import 'package:inventivo/screens/auth/registro_admin.dart';
import 'package:inventivo/screens/dashboard/admin_dashboar.dart';
import 'package:inventivo/screens/modulos/chatbot/chatbot_screen.dart';
import 'package:inventivo/services/auth_service.dart';
import 'package:inventivo/core/utils/session_manager.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _correoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  final _session = SessionManager();
  bool _loading = false;

  Future<void> _login() async {
    if (_correoController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos')),
      );
      return;
    }

    setState(() => _loading = true);

    final response = await _authService.login(
      correo: _correoController.text,
      password: _passwordController.text,
    );

    setState(() => _loading = false);

    if (response['success'] == true) {
      await _session.saveUser(response['usuario']);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Sesión iniciada')),
      );

      final rol = response['usuario']['rol'];
      if (rol == 'PROPIETARIO' || rol == 'ADMINISTRADOR') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AdminDashboard()),
        );
      } else {
        // Navegación al dashboard de Trabajador
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AdminDashboard()),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ ${response['message']}')),
      );
    }
  }

  // ✅ NUEVA FUNCIÓN: Maneja la llamada a la API de recuperación
  Future<void> _handleRecoveryRequest(String correo) async {
    // Usamos el setState del widget principal para mostrar el spinner
    setState(() => _loading = true);

    final result = await _authService.sendRecoveryEmail(correo: correo);

    setState(() => _loading = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ ${result['message']}')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: ${result['message']}')),
      );
    }
  }

  void _iniciarRecuperacion() {
    final TextEditingController correoRecuperacionController = TextEditingController();
    
    showDialog<String?>( // El diálogo devuelve el correo o null
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recuperar Contraseña'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ingresa el correo electrónico asociado a tu cuenta:'),
            const SizedBox(height: 10),
            TextField(
              controller: correoRecuperacionController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Correo',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final correo = correoRecuperacionController.text.trim();
              if (correo.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingresa un correo válido.')));
                return;
              }
              // Devolvemos el correo electrónico al ".then"
              Navigator.of(context).pop(correo);
            },
            child: const Text('Enviar Solicitud'),
          ),
        ],
      ),
    ).then((correo) {
      // ✅ Si se devuelve un correo, iniciamos la llamada a la API
      if (correo != null && correo.isNotEmpty) {
        _handleRecoveryRequest(correo);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // ... (Tu diseño de login)

    return Scaffold(
      body: 
      Container(
        decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('images/chat_bg.png'),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                Color.fromARGB(176, 255, 255, 255), BlendMode.dstATop),
            ),
          ),
        child: Center(
          child: SingleChildScrollView(
            child: LayoutBuilder(
              builder: (context, constraints) {
                double cardWidth;
                if (constraints.maxWidth > 1000) {
                  cardWidth = 500;
                } else if (constraints.maxWidth > 600) {
                  cardWidth = 400;
                } else {
                  cardWidth = constraints.maxWidth * 0.9;
                }

                return Center(
                  child: Card(
                    color: Colors.white,
                    elevation: 10,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Container(
                      width: cardWidth,
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 150,
                            height: 150,
                            decoration: const BoxDecoration(
                              color: Color(0xFF2E7D32),
                              borderRadius: BorderRadius.all(Radius.circular(20))
                            ),
                            child: const Icon(Icons.lock_open, size: 80, color: Colors.white),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'INICIAR SESIÓN',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: _correoController,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.email_outlined),
                              labelText: 'Correo',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: _passwordController,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.lock_outline),
                              labelText: 'Contraseña',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            obscureText: true,
                          ),
                          
                          // Botón de Olvidé mi Contraseña (Recuperación)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _iniciarRecuperacion, 
                              child: const Text('¿Olvidaste tu contraseña?', style: TextStyle(color: Color(0xFF388E3C), fontSize: 14)),
                            ),
                          ),

                          const SizedBox(height: 10),
                          _loading
                              ? const CircularProgressIndicator()
                              : SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF388E3C),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                    ),
                                    onPressed: _login,
                                    child: const Text(
                                      'Ingresar',
                                      style: TextStyle(
                                          fontSize: 18, color: Colors.white),
                                    ),
                                  ),
                                ),
                          const SizedBox(height: 20),
                          TextButton(
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context)=> RegistroAdminScreen())); 
                            },
                            child: const Text(
                              '¿No tienes cuenta? Registra tu empresa',
                              style: TextStyle(color: Color(0xFF1B5E20)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
      // Botón Chatbot (se mantiene)
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ChatbotScreen()),
          );
        },
        icon: const Icon(Icons.chat_bubble_outline),
        label: const Text("Consultar Inventario"),
        backgroundColor: const Color(0xFF2E7D32),
      ),
    );
  }
}