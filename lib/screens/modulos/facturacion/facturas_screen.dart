import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:inventivo/core/constants/api_config.dart';

class FacturasScreen extends StatefulWidget {
  final int idEmpresa;
  final int idVendedor;

  const FacturasScreen({
    super.key,
    required this.idEmpresa,
    required this.idVendedor,
  });

  @override
  State<FacturasScreen> createState() => _FacturasScreenState();
}

class _FacturasScreenState extends State<FacturasScreen> {
  List facturas = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    obtenerFacturas();
  }

  Future<void> obtenerFacturas() async {
    setState(() => isLoading = true);
    final url = Uri.parse("${ApiConfig.listarFacturas}?id_empresa=${widget.idEmpresa}");
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            facturas = data['data'];
          });
        }
      }
    } catch (e) {
      debugPrint("Error al obtener facturas: $e");
    }
    setState(() => isLoading = false);
  }

  Future<void> crearFactura(Map<String, dynamic> factura) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.registrarFactura),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(factura),
      );
      final data = jsonDecode(response.body);

      if (data["success"] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Factura creada correctamente")),
        );
        obtenerFacturas();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ ${data['message']}")),
        );
      }
    } catch (e) {
      debugPrint("Error al crear factura: $e");
    }
  }

  Future<void> eliminarFactura(int id) async {
    try {
      final response = await http.delete(
        Uri.parse("${ApiConfig.eliminarFactura}?id=$id"),
      );
      final data = jsonDecode(response.body);
      if (data["success"] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("🗑 Factura eliminada")),
        );
        obtenerFacturas();
      }
    } catch (e) {
      debugPrint("Error al eliminar factura: $e");
    }
  }

  void mostrarFormularioFactura({Map<String, dynamic>? factura}) {
    final numeroController =
        TextEditingController(text: factura?['numero_factura'] ?? '');
    final totalController =
        TextEditingController(text: factura?['total']?.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(factura == null ? "🧾 Nueva Factura" : "✏️ Editar Factura"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: numeroController,
                  decoration: const InputDecoration(labelText: "Número de factura"),
                ),
                TextField(
                  controller: totalController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Total"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () {
                if (numeroController.text.isEmpty ||
                    totalController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Completa todos los campos")),
                  );
                  return;
                }

                final nuevaFactura = {
                  "numero_factura": numeroController.text,
                  "id_empresa": widget.idEmpresa,
                  "id_vendedor": widget.idVendedor,
                  "total": double.parse(totalController.text),
                  "detalles": [], // Por ahora vacío
                };

                crearFactura(nuevaFactura);
                Navigator.pop(context);
              },
              child: Text(factura == null ? "Guardar" : "Actualizar"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("📄 Facturas")),
      floatingActionButton: FloatingActionButton(
        onPressed: () => mostrarFormularioFactura(),
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : facturas.isEmpty
              ? const Center(child: Text("No hay facturas registradas"))
              : ListView.builder(
                  itemCount: facturas.length,
                  itemBuilder: (context, index) {
                    final factura = facturas[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        title: Text("Factura #${factura['numero_factura']}"),
                        subtitle: Text(
                          "Total: \$${factura['total']}\nFecha: ${factura['fecha_emision']}",
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.orange),
                              onPressed: () => mostrarFormularioFactura(factura: factura),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => eliminarFactura(int.parse(factura['id'].toString())),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
