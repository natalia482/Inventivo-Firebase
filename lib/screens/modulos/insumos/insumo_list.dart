import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:inventivo/core/constants/api_config.dart';
import 'package:inventivo/core/utils/session_manager.dart';

class InsumosPage extends StatefulWidget {
  const InsumosPage({super.key});

  @override
  State<InsumosPage> createState() => _InsumosPageState();
}

class _InsumosPageState extends State<InsumosPage> {
  List<dynamic> insumos = [];
  bool isLoading = true;
  int? idEmpresa;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController categoriaOtroController = TextEditingController();
  final TextEditingController precioController = TextEditingController();
  final TextEditingController cantidadController = TextEditingController();

  String? categoriaSeleccionada;
  String? medidaSeleccionada;

  final List<String> medidas = ["KG", "LB", "LITRO", "MILILITRO"];
  final List<String> categorias = ["Fertilizante", "Abono", "Matamaleza", "Otro"];

  @override
  void initState() {
    super.initState();
    _loadEmpresaYListar();
  }

  Future<void> _loadEmpresaYListar() async {
    final session = SessionManager();
    final user = await session.getUser();

    if (user != null && user["id_empresa"] != null) {
      idEmpresa = user["id_empresa"];
      await listarInsumos();
    } else {
      setState(() => isLoading = false);
    }
  }

