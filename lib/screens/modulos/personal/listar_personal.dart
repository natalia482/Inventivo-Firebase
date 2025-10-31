import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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
  String filtro = '';
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
            SnackBar(
              content: Text("Estado cambiado a $nuevoEstado"),
              backgroundColor: const Color(0xFF2E7D32),
            ),
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
          const SnackBar(
            content: Text("Trabajador eliminado correctamente"),
            backgroundColor: Colors.redAccent,
          ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:
                const Text("Cancelar", style: TextStyle(color: Colors.redAccent)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Eliminar"),
          ),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text("Registrar Trabajador"),
            content: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildInput(_nombre, "Nombre"),
                    _buildInput(_apellido, "Apellido"),
                    _buildInput(_correo, "Correo electrónico"),
                    _buildInput(_password, "Contraseña", obscure: true),
                    _buildInput(_confirmarPassword, "Confirmar contraseña",
                        obscure: true),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancelar",
                      style: TextStyle(color: Colors.redAccent))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
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
                            SnackBar(
                              content: Text("✅ ${data["message"]}"),
                              backgroundColor: const Color(0xFF2E7D32),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  "❌ ${data["message"] ?? "Error al registrar"}"),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                      },
                child: cargando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text("Registrar"),
              ),
            ],
          );
        });
      },
    );
  }

  Widget _buildInput(TextEditingController ctrl, String label,
      {bool obscure = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: ctrl,
        obscureText: obscure,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white,
        ),
        validator: (v) => v!.isEmpty ? "Campo obligatorio" : null,
      ),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text("Editar Trabajador"),
            content: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildInput(_nombre, "Nombre"),
                    _buildInput(_apellido, "Apellido"),
                    _buildInput(_correo, "Correo"),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancelar",
                      style: TextStyle(color: Colors.redAccent))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
                onPressed: cargando
                    ? null
                    : () async {
                        if (!_formKey.currentState!.validate()) return;
                        setStateDialog(() => cargando = true);

                        final response = await http.post(
                          Uri.parse(
                              "${ApiConfig.baseUrl}/usuarios/trabajador/editar_trabajador.php"),
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
                            SnackBar(
                                content: Text("✅ ${data["message"]}"),
                                backgroundColor: const Color(0xFF2E7D32)),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    "❌ ${data["message"] ?? "Error al editar"}"),
                                backgroundColor: Colors.redAccent),
                          );
                        }
                      },
                child: cargando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
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
      backgroundColor: const Color(0xFFEFF7EE),
      appBar: AppBar(
        title: const Text("Gestión de Trabajadores",
            style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF2E7D32),
        actions: [
          TextButton.icon(
            onPressed: mostrarPopupRegistro,
            icon: const Icon(Icons.add_circle_outline, color: Colors.white),
            label: const Text("Registrar trabajador",
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: "Buscar trabajador",
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15)),
                        ),
                        onChanged: (val) {
                          setState(() => filtro = val);
                        },
                      ),
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: obtenerTrabajadores,
                        color: const Color(0xFF2E7D32),
                        child: ListView.builder(
                          itemCount: trabajadores.length,
                          itemBuilder: (context, index) {
                            final trabajador = trabajadores[index];
                            final estado =
                                trabajador["estado"]?.toUpperCase() ?? "ACTIVO";

                            return Card(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15)),
                              margin: const EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 12),
                              elevation: 4,
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: estado == "ACTIVO"
                                      ? Colors.green
                                      : Colors.red,
                                  child: const Icon(Icons.person,
                                      color: Colors.white),
                                ),
                                title: Text(
                                  "${trabajador["nombre"]} ${trabajador["apellido"]}",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    "Correo: ${trabajador["correo"]}\nEstado: $estado",
                                    style: const TextStyle(height: 1.4),
                                  ),
                                ),
                                trailing: Wrap(
                                  spacing: 6,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit,
                                          color: Colors.blueAccent),
                                      onPressed: () =>
                                          mostrarPopupEditar(trabajador),
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
                                      onPressed: () => cambiarEstado(
                                          trabajador["id"], estado),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.redAccent),
                                      onPressed: () =>
                                          eliminarTrabajador(trabajador["id"]),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
