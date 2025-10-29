import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:inventivo/core/constants/api_config.dart';
import 'package:inventivo/core/utils/session_manager.dart';

class ListaTrabajadores extends StatefulWidget {
  final int idEmpresa;

  const ListaTrabajadores({super.key, required this.idEmpresa});

  @override
  State<ListaTrabajadores> createState() => _ListaTrabajadoresState();
}

class _ListaTrabajadoresState extends State<ListaTrabajadores> {
  List trabajadores = [];
  bool isLoading = true;
  final SessionManager _session = SessionManager();

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
        } else {
          setState(() {
            trabajadores = [];
            isLoading = false;
          });
        }
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
        body: jsonEncode({"id": id, "estado": nuevoEstado}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["success"] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Estado cambiado a $nuevoEstado")),
          );
          obtenerTrabajadores();
        }
      }
    } catch (e) {
      debugPrint("Error al cambiar estado: $e");
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

  /// 🔹 Popup para registrar trabajador
  void mostrarPopupRegistro() {
    final _formKey = GlobalKey<FormState>();
    final _nombre = TextEditingController();
    final _apellido = TextEditingController();
    final _correo = TextEditingController();
    final _password = TextEditingController();
    final _confirmarPassword = TextEditingController();
    bool cargando = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text("Registrar Trabajador"),
            content: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _nombre,
                      decoration: const InputDecoration(labelText: "Nombre"),
                      validator: (v) => v!.isEmpty ? "Ingrese el nombre" : null,
                    ),
                    TextFormField(
                      controller: _apellido,
                      decoration: const InputDecoration(labelText: "Apellido"),
                      validator: (v) => v!.isEmpty ? "Ingrese el apellido" : null,
                    ),
                    TextFormField(
                      controller: _correo,
                      decoration: const InputDecoration(labelText: "Correo"),
                      validator: (v) =>
                          v!.isEmpty || !v.contains('@') ? "Correo inválido" : null,
                    ),
                    TextFormField(
                      controller: _password,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: "Contraseña"),
                      validator: (v) =>
                          v!.length < 6 ? "Debe tener al menos 6 caracteres" : null,
                    ),
                    TextFormField(
                      controller: _confirmarPassword,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: "Confirmar contraseña"),
                      validator: (v) =>
                          v != _password.text ? "Las contraseñas no coinciden" : null,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancelar"),
              ),
              ElevatedButton(
                onPressed: cargando
                    ? null
                    : () async {
                        if (!_formKey.currentState!.validate()) return;

                        setStateDialog(() => cargando = true);

                        final user = await _session.getUser();
                        final idEmpresa = user?['id_empresa'] ?? widget.idEmpresa;

                        final response = await http.post(
                          Uri.parse(ApiConfig.registroTrabajador),
                          headers: {"Content-Type": "application/json"},
                          body: jsonEncode({
                            "nombre": _nombre.text,
                            "apellido": _apellido.text,
                            "correo": _correo.text,
                            "password": _password.text,
                            "id_empresa": idEmpresa.toString(),
                          }),
                        );

                        final data = jsonDecode(response.body);
                        setStateDialog(() => cargando = false);

                        if (data["success"] == true) {
                          Navigator.pop(context);
                          obtenerTrabajadores();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("✅ ${data["message"]}")),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("❌ ${data["message"] ?? "Error"}")),
                          );
                        }
                      },
                child: cargando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text("Registrar"),
              ),
            ],
          );
        });
      },
    );
  }

  /// 🔹 Popup para editar trabajador
  void mostrarPopupEditar(Map trabajador) {
    final _formKey = GlobalKey<FormState>();
    final _nombre = TextEditingController(text: trabajador["nombre"]);
    final _apellido = TextEditingController(text: trabajador["apellido"]);
    final _correo = TextEditingController(text: trabajador["correo"]);
    bool cargando = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text("Editar Trabajador"),
            content: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nombre,
                      decoration: const InputDecoration(labelText: "Nombre"),
                      validator: (v) => v!.isEmpty ? "Ingrese el nombre" : null,
                    ),
                    TextFormField(
                      controller: _apellido,
                      decoration: const InputDecoration(labelText: "Apellido"),
                      validator: (v) => v!.isEmpty ? "Ingrese el apellido" : null,
                    ),
                    TextFormField(
                      controller: _correo,
                      decoration: const InputDecoration(labelText: "Correo"),
                      validator: (v) =>
                          v!.isEmpty || !v.contains('@') ? "Correo inválido" : null,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancelar"),
              ),
              ElevatedButton(
                onPressed: cargando
                    ? null
                    : () async {
                        if (!_formKey.currentState!.validate()) return;
                        setStateDialog(() => cargando = true);

                        final response = await http.post(
                          Uri.parse("${ApiConfig.baseUrl}/usuarios/trabajador/editar_trabajador.php"),
                          headers: {"Content-Type": "application/json"},
                          body: jsonEncode({
                            "id": trabajador["id"],
                            "nombre": _nombre.text,
                            "apellido": _apellido.text,
                            "correo": _correo.text,
                          }),
                        );

                        final data = jsonDecode(response.body);
                        setStateDialog(() => cargando = false);

                        if (data["success"] == true) {
                          Navigator.pop(context);
                          obtenerTrabajadores();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("✅ ${data["message"]}")),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("❌ ${data["message"] ?? "Error al editar"}")),
                          );
                        }
                      },
                child: cargando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text("Guardar"),
              ),
            ],
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gestión de Trabajadores"),
        backgroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: TextButton.icon(
              icon: const Icon(Icons.add, color: Color.fromARGB(255, 48, 105, 58)),
              label: const Text(
                "Agregar Trabajador ",
                style: TextStyle(
                    color: Color.fromARGB(255, 62, 153, 89),
                    fontWeight: FontWeight.bold),
              ),
              onPressed: () => mostrarPopupRegistro(),
            ),
          ),
        ],
      ),
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
                          child: const Icon(Icons.person, color: Colors.white),
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
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => mostrarPopupEditar(trabajador),
                            ),
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
                              onPressed: () =>
                                  cambiarEstado(trabajador["id"], estado),
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
