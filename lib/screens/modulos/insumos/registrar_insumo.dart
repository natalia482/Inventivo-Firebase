import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:inventivo/core/constants/api_config.dart';
import 'package:inventivo/core/utils/session_manager.dart';
import 'package:inventivo/screens/modulos/insumos/insumo_list.dart';

class RegistroInsumoScreen extends StatefulWidget {
  const RegistroInsumoScreen({Key? key}) : super(key: key);

  @override
  State<RegistroInsumoScreen> createState() => _RegistroInsumoScreenState();
}

class _RegistroInsumoScreenState extends State<RegistroInsumoScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController categoriaController = TextEditingController();
  final TextEditingController precioController = TextEditingController();
  final TextEditingController medidaController = TextEditingController();
  final TextEditingController cantidadController = TextEditingController();

  bool _isLoading = false;
  int? idEmpresa;

  @override
  void initState() {
    super.initState();
    _loadEmpresa(); // Cargar el id de la empresa al iniciar
  }

  Future<void> _loadEmpresa() async {
    final session = SessionManager();
    final user = await session.getUser();
    if (user != null) {
      setState(() {
        idEmpresa = user['id_empresa'];
      });
    }
  }

  Future<void> registrarInsumo() async {
    if (!_formKey.currentState!.validate()) return;
    if (idEmpresa == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error: no se encontró la empresa del usuario.")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.registrarInsumo),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "nombre_insumo": nombreController.text.trim(),
          "categoria": categoriaController.text.trim(),
          "precio": double.tryParse(precioController.text.trim()) ?? 0,
          "medida": medidaController.text.trim(),
          "cantidad": int.tryParse(cantidadController.text.trim()) ?? 0,
          "id_empresa": idEmpresa, // 🔹 Se envía el ID de la empresa logueada
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data["success"] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Insumo registrado correctamente."),
            backgroundColor: Colors.green,
          ),
        );
        _formKey.currentState?.reset();
        //Espera un segundo antes de redirigir
        await Future.delayed(const Duration(seconds: 1));

        //Redirigir a la pagina Lista de insumos 
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>  ListarInsumosPage()),);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data["message"] ?? "Error al registrar insumo."),
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
      appBar: AppBar(title: const Text("Registrar Insumo")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: idEmpresa == null
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: nombreController,
                      decoration: const InputDecoration(labelText: "Nombre del insumo"),
                      validator: (value) =>
                          value!.isEmpty ? "Ingrese el nombre del insumo" : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: categoriaController,
                      decoration: const InputDecoration(labelText: "Categoría"),
                      validator: (value) =>
                          value!.isEmpty ? "Ingrese la categoría" : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: precioController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Precio"),
                      validator: (value) =>
                          value!.isEmpty ? "Ingrese el precio" : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: medidaController,
                      decoration: const InputDecoration(labelText: "Medida (ej: kg, l, unidad)"),
                      validator: (value) =>
                          value!.isEmpty ? "Ingrese la medida" : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: cantidadController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Cantidad"),
                      validator: (value) =>
                          value!.isEmpty ? "Ingrese la cantidad" : null,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _isLoading ? null : registrarInsumo,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Registrar Insumo"),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
