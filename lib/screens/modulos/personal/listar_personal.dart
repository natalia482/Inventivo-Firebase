import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:inventivo/core/constants/api_config.dart';

class ListaTrabajadores extends StatefulWidget {
  final int idEmpresa;

  const ListaTrabajadores({super.key, required this.idEmpresa});

  @override
  State<ListaTrabajadores> createState() => _ListaTrabajadoresState();
}

class _ListaTrabajadoresState extends State<ListaTrabajadores> {
  List trabajadores = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    obtenerTrabajadores();
  }

  Future<void> obtenerTrabajadores() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.obtenerTrabajadores(widget.idEmpresa)),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is Map && data.containsKey('data')) {
          setState(() {
            trabajadores = data['data'] ?? [];
            isLoading = false;
          });
        } else if (data is List) {
          setState(() {
            trabajadores = data;
            isLoading = false;
          });
        } else {
          setState(() {
            trabajadores = [];
            isLoading = false;
          });
          debugPrint("Estructura JSON no esperada: $data");
        }
      } else {
        throw Exception("Error al obtener trabajadores (${response.statusCode})");
      }
    } catch (e) {
      debugPrint("Error al obtener trabajadores: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> cambiarEstado(int id, String estadoActual) async {
    final nuevoEstado = estadoActual == "ACTIVO" ? "INACTIVO" : "ACTIVO";

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.cambiarEstado),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "id": id.toString(),
          "estado": nuevoEstado,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data["success"] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Estado cambiado a $nuevoEstado")),
          );
          obtenerTrabajadores();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("❌ ${data["message"] ?? "No se pudo cambiar el estado."}")),
          );
        }
      } else {
        debugPrint("Error HTTP ${response.statusCode}: ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error en la conexión con el servidor.")),
        );
      }
    } catch (e) {
      debugPrint("Error al cambiar estado: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al cambiar estado.")),
      );
    }
  }

  Future<void> eliminarTrabajador(int id) async {
    bool confirmar = await mostrarConfirmacion(
      context,
      "¿Eliminar trabajador?",
      "Esta acción no se puede deshacer.",
    );

    if (!confirmar) return;

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.eliminarTrabajador),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"id": id}),
      );

      final data = jsonDecode(response.body);
      if (data["success"] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Trabajador eliminado correctamente")),
        );
        obtenerTrabajadores();
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  Future<bool> mostrarConfirmacion(
      BuildContext context, String titulo, String mensaje) async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titulo),
        content: Text(mensaje),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancelar")),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("Eliminar")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Lista de Trabajadores")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : trabajadores.isEmpty
              ? const Center(child: Text("No hay trabajadores registrados"))
              : ListView.builder(
                  itemCount: trabajadores.length,
                  itemBuilder: (context, index) {
                    final trabajador = trabajadores[index];
                    final estado = trabajador["estado"]?.toUpperCase() ?? "ACTIVO";

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              estado == "ACTIVO" ? Colors.green : Colors.red,
                          child: Icon(Icons.person,
                              color: Colors.white),
                        ),
                        title: Text("${trabajador["nombre"]} ${trabajador["apellido"]}"),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Correo: ${trabajador["correo"]}"),
                            const SizedBox(height: 4),
                            Text(
                              "Estado: $estado",
                              style: TextStyle(
                                color: estado == "ACTIVO" ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                estado == "ACTIVO"
                                    ? Icons.toggle_on
                                    : Icons.toggle_off,
                                color: estado == "ACTIVO"
                                    ? Colors.green
                                    : Colors.red,
                                size: 36,
                              ),
                              onPressed: () => cambiarEstado(trabajador["id"], estado),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => eliminarTrabajador(trabajador["id"]),
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
