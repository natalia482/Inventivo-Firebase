import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:inventivo/core/constants/api_config.dart';
import 'package:inventivo/services/auth_service.dart'; // Importar el servicio actualizado

class RegistroAdminScreen extends StatefulWidget {
  // Nota: Este archivo debería ser renombrado a 'registro_propietario_screen.dart'
  // pero mantengo el nombre de la clase por compatibilidad con tu 'main.dart'
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

  final AuthService _authService = AuthService(); // Usar el servicio
  bool _isLoading = false;

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
      // Llamar al nuevo método del servicio
      final response = await _authService.registrarPropietario(
          nombre: nombreController.text.trim(),
          apellido: apellidoController.text.trim(),
          correo: correoController.text.trim(),
          password: passwordController.text.trim(),
          nombreEmpresa: nombreEmpresaController.text.trim(),
          nit: nitEmpresaController.text.trim(),
          direccionEmpresa: direccionEmpresaController.text.trim()
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
        
        // Regresar al Login
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Registrar Propietario y Empresa")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // ... (Campos de texto existentes)
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
                decoration: const InputDecoration(labelText: "Dirección (Sede Principal)"),
                validator: (value) =>
                    value!.isEmpty ? "Ingrese la dirección de la sede principal" : null,
              ),
              const SizedBox(height: 20),

              // 👤 Datos del administrador
              TextFormField(
                controller: nombreController,
                decoration: const InputDecoration(labelText: "Nombre (Propietario)"),
                validator: (value) =>
                    value!.isEmpty ? "Ingrese el nombre" : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: apellidoController,
                decoration: const InputDecoration(labelText: "Apellido (Propietario)"),
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
                onPressed: _isLoading ? null : registrarPropietario,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Registrar"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}