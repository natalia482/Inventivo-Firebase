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
  String? userRole; 
  int? idSede; // Modificado
  int? idUsuario; // Para auditoría

  final TextEditingController _searchController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController categoriaOtroController = TextEditingController();
  final TextEditingController precioController = TextEditingController();
  final TextEditingController cantidadController = TextEditingController();

  String? categoriaSeleccionada;
  String? medidaSeleccionada;

  final List<String> medidas = ["KG", "LB", "LITRO", "MILILITRO"];
  final List<String> categorias = ["Fertilizante", "Abono", "Matamaleza", "Otro"];

  // Función para verificar y dar formato al estado del insumo
  Map<String, dynamic> _verificarStockInsumo(double cantidad) {
    if (cantidad <= 0) {
      return {"mensaje": "NO DISPONIBLE. Reabastecer.", "color": Colors.red};
    } else if (cantidad <= 20) { // Umbral de "pronto a agotarse"
      return {"mensaje": "Pronto a agotarse.", "color": Colors.orange};
    } else {
      return {"mensaje": "DISPONIBLE", "color": const Color(0xFF2E7D32)};
    }
  }

  @override
  void initState() {
    super.initState();
    _loadEmpresaYListar();
    
    _searchController.addListener(() {
      listarInsumos(filtro: _searchController.text); 
    });
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadEmpresaYListar() async {
    final session = SessionManager();
    final user = await session.getUser();

    if (user != null && user["id_sede"] != null) {
      idSede = int.tryParse(user["id_sede"].toString()); // Modificado
      idUsuario = int.tryParse(user["id"].toString()); // Para auditoría
      userRole = user["rol"]?.toUpperCase(); // Normalizar el rol
      await listarInsumos();
    } else {
      setState(() => isLoading = false);
      //Manejar error si no hay sede
    }
  }

  Future<void> listarInsumos({String? filtro}) async { 
    if (idSede == null) return;
    
    // Construir la URL con el filtro
  String url = ApiConfig.listarInsumos(idSede!, filtro: filtro);
  final response = await http.get(Uri.parse(url));
  if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data["success"]) {
        setState(() {
          insumos = data["data"];
          isLoading = false;
        });
      }
    } else {
       setState(() => isLoading = false);
    }
  }

 
  void _mostrarPopupActividades() async { 
      // Capturar el filtro actual para refrescar con él
      final currentFiltro = _searchController.text;
      
      // Await la finalización y cierre del diálogo
      await showDialog(
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
      ); // La ejecución se reanuda cuando el diálogo se cierra

      listarInsumos(filtro: currentFiltro);
    }

