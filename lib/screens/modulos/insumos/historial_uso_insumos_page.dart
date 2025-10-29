import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:inventivo/core/constants/api_config.dart';
import 'package:inventivo/core/utils/session_manager.dart';

class HistorialUsoInsumosPage extends StatefulWidget {
  const HistorialUsoInsumosPage({super.key});

  @override
  State<HistorialUsoInsumosPage> createState() => _HistorialUsoInsumosPageState();
}

class _HistorialUsoInsumosPageState extends State<HistorialUsoInsumosPage> {
  List<dynamic> actividades = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    cargarActividades();
  }

  Future<void> cargarActividades() async {
    setState(() => isLoading = true);
    final response = await http.get(Uri.parse(ApiConfig.listarUsoInsumos));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success']) {
        setState(() {
          actividades = data['data'];
          isLoading = false;
        });
      }
    } else {
      setState(() => isLoading = false);
    }
  }

  void mostrarPopupRegistro() {
    showDialog(
      context: context,
      builder: (context) => RegistrarActividadPopup(
        onRegistrada: () => cargarActividades(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Historial de Uso de Insumos")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : actividades.isEmpty
              ? const Center(child: Text("No hay actividades registradas."))
              : ListView.builder(
                  itemCount: actividades.length,
                  itemBuilder: (context, index) {
                    final a = actividades[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        title: Text(a['nombre_insumo'] ?? 'Insumo'),
                        subtitle: Text(
                            "📅 ${a['fecha']}\n💧 ${a['cantidad_utilizada']} ${a['dosificacion']}\n🎯 ${a['objetivo']}\n👤 ${a['responsable']}"),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: mostrarPopupRegistro,
        icon: const Icon(Icons.add),
        label: const Text("Registrar Actividad Agrícola"),
      ),
    );
  }
}

class RegistrarActividadPopup extends StatefulWidget {
  final VoidCallback onRegistrada;
  const RegistrarActividadPopup({super.key, required this.onRegistrada});

  @override
  State<RegistrarActividadPopup> createState() => _RegistrarActividadPopupState();
}

class _RegistrarActividadPopupState extends State<RegistrarActividadPopup> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _cantidadCtrl = TextEditingController();
  final TextEditingController _dosificacionCtrl = TextEditingController();
  final TextEditingController _responsableCtrl = TextEditingController();
  final TextEditingController _otroObjetivoCtrl = TextEditingController();

  bool isLoading = false;
  bool mostrarOtroObjetivo = false;
  List<dynamic> insumos = [];
  String? selectedInsumo;
  String? medida;
  String? objetivo;

  @override
  void initState() {
    super.initState();
    cargarInsumos();
  }

  Future<void> cargarInsumos() async {
    final response = await http.get(Uri.parse(ApiConfig.listarInsumos));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success']) {
        setState(() => insumos = data['data']);
      }
    }
  }

  Future<void> registrarActividad() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedInsumo == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Selecciona un insumo")));
      return;
    }

    setState(() => isLoading = true);

    final session = SessionManager();
    final user = await session.getUser();
    final idEmpresa = user?['id_empresa'] ?? '';

    final insumo = insumos.firstWhere((i) => i['nombre_insumo'] == selectedInsumo);
    final idInsumo = insumo['id'];

    final response = await http.post(
      Uri.parse(ApiConfig.registrarUsoInsumo),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "id_insumo": idInsumo,
        "cantidad_utilizada": _cantidadCtrl.text,
        "dosificacion": _dosificacionCtrl.text,
        "objetivo": objetivo == "Otro" ? _otroObjetivoCtrl.text : objetivo,
        "responsable": _responsableCtrl.text,
        "id_empresa": idEmpresa
      }),
    );

    final data = jsonDecode(response.body);
    setState(() => isLoading = false);

    if (data['success']) {
      Navigator.pop(context);
      widget.onRegistrada();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Actividad registrada correctamente")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error: ${data['message']}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Registrar Actividad Agrícola"),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: selectedInsumo,
                items: insumos.map<DropdownMenuItem<String>>((i) {
                  return DropdownMenuItem<String>(
                    value: i['nombre_insumo'],
                    child: Text(i['nombre_insumo']),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedInsumo = value;
                    final insumo = insumos.firstWhere(
                        (i) => i['nombre_insumo'] == value,
                        orElse: () => {});
                    medida = insumo['medida'] ?? '';
                  });
                },
                decoration: const InputDecoration(labelText: "Seleccionar insumo"),
                validator: (v) => v == null ? "Campo obligatorio" : null,
              ),
              if (medida != null && medida!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text("Medida del insumo: $medida"),
                ),
              TextFormField(
                controller: _cantidadCtrl,
                decoration: const InputDecoration(labelText: "Cantidad utilizada"),
                validator: (v) => v!.isEmpty ? "Campo obligatorio" : null,
              ),
              TextFormField(
                controller: _dosificacionCtrl,
                decoration: const InputDecoration(labelText: "Dosificación (ej: 60 ml por mata)"),
                validator: (v) => v!.isEmpty ? "Campo obligatorio" : null,
              ),
              DropdownButtonFormField<String>(
                value: objetivo,
                decoration: const InputDecoration(labelText: "Objetivo de la actividad"),
                items: const [
                  DropdownMenuItem(value: "Fertilización", child: Text("Fertilización")),
                  DropdownMenuItem(value: "Abono", child: Text("Abono")),
                  DropdownMenuItem(value: "Matamaleza", child: Text("Matamaleza")),
                  DropdownMenuItem(value: "Otro", child: Text("Otro")),
                ],
                onChanged: (val) {
                  setState(() {
                    objetivo = val;
                    mostrarOtroObjetivo = val == "Otro";
                  });
                },
                validator: (v) => v == null ? "Campo obligatorio" : null,
              ),
              if (mostrarOtroObjetivo)
                TextFormField(
                  controller: _otroObjetivoCtrl,
                  decoration: const InputDecoration(labelText: "Especificar otro objetivo"),
                  validator: (v) => mostrarOtroObjetivo && v!.isEmpty
                      ? "Campo obligatorio"
                      : null,
                ),
              TextFormField(
                controller: _responsableCtrl,
                decoration: const InputDecoration(labelText: "Responsable"),
                validator: (v) => v!.isEmpty ? "Campo obligatorio" : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
        ElevatedButton(
          onPressed: isLoading ? null : registrarActividad,
          child: isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text("Registrar"),
        ),
      ],
    );
  }
}