  Future<void> listarInsumos() async {
    if (idEmpresa == null) return;
    final url = Uri.parse("${ApiConfig.listarInsumos}?id_empresa=$idEmpresa");

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data["success"]) {
        setState(() {
          insumos = data["data"];
          isLoading = false;
        });
      }
    }
  }

  // 🔹 Mostrar popup para registrar insumo
  void _mostrarPopupRegistro() {
    categoriaSeleccionada = null;
    medidaSeleccionada = null;
    categoriaOtroController.clear();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              title: const Text("Registrar Insumo", style: TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nombreController,
                        decoration: const InputDecoration(labelText: "Nombre del insumo"),
                        validator: (value) => value!.isEmpty ? "Ingrese el nombre" : null,
                      ),
                      DropdownButtonFormField<String>(
                        value: categoriaSeleccionada,
                        decoration: const InputDecoration(labelText: "Categoría"),
                        items: categorias
                            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (value) {
                          setStateDialog(() {
                            categoriaSeleccionada = value;
                          });
                        },
                        validator: (value) => value == null ? "Seleccione una categoría" : null,
                      ),
                      if (categoriaSeleccionada == "Otro")
                        TextFormField(
                          controller: categoriaOtroController,
                          decoration: const InputDecoration(labelText: "Especifique otra categoría"),
                          validator: (value) => categoriaSeleccionada == "Otro" && value!.isEmpty
                              ? "Ingrese la categoría"
                              : null,
                        ),
                      DropdownButtonFormField<String>(
                        value: medidaSeleccionada,
                        decoration: const InputDecoration(labelText: "Medida"),
                        items: medidas
                            .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                            .toList(),
                        onChanged: (value) {
                          setStateDialog(() {
                            medidaSeleccionada = value;
                          });
                        },
                        validator: (value) => value == null ? "Seleccione una medida" : null,
                      ),
                      TextFormField(
                        controller: cantidadController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: "Cantidad del insumo"),
                        validator: (value) => value!.isEmpty ? "Ingrese la cantidad" : null,
                      ),
                      TextFormField(
                        controller: precioController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: "Precio"),
                        validator: (value) => value!.isEmpty ? "Ingrese el precio" : null,
                      ),
               
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  onPressed: registrarInsumo,
                  child: const Text("Guardar"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> registrarInsumo() async {
    if (!_formKey.currentState!.validate()) return;
    if (idEmpresa == null) return;

    final categoriaFinal = categoriaSeleccionada == "Otro"
        ? categoriaOtroController.text.trim()
        : categoriaSeleccionada;

    final response = await http.post(
      Uri.parse(ApiConfig.registrarInsumo),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "nombre_insumo": nombreController.text.trim(),
        "categoria": categoriaFinal,
        "precio": double.tryParse(precioController.text.trim()) ?? 0,
        "medida": medidaSeleccionada,
        "cantidad": int.tryParse(cantidadController.text.trim()) ?? 0,
        "id_empresa": idEmpresa,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data["success"] == true) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Insumo registrado correctamente.")),
      );
      nombreController.clear();
      precioController.clear();
      cantidadController.clear();
      listarInsumos();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data["message"] ?? "Error al registrar el insumo")),
      );
    }
  }

  // 🔹 Popup para editar insumo
  Future<void> _editarInsumo(dynamic insumo) async {
  String? medidaEdit = insumo["medida"]?.toString().toUpperCase();
  String? categoriaEdit =
      categorias.contains(insumo["categoria"]) ? insumo["categoria"] : "Otro";

  final nombreCtrl = TextEditingController(text: insumo["nombre_insumo"]);
  final categoriaOtroCtrl = TextEditingController(text: categoriaEdit == "Otro" ? insumo["categoria"] : "");
  final precioCtrl = TextEditingController(text: insumo["precio"].toString());
  final cantidadCtrl = TextEditingController(text: insumo["cantidad"].toString());

  await showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setStateDialog) {
        return AlertDialog(
          title: const Text("Editar Insumo"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                    controller: nombreCtrl,
                    decoration: const InputDecoration(labelText: "Nombre")),
                DropdownButtonFormField<String>(
                  value: categoriaEdit,
                  decoration: const InputDecoration(labelText: "Categoría"),
                  items: categorias
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (value) {
                    setStateDialog(() {
                      categoriaEdit = value;
                    });
                  },
                ),
                if (categoriaEdit == "Otro")
                  TextField(
                    controller: categoriaOtroCtrl,
                    decoration:
                        const InputDecoration(labelText: "Especifique otra categoría"),
                  ),
                DropdownButtonFormField<String>(
                  value: medidaEdit,
                  decoration: const InputDecoration(labelText: "Medida"),
                  items: medidas
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (value) {
                    setStateDialog(() {
                      medidaEdit = value;
                    });
                  },
                ),
                TextField(
                    controller: cantidadCtrl,
                    decoration: const InputDecoration(labelText: "Cantidad")),
                TextField(
                    controller: precioCtrl,
                    decoration: const InputDecoration(labelText: "Precio")),
                
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () async {
                final categoriaFinal = categoriaEdit == "Otro"
                    ? categoriaOtroCtrl.text.trim()
                    : categoriaEdit;

                final response = await http.post(
                  Uri.parse(ApiConfig.editarInsumo),
                  body: {
                    "id": insumo["id"].toString(),
                    "nombre_insumo": nombreCtrl.text,
                    "categoria": categoriaFinal,
                    "medida": medidaEdit,
                    "precio": precioCtrl.text,
                    "cantidad": cantidadCtrl.text,
                  },
                );

                final data = jsonDecode(response.body);
                if (data["success"] == true) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("✅ Insumo actualizado.")),
                  );
                  listarInsumos();
                }
              },
              child: const Text("Guardar"),
            ),
          ],
        );
      },
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    // Tu cuerpo original sin cambios
    return Scaffold(
      appBar: AppBar(
        title: const Text("Insumos"),
        backgroundColor: Colors.green,
        actions: [
          TextButton.icon(
            onPressed: _mostrarPopupRegistro,
            icon: const Icon(Icons.add_circle, color: Colors.white),
            label: const Text("Registrar insumo", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : insumos.isEmpty
              ? const Center(child: Text("No hay insumos registrados"))
              : RefreshIndicator(
                  onRefresh: listarInsumos,
                  child: ListView.builder(
                    itemCount: insumos.length,
                    itemBuilder: (context, index) {
                      final insumo = insumos[index];
                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: ListTile(
                          title: Text(insumo["nombre_insumo"], style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            "Categoría: ${insumo["categoria"]}\n"
                            "Medida: ${insumo["medida"]} | Cantidad: ${insumo["cantidad"]} | Precio: ${insumo["precio"]}",
                            style: const TextStyle(height: 1.4),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _editarInsumo(insumo),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}