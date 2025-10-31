import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:inventivo/core/constants/api_config.dart';
import 'package:inventivo/core/utils/session_manager.dart';

class HistorialUsoInsumosPage extends StatefulWidget {
  const HistorialUsoInsumosPage({super.key});

  @override
  State<HistorialUsoInsumosPage> createState() =>
      _HistorialUsoInsumosPageState();
}

class _HistorialUsoInsumosPageState extends State<HistorialUsoInsumosPage> {
  List<dynamic> actividades = [];
  bool isLoading = true;
  int? idEmpresa;

  @override
  void initState() {
    super.initState();
    _cargarDatosIniciales();
  }

  Future<void> _cargarDatosIniciales() async {
    final session = SessionManager();
    final user = await session.getUser();
    if (user != null && user['id_empresa'] != null) {
      idEmpresa = int.tryParse(user['id_empresa'].toString());
    }
    cargarActividades();
  }

  Future<void> cargarActividades() async {
    if (idEmpresa == null) {
      setState(() => isLoading = false);
      return;
    }

    setState(() => isLoading = true);
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.listarUsoInsumos),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"id_empresa": idEmpresa}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            actividades = data['data'] ?? [];
            isLoading = false;
          });
        } else {
          setState(() => isLoading = false);
        }
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
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
      backgroundColor: const Color(0xFFF8FAF8),
      appBar: AppBar(
        title: const Text(
          "Historial de Uso de Insumos",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 3,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
          : actividades.isEmpty
              ? const Center(
                  child: Text(
                    "No hay actividades registradas.",
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                )
              : RefreshIndicator(
                  color: const Color(0xFF2E7D32),
                  onRefresh: cargarActividades,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: actividades.length,
                    itemBuilder: (context, index) {
                      final a = actividades[index];
                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 3,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                a['nombre_insumo'] ?? 'Insumo desconocido',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF2E7D32),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("📅 ${a['fecha'] ?? '-'}"),
                                  Text("👤 ${a['responsable'] ?? '-'}"),
                                ],
                              ),
                              const Divider(height: 15),
                              Text("💧 Cantidad utilizada: ${a['cantidad_utilizada']} ${a['dosificacion']}"),
                              Text("🎯 Objetivo: ${a['objetivo'] ?? '-'}"),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF43A047),
        onPressed: mostrarPopupRegistro,
        icon: const Icon(Icons.add),
        label: const Text("Registrar actividad"),
      ),
    );
  }
}

class RegistrarActividadPopup extends StatefulWidget {
  final VoidCallback onRegistrada;
  const RegistrarActividadPopup({super.key, required this.onRegistrada});

  @override
  State<RegistrarActividadPopup> createState() =>
      _RegistrarActividadPopupState();
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

      final response = await http.post(
        Uri.parse(ApiConfig.listarInsumos),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"id_empresa": int.parse(idEmpresa.toString())}),
      );

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        setState(() => insumos = data['data']);
      }
    } catch (e) {
      debugPrint("Error al cargar insumos: $e");
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

      final insumo =
          insumos.firstWhere((i) => i['nombre_insumo'] == selectedInsumo);
      final idInsumo = insumo['id'];

      final response = await http.post(
        Uri.parse(ApiConfig.registrarUsoInsumo),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "id_insumo": idInsumo,
          "cantidad_utilizada": _cantidadCtrl.text,
          "dosificacion": _dosificacionCtrl.text,
          "objetivo": objetivo == "Otro"
              ? _otroObjetivoCtrl.text
              : objetivo,
          "responsable": _responsableCtrl.text,
          "id_empresa": int.parse(idEmpresa.toString())
        }),
      );

      final data = jsonDecode(response.body);
      setState(() => isLoading = false);

      if (data['success'] == true) {
        Navigator.pop(context);
        widget.onRegistrada();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Actividad registrada y stock actualizado"),
          ),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        "Registrar Actividad Agrícola",
        style: TextStyle(
          color: Color(0xFF2E7D32),
          fontWeight: FontWeight.bold,
        ),
      ),
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
                    child: Text("${i['nombre_insumo']} (${i['medida'] ?? 'Sin medida'})"),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedInsumo = value;
                    final insumo = insumos.firstWhere(
                        (i) => i['nombre_insumo'] == value,
                        orElse: () => {});
                    medida = insumo['cantidad'] ?? '';
                    _medidaCtrl.text = medida ?? '';
                  });
                },
                decoration: const InputDecoration(
                  labelText: "Seleccionar insumo",
                  prefixIcon: Icon(Icons.grass_outlined, color: Color(0xFF43A047)),
                ),
                validator: (v) => v == null ? "Campo obligatorio" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _medidaCtrl,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: "Cantidad disponible",
                  prefixIcon: Icon(Icons.scale, color: Color(0xFF43A047)),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _cantidadCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Cantidad utilizada",
                  prefixIcon: Icon(Icons.local_drink_outlined, color: Color(0xFF43A047)),
                ),
                validator: (v) => v!.isEmpty ? "Campo obligatorio" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _dosificacionCtrl,
                decoration: const InputDecoration(
                  labelText: "Dosificación (ej: 60 ml por mata)",
                  prefixIcon: Icon(Icons.edit_outlined, color: Color(0xFF43A047)),
                ),
                validator: (v) => v!.isEmpty ? "Campo obligatorio" : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: objetivo,
                decoration: const InputDecoration(
                  labelText: "Objetivo de la actividad",
                  prefixIcon: Icon(Icons.flag_outlined, color: Color(0xFF43A047)),
                ),
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
                  decoration: const InputDecoration(
                    labelText: "Especificar otro objetivo",
                    prefixIcon: Icon(Icons.text_fields, color: Color(0xFF43A047)),
                  ),
                  validator: (v) =>
                      mostrarOtroObjetivo && v!.isEmpty ? "Campo obligatorio" : null,
                ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _responsableCtrl,
                decoration: const InputDecoration(
                  labelText: "Responsable",
                  prefixIcon: Icon(Icons.person_outline, color: Color(0xFF43A047)),
                ),
                validator: (v) => v!.isEmpty ? "Campo obligatorio" : null,
              ),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancelar"),
        ),
        ElevatedButton.icon(
          onPressed: isLoading ? null : registrarActividad,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF43A047),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: isLoading
              ? const SizedBox(
                  height: 16, width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.save),
          label: Text(isLoading ? "Guardando..." : "Registrar"),
        ),
      ],
    );
  }
}
