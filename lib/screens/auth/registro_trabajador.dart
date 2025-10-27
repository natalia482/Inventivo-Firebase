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
  final SessionManager _session = SessionManager();

  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _correoController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _idEmpresa;
  String? _nombreEmpresa;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadEmpresa();
  }

  Future<void> _loadEmpresa() async {
    final user = await _session.getUser();
    setState(() {
      _idEmpresa = user?['id_empresa']?.toString();
      _nombreEmpresa = user?['nombre_empresa'];
    });
  }

  Future<void> _registrarTrabajador() async {
    if (!_formKey.currentState!.validate()) return;
    if (_idEmpresa == null || _nombreEmpresa == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: no se encontró la empresa del administrador')),
      );
      return;
    }

    setState(() => _loading = true);

    final response = await _authService.registrarTrabajador(
      nombre: _nombreController.text,
      apellido: _apellidoController.text,
      correo: _correoController.text,
      password: _passwordController.text,
      idEmpresa: _idEmpresa!,
      nombreEmpresa: _nombreEmpresa!,
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
          Image.asset('assets/images/vivero_fondo.jpg', fit: BoxFit.cover),
          Container(color: Colors.black.withOpacity(0.4)),
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 60),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Registrar Trabajador',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _nombreController,
                            decoration: const InputDecoration(
                              labelText: 'Nombre',
                              prefixIcon: Icon(Icons.person),
                            ),
                            validator: (v) => v!.isEmpty ? 'Ingrese el nombre' : null,
                          ),
                          const SizedBox(height: 15),
                          TextFormField(
                            controller: _apellidoController,
                            decoration: const InputDecoration(
                              labelText: 'Apellido',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator: (v) => v!.isEmpty ? 'Ingrese el apellido' : null,
                          ),
                          const SizedBox(height: 15),
                          TextFormField(
                            controller: _correoController,
                            decoration: const InputDecoration(
                              labelText: 'Correo electrónico',
                              prefixIcon: Icon(Icons.email),
                            ),
                            validator: (v) => !v!.contains('@') ? 'Correo no válido' : null,
                          ),
                          const SizedBox(height: 15),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Contraseña',
                              prefixIcon: Icon(Icons.lock),
                            ),
                            validator: (v) => v!.length < 6
                                ? 'Debe tener al menos 6 caracteres'
                                : null,
                          ),
                          const SizedBox(height: 25),

                          // 👇 Mostrar empresa actual solo como texto informativo
                          if (_nombreEmpresa != null)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.apartment, color: Colors.green),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Empresa: $_nombreEmpresa',
                                      style: const TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 25),

                          ElevatedButton(
                            onPressed: _loading ? null : _registrarTrabajador,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade700,
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 40),
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
                                        fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ],
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