// FUNCIONALIDAD ELIMINAR PERMANENTE
    Future<void> eliminarInsumo(int id) async {
      bool? confirmar = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Eliminar Insumo PERMANENTEMENTE'),
          content: const Text(
            '⚠️ ¿Estás seguro de que deseas ELIMINAR PERMANENTEMENTE este insumo? Esta acción es irreversible.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar', style: TextStyle(color: Colors.blueAccent)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Eliminar'),
            ),
          ],
        ),
      );
    // Uso seguro: verificar si es true
    if (confirmar == true) { 
      try {
        final response = await http.post(
          Uri.parse(ApiConfig.eliminarInsumo),
          headers: {"Content-Type": "application/json"},
          // Enviar id_usuario y id_sede para la auditoría (Paso 4)
          body: jsonEncode({
            "id": id,
            "id_usuario": idUsuario,
            "id_sede": idSede
            }),
        );

       final data = jsonDecode(response.body);
        if (response.statusCode == 200 && data["success"] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("✅ Insumo eliminado permanentemente.")),
          );
          listarInsumos(filtro: _searchController.text);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("❌ Error al eliminar insumo: ${data["message"] ?? 'Error de servidor'}")),
          );
        }
      } catch (e) {
        debugPrint("Excepción al eliminar insumo: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error de conexión al eliminar insumo.")),
        );
      }
    }
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
                  child: const Text("Guardar",style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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
      child: TextFormField( 
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
    if (idSede == null || idUsuario == null) return;

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
        "id_sede": idSede, // Modificado
        "id_sede": idSede.toString(), 
        "id_usuario": idUsuario.toString()      }),
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
    // Aseguramos que los valores sean Strings seguros para el controlador
    String? medidaEdit = insumo["medida"]?.toString().toUpperCase();
    String? categoriaEdit =
        categorias.contains(insumo["categoria"]) ? insumo["categoria"] : "Otro";
    String? estadoEdit = (insumo["estado"] == null || insumo["estado"] == "") ? "DISPONIBLE" : insumo["estado"];

    // ✅ CORRECCIÓN 1: Inicializar controladores con .toString() seguro
    final nombreCtrl = TextEditingController(text: insumo["nombre_insumo"]?.toString() ?? '');
    final categoriaOtroCtrl =
        TextEditingController(text: categoriaEdit == "Otro" ? insumo["categoria"]?.toString() ?? '' : "");
    final precioCtrl = TextEditingController(text: insumo["precio"]?.toString() ?? '');
    final cantidadCtrl = TextEditingController(text: insumo["cantidad"]?.toString() ?? '');

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
                  _buildInput(cantidadCtrl, "Cantidad", type: TextInputType.number),

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
                    // ESTA ES LA LÍNEA QUE CAUSABA EL ERROR DE TIPO
                    body: {
                      "id": insumo["id"].toString(),
                      "nombre_insumo": nombreCtrl.text,       // CORREGIDO: .text
                      "categoria": categoriaFinal,
                      "medida": medidaEdit,
                      "precio": precioCtrl.text,             // CORREGIDO: .text
                      "cantidad": cantidadCtrl.text,         // CORREGIDO: .text
                      "estado": estadoEdit,
                      "id_sede": idSede.toString(), 
                      "id_usuario": idUsuario.toString() 
                    },
                  );

                  final data = jsonDecode(response.body);
                  if (data["success"] == true) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Insumo actualizado correctamente")),
                    );
                    listarInsumos();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Error: ${data["message"] ?? 'Error al actualizar'}")),
                    );
                  }
                },
                child: const Text("Guardar",style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool canCreateEdit = userRole == 'PROPIETARIO' || userRole == 'ADMINISTRADOR' || userRole == 'TRABAJADOR'; 
    final bool canDelete = userRole == 'PROPIETARIO' || userRole == 'ADMINISTRADOR'; 
    
    return Scaffold(
      backgroundColor: const Color(0xFFEFF7EE),
      appBar: AppBar(
        title: const Text("Gestión de Insumos",
            style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF2E7D32),
        actions: [
          // Botón "Lista de actividades" (TRABAJADOR SI ve)
          TextButton.icon(
            onPressed: _mostrarPopupActividades,
            icon: const Icon(Icons.history, color: Colors.white),
            label: const Text("Lista de actividades",
                style: TextStyle(color: Colors.white)),
          ),
          // Botón "Registrar insumo" (TRABAJADOR SI ve)
          if (canCreateEdit) 
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
                    // CAMPO DE BÚSQUEDA
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: TextField(
                        controller: _searchController, // Usa el controller
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
                        onRefresh: () => listarInsumos(filtro: _searchController.text),
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
                                    final cantidad = double.tryParse(insumo["cantidad"]?.toString() ?? '0') ?? 0.0;
                                    final precio = insumo["precio"];
                                    
                                    // Verificar estado del stock
                                    final stockInfo = _verificarStockInsumo(cantidad);

                                    return Card(
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(15)),
                                      margin: const EdgeInsets.symmetric(
                                          vertical: 8, horizontal: 12),
                                      elevation: 4,
                                      child: ListTile(
                                        leading: Icon(Icons.inventory_2,
                                            color: stockInfo["color"], size: 35),
                                        title: Text(
                                          nombre,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                        subtitle: Padding(
                                          padding: const EdgeInsets.only(top: 6),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                                Text("Categoría: $categoria"),
                                                Text("Medida: $medida\nCantidad: ${cantidad.toStringAsFixed(2)} | Precio: \$${precio.toString()}"),
                                                
                                                // Mostrar mensaje de estado/alerta
                                                Text(stockInfo["mensaje"], 
                                                     style: TextStyle(
                                                         fontWeight: FontWeight.bold, 
                                                         color: stockInfo["color"]
                                                    )), 
                                            ],
                                          ),
                                        ),
                                        // ✅ PERMISO: El trabajador ve EDITAR, pero no ve ELIMINAR
                                        trailing: canCreateEdit
                                            ? Wrap( 
                                                spacing: 4,
                                                children: [
                                                  // Botón EDITAR (TRABAJADOR SI ve)
                                                  IconButton(
                                                    icon: const Icon(Icons.edit, color: Colors.blueAccent),
                                                    onPressed: () => _editarInsumo(insumo),
                                                  ),
                                                  // Botón ELIMINAR (TRABAJADOR NO ve)
                                                  if (canDelete)
                                                    IconButton(
                                                      icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
                                                      onPressed: () => eliminarInsumo(insumo["id"]),
                                                    ),
                                                ],
                                              )
                                            : null,
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