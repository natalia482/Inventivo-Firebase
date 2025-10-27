import 'package:flutter/material.dart';
import 'package:inventivo/services/auth_service.dart';
import 'package:inventivo/core/utils/session_manager.dart';

class RegistroTrabajadorScreen extends StatefulWidget {
  const RegistroTrabajadorScreen({super.key});

  @override
  State<RegistroTrabajadorScreen> createState() => _RegistroTrabajadorScreenState();
}

class _RegistroTrabajadorScreenState extends State<RegistroTrabajadorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final SessionManager _session = SessionManager(); // ✅ Manejo de sesión

  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _correoController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;

  Future<void> _registrarTrabajador() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    // ✅ Obtiene la sesión actual del administrador
    final user = await _session.getUser();

    final idEmpresa = user?['id_empresa']?.toString() ?? '';
    final nombreEmpresa = user?['nombre_empresa'] ?? '';

    // ✅ Llama al servicio de registro
    final response = await _authService.registrarTrabajador(
      nombre: _nombreController.text,
      apellido: _apellidoController.text,
      correo: _correoController.text,
      password: _passwordController.text,
      idEmpresa: idEmpresa,
      nombreEmpresa: nombreEmpresa,
    );

    setState(() => _loading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(response['message'] ?? 'Error desconocido')),
    );

    if (response['success'] == true) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 🌿 Fondo con imagen de vivero
          Image.asset(
            'assets/images/vivero_fondo.jpg',
            fit: BoxFit.cover,
          ),
          Container(
            color: Colors.black.withOpacity(0.4),
          ),
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 60),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 🌼 Encabezado
                  Text(
                    'Registrar Trabajador',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // 🧾 Formulario
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Nombre
                          TextFormField(
                            controller: _nombreController,
                            decoration: InputDecoration(
                              prefixIcon: Icon(Icons.person, color: Colors.green.shade700),
                              labelText: 'Nombre',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            validator: (value) =>
                                value == null || value.isEmpty ? 'Ingrese el nombre' : null,
                          ),
                          const SizedBox(height: 20),

                          // Apellido
                          TextFormField(
                            controller: _apellidoController,
                            decoration: InputDecoration(
                              prefixIcon: Icon(Icons.person_outline, color: Colors.green.shade700),
                              labelText: 'Apellido',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            validator: (value) =>
                                value == null || value.isEmpty ? 'Ingrese el apellido' : null,
                          ),
                          const SizedBox(height: 20),

                          // Correo
                          TextFormField(
                            controller: _correoController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              prefixIcon: Icon(Icons.email, color: Colors.green.shade700),
                              labelText: 'Correo Electrónico',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            validator: (value) =>
                                value == null || !value.contains('@') ? 'Correo no válido' : null,
                          ),
                          const SizedBox(height: 20),

                          // Contraseña
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              prefixIcon: Icon(Icons.lock, color: Colors.green.shade700),
                              labelText: 'Contraseña',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            validator: (value) => value != null && value.length < 6
                                ? 'Debe tener al menos 6 caracteres'
                                : null,
                          ),
                          const SizedBox(height: 30),

                          // Botón de registro
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _registrarTrabajador,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade700,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              child: _loading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text(
                                      'Registrar',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Volver al dashboard
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Volver al panel principal',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        decoration: TextDecoration.underline,
                      ),
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
}
