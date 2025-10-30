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

    try {
      final response = await http.get(Uri.parse(ApiConfig.listarUsoInsumos));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            actividades = data['data'];
            isLoading = false;
          });
        } else {
          setState(() => isLoading = false);
        }
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("Error al cargar actividades: $e");
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
                        "📅 ${a['fecha']}\n💧 ${a['cantidad_utilizada']} ${a['dosificacion']}\n🎯 ${a['objetivo']}\n👤 ${a['responsable']}",
                      ),
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
  final TextEditingController _medidaCtrl = TextEditingController();

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
    try {
      final session = SessionManager();
      final user = await session.getUser();
      final idEmpresa = user?['id_empresa'];

      debugPrint("🧾 Cargando insumos para empresa: $idEmpresa");

      if (idEmpresa == null || idEmpresa.toString().isEmpty) {
        debugPrint("⚠️ No se encontró id_empresa en sesión");
        return;
      }

      final response = await http.post(
        Uri.parse(ApiConfig.listarInsumos),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"id_empresa": int.parse(idEmpresa.toString())}),
      );

      debugPrint("📦 Respuesta listarInsumos: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() => insumos = data['data']);
        } else {
          debugPrint("Error backend: ${data['message']}");
        }
      } else {
        debugPrint("Error HTTP: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Excepción cargarInsumos: $e");
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

    try {
      final session = SessionManager();
      final user = await session.getUser();

      final idEmpresa = user?['id_empresa'];
      debugPrint("🧠 Datos del usuario: $user");

      if (idEmpresa == null || idEmpresa.toString().isEmpty) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Error: Falta el ID de la empresa.")));
        setState(() => isLoading = false);
        return;
      }

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
          "id_empresa": int.parse(idEmpresa.toString())
        }),
      );

      final data = jsonDecode(response.body);
      debugPrint("📤 Respuesta registrarUsoInsumo: ${response.body}");
      setState(() => isLoading = false);

      if (data['success'] == true) {
        Navigator.pop(context);
        widget.onRegistrada();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Actividad registrada y stock actualizado")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(" Error: ${data['message']}")),
        );
      }
    } catch (e) {
      debugPrint("Excepción registrarActividad: $e");
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al registrar la actividad.")),
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
              // Dropdown de insumos
              DropdownButtonFormField<String>(
                value: selectedInsumo,
                items: insumos.map<DropdownMenuItem<String>>((i) {
                  return DropdownMenuItem<String>(
                    value: i['nombre_insumo'],
                    child: Text("${i['nombre_insumo']} (${i['medida'] ?? 'Sin medida'})"),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedInsumo = value;
                    final insumo = insumos.firstWhere(
                      (i) => i['nombre_insumo'] == value,
                      orElse: () => {},
                    );
                    medida = insumo['cantidad'] ?? '';
                    _medidaCtrl.text = medida ?? '';
                  });
                },
                decoration: const InputDecoration(labelText: "Seleccionar insumo"),
                validator: (v) => v == null ? "Campo obligatorio" : null,
              ),

              const SizedBox(height: 10),

              // Campo medida
              TextFormField(
                controller: _medidaCtrl,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: "Cantidad disponible",
                  prefixIcon: Icon(Icons.scale),
                ),
              ),

              const SizedBox(height: 10),

              TextFormField(
                controller: _cantidadCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Cantidad utilizada"),
                validator: (v) => v!.isEmpty ? "Campo obligatorio" : null,
              ),
              TextFormField(
                controller: _dosificacionCtrl,
                decoration:
                    const InputDecoration(labelText: "Dosificación (ej: 60 ml por mata)"),
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
