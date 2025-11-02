import 'package:flutter/material.dart';
import 'package:inventivo/services/auth_service.dart';

class RegistroAdminScreen extends StatefulWidget {
  const RegistroAdminScreen({Key? key}) : super(key: key);

  @override
  _RegistroAdminScreenState createState() => _RegistroAdminScreenState();
}

class _RegistroAdminScreenState extends State<RegistroAdminScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController apellidoController = TextEditingController();
  final TextEditingController correoController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirpasswordController = TextEditingController();
  final TextEditingController nombreEmpresaController = TextEditingController();
  final TextEditingController nitEmpresaController = TextEditingController();
  final TextEditingController direccionEmpresaController = TextEditingController();
  final TextEditingController telefonoController = TextEditingController();

  final AuthService _authService = AuthService();
  bool _isLoading = false;

  // ✅ FUNCIÓN DE VALIDACIÓN DE CONTRASEÑA ROBUSTA
  String? _validarContrasena(String? value) {
    if (value == null || value.isEmpty) {
      return "La contraseña es obligatoria.";
    }

    // Expresión Regular (RegExp) para cubrir todos los requisitos:
    // 1. (?=.*[A-Z]): Al menos una mayúscula.
    // 2. (?=.*[a-z]): Al menos una minúscula.
    // 3. (?=.*\d): Al menos un dígito (0-9).
    // 4. (?=.*[!@#$%^&*()_+={}\[\]:;<>,.?/~\\-]): Al menos un carácter especial común.
    // 5. .{8,}: Mínimo 8 caracteres de longitud.
    const pattern = r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[!@#$%^&*()_+={}\[\]:;<>,.?/~\\-]).{8,}$';
    final regExp = RegExp(pattern);

    if (!regExp.hasMatch(value)) {
      return "Debe tener 8+ caracteres e incluir Mayúscula, Minúscula, Dígito y Símbolo.";
    }

    return null;
  }
  // FIN FUNCIÓN DE VALIDACIÓN

  Future<void> registrarPropietario() async {
    if (!_formKey.currentState!.validate()) return;

    if (passwordController.text.trim() != confirpasswordController.text.trim()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Las contraseñas no coinciden."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _authService.registrarPropietario(
        nombre: nombreController.text.trim(),
        apellido: apellidoController.text.trim(),
        correo: correoController.text.trim(),
        password: passwordController.text.trim(),
        nombreEmpresa: nombreEmpresaController.text.trim(),
        direccionEmpresa: direccionEmpresaController.text.trim(),
        telefonos: telefonoController.text.trim(),
      );

      if (response["success"] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Éxito: ${response["message"]}. Ahora puedes iniciar sesión."),
            backgroundColor: Colors.green,
          ),
        );

        // Limpiar los campos
        nombreController.clear();
        apellidoController.clear();
        correoController.clear();
        passwordController.clear();
        confirpasswordController.clear();
        nombreEmpresaController.clear();
        nitEmpresaController.clear();
        direccionEmpresaController.clear();
        telefonoController.clear();

        if (mounted) Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response["message"] ?? "Error al registrar."),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error de conexión: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white.withOpacity(0.9),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
         decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('images/chat_bg.png'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Color.fromARGB(176, 255, 255, 255), BlendMode.dstATop),
              ),
            ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 400, vertical: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Logo del robot o título
                    // Asumiendo que 'images/iniciosesion.png' está en assets/images/
                    Image.asset(
                      'images/iniciosesion.png', 
                      height: 120,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "REGISTRO DE PROPIETARIO Y EMPRESA",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 0, 0, 0),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 25),

                    // Sección empresa
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(38, 255, 255, 255).withOpacity(0.9),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 6,
                            offset: const Offset(2, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Datos de la Empresa",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: nombreEmpresaController,
                            decoration: _inputDecoration("Nombre de la empresa"),
                            validator: (value) =>
                                value!.isEmpty ? "Ingrese el nombre de la empresa" : null,
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: direccionEmpresaController,
                            decoration:
                                _inputDecoration("Dirección (Sede Principal)"),
                            validator: (value) =>
                                value!.isEmpty ? "Ingrese la dirección" : null,
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: telefonoController,
                            decoration: _inputDecoration(
                                "Teléfonos (separados por comas)"),
                            keyboardType: TextInputType.phone,
                            validator: (value) =>
                                value!.isEmpty ? "Ingrese al menos un número" : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Sección propietario
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 6,
                            offset: const Offset(2, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Datos del Propietario",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: nombreController,
                            decoration: _inputDecoration("Nombre"),
                            validator: (value) =>
                                value!.isEmpty ? "Ingrese el nombre" : null,
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: apellidoController,
                            decoration: _inputDecoration("Apellido"),
                            validator: (value) =>
                                value!.isEmpty ? "Ingrese el apellido" : null,
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: correoController,
                            decoration: _inputDecoration("Correo electrónico"),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) =>
                                value!.isEmpty ? "Ingrese el correo" : null,
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: passwordController,
                            obscureText: true,
                            decoration: _inputDecoration("Contraseña"),
                            // ✅ APLICAR LA NUEVA VALIDACIÓN
                            validator: _validarContrasena, 
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: confirpasswordController,
                            obscureText: true,
                            decoration: _inputDecoration("Confirmar contraseña"),
                            validator: (value) {
                                // 1. Verificar si está vacío
                                if (value!.isEmpty) {
                                    return "Confirme la contraseña";
                                }
                                // 2. Verificar que coincida con el campo principal
                                if (value != passwordController.text.trim()) {
                                    return "Las contraseñas no coinciden.";
                                }
                                // 3. Opcional: Reaplicar la validación de complejidad si se desea un mensaje completo
                                return _validarContrasena(value);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),

                    ElevatedButton(
                      onPressed: _isLoading ? null : registrarPropietario,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 80, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 6,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "Registrar",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}