import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:inventivo/core/constants/api_config.dart';
import 'package:inventivo/core/utils/session_manager.dart';

class ListarInsumosPage extends StatefulWidget {
  @override
  _ListarInsumosPageState createState() => _ListarInsumosPageState();
}

class _ListarInsumosPageState extends State<ListarInsumosPage> {
  List<dynamic> insumos = [];
  bool isLoading = true;
  int? idEmpresa;

  @override
  void initState() {
    super.initState();
    _loadEmpresaYListar();
  }

  Future<void> _loadEmpresaYListar() async {
    final session = SessionManager();
    final user = await session.getUser();

    print("🟢 Datos de sesión: $user");

    if (user != null && user["id_empresa"] != null) {
      idEmpresa = user["id_empresa"];
      print("🏢 ID de empresa obtenido: $idEmpresa");
      await listarInsumos();
    } else {
      print("⚠️ No se encontró el ID de empresa en la sesión");
      setState(() => isLoading = false);
    }
  }

  Future<void> listarInsumos() async {
    if (idEmpresa == null) return;

    final url = Uri.parse("${ApiConfig.listarInsumos}?id_empresa=$idEmpresa");
    print("📡 Solicitando a la API: $url");

    final response = await http.get(url);
    print("📥 Respuesta (${response.statusCode}): ${response.body}");

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

  Future<void> _editarInsumo(dynamic insumo) async {
    final nombreCtrl = TextEditingController(text: insumo["nombre_insumo"]);
    final categoriaCtrl = TextEditingController(text: insumo["categoria"]);
    final medidaCtrl = TextEditingController(text: insumo["medida"]);
    final precioCtrl = TextEditingController(text: insumo["precio"].toString());
    final cantidadCtrl = TextEditingController(text: insumo["cantidad"].toString());

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Editar Insumo"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nombreCtrl,
                  decoration: const InputDecoration(labelText: "Nombre del insumo"),
                ),
                TextField(
                  controller: categoriaCtrl,
                  decoration: const InputDecoration(labelText: "Categoría"),
                ),
                TextField(
                  controller: medidaCtrl,
                  decoration: const InputDecoration(labelText: "Medida"),
                ),
                TextField(
                  controller: precioCtrl,
                  decoration: const InputDecoration(labelText: "Precio"),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: cantidadCtrl,
                  decoration: const InputDecoration(labelText: "Cantidad"),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar"),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text("Guardar"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
              ),
              onPressed: () async {
                // Validación básica
                if (nombreCtrl.text.isEmpty || categoriaCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Por favor completa todos los campos.")),
                  );
                  return;
                }

                final response = await http.post(
                  Uri.parse(ApiConfig.editarInsumo),
                  body: {
                    "id": insumo["id"].toString(),
                    "nombre_insumo": nombreCtrl.text,
                    "categoria": categoriaCtrl.text,
                    "medida": medidaCtrl.text,
                    "precio": precioCtrl.text,
                    "cantidad": cantidadCtrl.text,
                  },
                );

                final data = jsonDecode(response.body);
                if (data["success"] == true) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("✅ Insumo actualizado correctamente.")),
                  );
                  await listarInsumos(); // 🔄 Recarga la lista
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(data["message"] ?? "Error al actualizar el insumo.")),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Lista de Insumos")),
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
                        shadowColor: Colors.green.shade100,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        margin: const EdgeInsets.symmetric(
                            vertical: 6, horizontal: 10),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          title: Text(
                            insumo["nombre_insumo"],
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          subtitle: Text(
                            "Categoría: ${insumo["categoria"]}\n"
                            "Medida: ${insumo["medida"]} | Cantidad: ${insumo["cantidad"]} | Precio: ${insumo["precio"]}",
                            style: const TextStyle(height: 1.4, fontSize: 14),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit,
                                color: Color.fromARGB(255, 14, 106, 182), size: 28),
                            tooltip: "Editar insumo",
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
