import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:inventivo/core/constants/api_config.dart';
import 'package:inventivo/core/utils/session_manager.dart';
import 'package:inventivo/screens/modulos/insumos/historial_uso_insumos_page.dart';

class InsumosPage extends StatefulWidget {
  const InsumosPage({Key? key}) : super(key: key);

  @override
  State<InsumosPage> createState() => _InsumosPageState();
}

class _InsumosPageState extends State<InsumosPage> {
  List<dynamic> insumos = [];
  bool isLoading = true;
  String? userRole; // ✅ NUEVO: Almacena el rol del usuario
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
      userRole = user["rol"]; // ✅ Obtenemos el rol de la sesión
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

  void _mostrarPopupActividades() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          insetPadding: EdgeInsets.zero,
          contentPadding: EdgeInsets.zero,
          titlePadding: EdgeInsets.zero,
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.95,
            height: MediaQuery.of(context).size.height * 0.95,
            child: const HistorialUsoInsumosPage(),
          ),
        );
      },
    );
  }

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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text("Registrar Insumo"),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ... (Campos de formulario omitidos por brevedad)
                      _buildInput(nombreController, "Nombre del insumo"),
                      DropdownButtonFormField<String>(
                        value: categoriaSeleccionada,
                        decoration: const InputDecoration(labelText: "Categoría"),
                        items: categorias
                            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (value) => setStateDialog(() => categoriaSeleccionada = value),
                        validator: (value) => value == null ? "Seleccione una categoría" : null,
                      ),
                      if (categoriaSeleccionada == "Otro")
                        _buildInput(categoriaOtroController, "Otra categoría"),
                      DropdownButtonFormField<String>(
                        value: medidaSeleccionada,
                        decoration: const InputDecoration(labelText: "Medida"),
                        items: medidas
                            .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                            .toList(),
                        onChanged: (value) => setStateDialog(() => medidaSeleccionada = value),
                        validator: (value) => value == null ? "Seleccione una medida" : null,
                      ),
                      _buildInput(cantidadController, "Cantidad del insumo", type: TextInputType.number),
                      _buildInput(precioController, "Precio de compra", type: TextInputType.number),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancelar", style: TextStyle(color: Colors.redAccent))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
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

  Widget _buildInput(TextEditingController ctrl, String label,
      {TextInputType type = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField( // Cambiado a TextFormField para usar la validación del form
        controller: ctrl,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white,
        ),
        validator: (value) => value!.isEmpty ? "Campo obligatorio" : null,
      ),
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
        const SnackBar(content: Text("Insumo registrado correctamente")),
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

  Future<void> _editarInsumo(dynamic insumo) async {
    // ... (Lógica de edición omitida por brevedad, asume que usa isAdmin en el build)
     String? medidaEdit = insumo["medida"]?.toString().toUpperCase();
    String? categoriaEdit =
        categorias.contains(insumo["categoria"]) ? insumo["categoria"] : "Otro";

    final nombreCtrl = TextEditingController(text: insumo["nombre_insumo"]);
    final categoriaOtroCtrl =
        TextEditingController(text: categoriaEdit == "Otro" ? insumo["categoria"] : "");
    final precioCtrl = TextEditingController(text: insumo["precio"].toString());
    final cantidadCtrl = TextEditingController(text: insumo["cantidad"].toString());

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text("Editar Insumo"),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  _buildInput(nombreCtrl, "Nombre"),
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
                    _buildInput(categoriaOtroCtrl, "Otra categoría"),
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
                  _buildInput(cantidadCtrl, "Cantidad", type: TextInputType.number),
                  _buildInput(precioCtrl, "Precio de compra", type: TextInputType.number),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancelar", style: TextStyle(color: Colors.redAccent))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
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
                      const SnackBar(content: Text("Insumo actualizado correctamente")),
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
    final bool isAdmin = userRole == 'ADMINISTRADOR'; // ✅ Bandera de control de acceso

    return Scaffold(
      backgroundColor: const Color(0xFFEFF7EE),
      appBar: AppBar(
        title: const Text("Gestión de Insumos",
            style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF2E7D32),
        actions: [
          // Botón "Lista de actividades" (Visible para todos)
          TextButton.icon(
            onPressed: _mostrarPopupActividades,
            icon: const Icon(Icons.history, color: Colors.white),
            label: const Text("Lista de actividades",
                style: TextStyle(color: Colors.white)),
          ),
          // Botón "Registrar insumo" (SOLO ADMIN)
          if (isAdmin) // ✅ Renderizado condicional
            TextButton.icon(
              onPressed: _mostrarPopupRegistro,
              icon: const Icon(Icons.add_circle_outline, color: Colors.white),
              label: const Text("Registrar insumo",
                  style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
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
                          labelText: "Buscar insumo",
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        
                      ),
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: listarInsumos,
                        color: const Color(0xFF2E7D32),
                        child: insumos.isEmpty
                            ? const Center(child: Text("No hay insumos registrados"))
                            : ListView.builder(
                                  itemCount: insumos.length,
                                  itemBuilder: (context, index) {
                                    final insumo = insumos[index];
                                    final nombre = insumo["nombre_insumo"];
                                    final categoria = insumo["categoria"];
                                    final medida = insumo["medida"];
                                    final cantidad = insumo["cantidad"];
                                    final precio = insumo["precio"];

                                    return Card(
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(15)),
                                      margin: const EdgeInsets.symmetric(
                                          vertical: 8, horizontal: 12),
                                      elevation: 4,
                                      child: ListTile(
                                        leading: const Icon(Icons.inventory_2,
                                            color: Color(0xFF2E7D32), size: 35),
                                        title: Text(
                                          nombre,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                        subtitle: Padding(
                                          padding: const EdgeInsets.only(top: 6),
                                          child: Text(
                                            "Categoría: $categoria\n"
                                            "Medida: $medida\n"
                                            "Cantidad: $cantidad | Precio: \$${precio.toString()}",
                                            style: const TextStyle(height: 1.4),
                                          ),
                                        ),
                                        // ✅ Ocultar/Mostrar botón de EDICIÓN (SOLO ADMIN)
                                        trailing: isAdmin
                                            ? IconButton( 
                                                icon: const Icon(Icons.edit,
                                                    color: Colors.blueAccent),
                                                onPressed: () => _editarInsumo(insumo),
                                              )
                                            : null, // No mostrar nada si no es administrador
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