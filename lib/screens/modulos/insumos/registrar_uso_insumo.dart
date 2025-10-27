import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:inventivo/core/constants/api_config.dart';
import 'package:inventivo/core/utils/session_manager.dart';

class RegistrarUsoInsumoPage extends StatefulWidget {
  @override
  _RegistrarUsoInsumoPageState createState() => _RegistrarUsoInsumoPageState();
}

class _RegistrarUsoInsumoPageState extends State<RegistrarUsoInsumoPage> {
  final _formKey = GlobalKey<FormState>();
  List<dynamic> insumos = [];
  String? insumoSeleccionado;
  int? idEmpresa;
  String? responsable;

  final fechaCtrl = TextEditingController();
  final cantidadCtrl = TextEditingController();
  final dosificacionCtrl = TextEditingController();
  final objetivoCtrl = TextEditingController();

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _cargarDatosIniciales();
  }

  Future<void> _cargarDatosIniciales() async {
    final session = SessionManager();
    final user = await session.getUser();
    if (user != null) {
      idEmpresa = user["id_empresa"];
      responsable = "${user["nombre"]} ${user["apellido"]}";
      await _obtenerInsumos();
    }
  }

  Future<void> _obtenerInsumos() async {
    final url = Uri.parse("${ApiConfig.listarInsumos}?id_empresa=$idEmpresa");
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data["success"]) {
        setState(() {
          insumos = data["data"];
        });
      }
    }
  }

  Future<void> registrarUsoInsumo() async {
  final url = Uri.parse(ApiConfig.registrarUsoInsumo);

  final body = jsonEncode({
    "fecha": fechaCtrl.text,
    "id_insumo": insumoSeleccionado,
    "cantidad_utilizada": cantidadCtrl.text,
    "dosificacion": dosificacionCtrl.text,
    "objetivo": objetivoCtrl.text,
    "responsable": responsable,
    "id_empresa": idEmpresa,
  });

  final response = await http.post(
    url,
    headers: {"Content-Type": "application/json"},
    body: body,
  );

  final data = jsonDecode(response.body);

  if (data["success"] == true) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(data["message"])),
    );
    _cargarDatosIniciales(); // recarga la lista de movimientos
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(data["message"])),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Registrar Uso de Insumo")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: fechaCtrl,
                      decoration: const InputDecoration(labelText: "Fecha"),
                      readOnly: true,
                      onTap: () async {
                        final fecha = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2023),
                          lastDate: DateTime(2030),
                        );
                        if (fecha != null) {
                          fechaCtrl.text = fecha.toIso8601String().split("T")[0];
                        }
                      },
                      validator: (v) => v!.isEmpty ? "Seleccione la fecha" : null,
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: insumoSeleccionado,
                      items: insumos.map<DropdownMenuItem<String>>((i) {
                        return DropdownMenuItem<String>(
                          value: i["id"].toString(),
                          child: Text(i["nombre_insumo"]),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => insumoSeleccionado = v),
                      decoration: const InputDecoration(labelText: "Seleccione el insumo"),
                      validator: (v) => v == null ? "Seleccione un insumo" : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: cantidadCtrl,
                      decoration: const InputDecoration(labelText: "Cantidad utilizada"),
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? "Ingrese la cantidad" : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: dosificacionCtrl,
                      decoration: const InputDecoration(labelText: "Dosificación (por mata o cama)"),
                      validator: (v) => v!.isEmpty ? "Ingrese la dosificación" : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: objetivoCtrl,
                      decoration: const InputDecoration(labelText: "Objetivo de la actividad"),
                      validator: (v) => v!.isEmpty ? "Ingrese el objetivo" : null,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text("Registrar uso"),
                      onPressed: registrarUsoInsumo,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
