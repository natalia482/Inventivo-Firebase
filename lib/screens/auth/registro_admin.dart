import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:inventivo/core/constants/api_config.dart';

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

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  Future<void> registrarAdministrador() async {
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
      final response = await http.post(
        Uri.parse(ApiConfig.registroAdmin),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "nombre": nombreController.text.trim(),
          "apellido": apellidoController.text.trim(),
          "correo": correoController.text.trim(),
          "password": passwordController.text.trim(),
          "rol": "ADMINISTRADOR",
          "nombre_empresa": nombreEmpresaController.text.trim(),
          "nit": nitEmpresaController.text.trim(),
          "direccion_empresa": direccionEmpresaController.text.trim(),
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data["success"] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Administrador y empresa creados correctamente."),
            backgroundColor: Colors.green,
          ),
        );

        nombreController.clear();
        apellidoController.clear();
        correoController.clear();
        passwordController.clear();
        confirpasswordController.clear();
        nombreEmpresaController.clear();
        nitEmpresaController.clear();
        direccionEmpresaController.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data["message"] ?? "Error al registrar."),
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

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: const Color(0xFFEFF7EE),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: isLargeScreen ? 520 : double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 🌿 Encabezado visual
                  const Icon(Icons.eco, color: Color(0xFF2E7D32), size: 70),
                  const SizedBox(height: 10),
                  const Text(
                    "Registro de Administrador",
                    style: TextStyle(
                      color: Color(0xFF2E7D32),
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Crea una cuenta para gestionar tu empresa",
                    style: TextStyle(color: Colors.black54, fontSize: 15),
                  ),
                  const SizedBox(height: 25),

                  // 🏢 Datos de empresa
                  const Text(
                    "Información de la empresa",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: nombreEmpresaController,
                    decoration: const InputDecoration(
                      labelText: "Nombre de la empresa",
                      prefixIcon: Icon(Icons.business, color: Colors.green),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v!.isEmpty ? "Ingrese el nombre de la empresa" : null,
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: nitEmpresaController,
                    decoration: const InputDecoration(
                      labelText: "NIT de la empresa",
                      prefixIcon: Icon(Icons.confirmation_number, color: Colors.green),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) => v!.isEmpty ? "Ingrese el NIT" : null,
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: direccionEmpresaController,
                    decoration: const InputDecoration(
                      labelText: "Dirección de la empresa",
                      prefixIcon: Icon(Icons.location_on, color: Colors.green),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v!.isEmpty ? "Ingrese la dirección" : null,
                  ),

                  const SizedBox(height: 25),

                  // 👤 Datos personales
                  const Text(
                    "Datos del administrador",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 10),

                  TextFormField(
                    controller: nombreController,
                    decoration: const InputDecoration(
                      labelText: "Nombre",
                      prefixIcon: Icon(Icons.person, color: Colors.green),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v!.isEmpty ? "Ingrese el nombre" : null,
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: apellidoController,
                    decoration: const InputDecoration(
                      labelText: "Apellido",
                      prefixIcon: Icon(Icons.person_outline, color: Colors.green),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v!.isEmpty ? "Ingrese el apellido" : null,
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: correoController,
                    decoration: const InputDecoration(
                      labelText: "Correo electrónico",
                      prefixIcon: Icon(Icons.email_outlined, color: Colors.green),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => v!.isEmpty ? "Ingrese el correo" : null,
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: "Contraseña",
                      prefixIcon: const Icon(Icons.lock_outline, color: Colors.green),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: Colors.grey,
                        ),
                        onPressed: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (v) => v!.isEmpty ? "Ingrese la contraseña" : null,
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: confirpasswordController,
                    obscureText: _obscureConfirmPassword,
                    decoration: InputDecoration(
                      labelText: "Confirmar contraseña",
                      prefixIcon:
                          const Icon(Icons.lock_person_outlined, color: Colors.green),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: Colors.grey,
                        ),
                        onPressed: () => setState(
                            () => _obscureConfirmPassword = !_obscureConfirmPassword),
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (v) => v!.isEmpty ? "Confirme la contraseña" : null,
                  ),
                  const SizedBox(height: 30),

                  // 🔘 Botón de registro
                  _isLoading
                      ? const CircularProgressIndicator(color: Colors.green)
                      : SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E7D32),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            onPressed: registrarAdministrador,
                            child: const Text(
                              "Registrar Administrador",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                  const SizedBox(height: 20),

                  // 🔙 Enlace para volver al login
                  TextButton.icon(
                    icon: const Icon(Icons.arrow_back, color: Color(0xFF2E7D32)),
                    label: const Text(
                      "Volver al inicio de sesión",
                      style: TextStyle(
                        color: Color(0xFF2E7D32),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
