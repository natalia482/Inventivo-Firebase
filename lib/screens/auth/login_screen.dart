import 'package:flutter/material.dart';
import 'package:inventivo/screens/dashboard/admin_dashboar.dart';
import 'package:inventivo/screens/modulos/chatbot/chatbot_screen.dart'; // 👈 importa la pantalla del bot
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
      if (rol == 'ADMINISTRADOR') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AdminDashboard(
              idEmpresa: int.parse(response['usuario']['id_empresa'].toString()),
            ),
          ),
        );
      } else {
        Navigator.pushReplacementNamed(context, '/dashboard_trabajador');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ ${response['message']}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inicio de Sesión')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: _correoController,
              decoration: const InputDecoration(labelText: 'Correo'),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Contraseña'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            _loading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _login,
                    child: const Text('Ingresar'),
                  ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/registro_admin');
              },
              child: const Text('¿No tienes cuenta? Regístrate'),
            ),

            // 👇 NUEVA SECCIÓN: Botón del chatbot
            const Divider(height: 30, thickness: 1),
            TextButton.icon(
              icon: const Icon(Icons.chat_bubble_outline, color: Colors.green),
              label: const Text(
                "Habla con nuestro bot 🤖",
                style: TextStyle(
                    color: Colors.green, fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ChatBotScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
