import 'package:flutter/material.dart';
import 'package:inventivo/services/auth_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  // El token generalmente viene de un parámetro de URL, que se recibiría aquí.
  final String? token; 

  const ResetPasswordScreen({super.key, this.token});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  // Reutilizamos la función de validación de complejidad de contraseña (la debes copiar)
  String? _validarContrasena(String? value) {
    if (value == null || value.isEmpty) {
      return "La contraseña es obligatoria.";
    }
    const pattern = r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[!@#$%^&*()_+={}\[\]:;<>,.?/~\\-]).{8,}$';
    final regExp = RegExp(pattern);

    if (!regExp.hasMatch(value)) {
      return "Debe tener 8+ caracteres e incluir Mayúscula, Minúscula, Dígito y Símbolo.";
    }
    return null;
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Token de recuperación no encontrado.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final response = await _authService.resetPassword(
      token: widget.token!,
      newPassword: _passwordController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (response['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ ${response['message']}. Inicia sesión con tu nueva clave.')),
      );
      // Navegar a Login después de un restablecimiento exitoso
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: ${response['message']}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Restablecer Contraseña'),
        backgroundColor: const Color(0xFF2E7D32),
      ),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(30),
          constraints: const BoxConstraints(maxWidth: 400),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Ingresa y confirma tu nueva contraseña.', style: TextStyle(fontSize: 16)),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Nueva Contraseña',
                    border: OutlineInputBorder(),
                  ),
                  validator: _validarContrasena, // Reutiliza la validación
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirmar Contraseña',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return 'Las contraseñas no coinciden.';
                    }
                    return _validarContrasena(value);
                  },
                ),
                const SizedBox(height: 30),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _resetPassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: const Text('Restablecer Contraseña'),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}