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

  Future<void> registrarAdministrador() async {
    if (!_formKey.currentState!.validate()) return;

    // ✅ Validar que las contraseñas coincidan antes de enviar
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
        final idUsuario = data["id_usuario"];
        final idEmpresa = data["id_empresa"];

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Administrador y empresa creados.",
            ),
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
    return Scaffold(
      appBar: AppBar(title: const Text("Registrar Administrador")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // 🏢 Datos de la empresa
              TextFormField(
                controller: nombreEmpresaController,
                decoration: const InputDecoration(labelText: "Nombre de la empresa"),
                validator: (value) =>
                    value!.isEmpty ? "Ingrese el nombre de la empresa" : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: nitEmpresaController,
                decoration: const InputDecoration(labelText: "NIT de la empresa"),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value!.isEmpty ? "Ingrese el NIT de la empresa" : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: direccionEmpresaController,
                decoration: const InputDecoration(labelText: "Dirección de la empresa"),
                validator: (value) =>
                    value!.isEmpty ? "Ingrese la dirección de la empresa" : null,
              ),
              const SizedBox(height: 20),

              // 👤 Datos del administrador
              TextFormField(
                controller: nombreController,
                decoration: const InputDecoration(labelText: "Nombre"),
                validator: (value) =>
                    value!.isEmpty ? "Ingrese el nombre" : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: apellidoController,
                decoration: const InputDecoration(labelText: "Apellido"),
                validator: (value) =>
                    value!.isEmpty ? "Ingrese el apellido" : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: correoController,
                decoration: const InputDecoration(labelText: "Correo"),
                keyboardType: TextInputType.emailAddress,
                validator: (value) =>
                    value!.isEmpty ? "Ingrese el correo" : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Contraseña"),
                validator: (value) =>
                    value!.isEmpty ? "Ingrese la contraseña" : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: confirpasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Confirmar contraseña"),
                validator: (value) =>
                    value!.isEmpty ? "Confirme la contraseña" : null,
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _isLoading ? null : registrarAdministrador,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Registrar Administrador"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
