import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:inventivo/core/constants/api_config.dart';
import 'package:inventivo/core/utils/session_manager.dart';
import 'package:inventivo/services/planta_service.dart';

class PlantasPage extends StatefulWidget {
  const PlantasPage({Key? key}) : super(key: key);

  @override
  State<PlantasPage> createState() => _PlantasPageState();
}

class _PlantasPageState extends State<PlantasPage> {
  List<Planta> plantas = [];
  bool isLoading = true;
  String filtro = '';
  int? idEmpresa;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final session = SessionManager();
    final user = await session.getUser();
    idEmpresa = user?["id_empresa"];
    if (idEmpresa != null) {
      final data = await obtenerPlantas(idEmpresa!, filtro: filtro);
      setState(() {
        plantas = data;
        isLoading = false;
      });
    }
  }

  // 
  Future<void> _mostrarDialogoPlanta({Planta? planta}) async {
    final nombreCtrl = TextEditingController(text: planta?.nombrePlantas ?? '');
    final bolsaCtrl = TextEditingController(text: planta?.numeroBolsa ?? '');
    final precioCtrl = TextEditingController(text: planta?.precio.toString() ?? '');
    final categoriaCtrl = TextEditingController(text: planta?.categoria ?? '');
    final stockCtrl = TextEditingController(text: planta?.stock.toString() ?? '');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(planta == null ? "Agregar Planta" : "Editar Planta"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: "Nombre")),
              TextField(controller: bolsaCtrl, decoration: const InputDecoration(labelText: "Número Bolsa")),
              TextField(controller: precioCtrl, decoration: const InputDecoration(labelText: "Precio de venta")),
              TextField(controller: categoriaCtrl, decoration: const InputDecoration(labelText: "Categoría")),
              TextField(controller: stockCtrl, decoration: const InputDecoration(labelText: "Cantidad")),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () async {
              final nombre = nombreCtrl.text.trim();
              final stockActual = int.tryParse(stockCtrl.text) ?? 0;

              // Validar campos obligatorios
              if (nombre.isEmpty || precioCtrl.text.isEmpty || stockCtrl.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Por favor completa todos los campos obligatorios")),
                );
                return;
              }

              // Validar duplicados
              final existe = plantas.any((p) =>
                  p.nombrePlantas.toLowerCase() == nombre.toLowerCase() &&
                  p.id != planta?.id);

              if (existe) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Ya existe una planta con ese nombre")),
                );
                return;
              }

              int nuevoStock = stockActual;

              // Si está editando, preguntar si entraron más unidades
              if (planta != null) {
                final agregarMas = await showDialog<bool>(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text("¿Nuevas unidades?"),
                      content: const Text("¿Ingresaron más unidades de esta planta al inventario?"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text("No"),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text("Sí"),
                        ),
                      ],
                    );
                  },
                );

                if (agregarMas == true) {
                  final cantidadCtrl = TextEditingController();
                  await showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text("¿Cuántas unidades nuevas ingresaron?"),
                        content: TextField(
                          controller: cantidadCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: "Cantidad"),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Cancelar"),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              final nuevas = int.tryParse(cantidadCtrl.text) ?? 0;
                              nuevoStock = stockActual + nuevas;
                              Navigator.pop(context);
                            },
                            child: const Text("Agregar"),
                          ),
                        ],
                      );
                    },
                  );
                }
              }

              final nueva = Planta(
                id: planta?.id,
                nombrePlantas: nombre,
                numeroBolsa: bolsaCtrl.text,
                precio: double.tryParse(precioCtrl.text) ?? 0,
                categoria: categoriaCtrl.text,
                stock: nuevoStock,
                estado: nuevoStock > 0 ? "disponible" : "no disponible",
                fechaCreacion: planta?.fechaCreacion ?? DateTime.now().toString(),
                idEmpresa: idEmpresa!,
              );

              bool ok = planta == null
                  ? await registrarPlanta(nueva)
                  : await actualizarPlanta(nueva);

              if (ok) {
                Navigator.pop(context);
                _cargarDatos();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(planta == null ? "Planta registrada" : "Planta actualizada")),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Error al guardar la planta")),
                );
              }
            },
            child: const Text("Guardar"),
          ),
        ],
      ),
    );
  }

  // 🗑️ Eliminar planta completamente
  Future<bool> eliminarPlanta(int id) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.eliminarPlantas),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"id": id}),
      );

      print("Respuesta backend eliminar: ${response.body}");

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json["success"] == true;
      } else {
        return false;
      }
    } catch (e) {
      print("Error al eliminar planta: $e");
      return false;
    }
  }

  // 🔸 Verifica nivel de stock
  Map<String, dynamic> _verificarStock(int stock) {
    if (stock <= 0) {
      return {"mensaje": "No disponible. Reabastecer.", "color": Colors.red};
    } else if (stock <= 20) {
      return {"mensaje": "Producto pronto a agotarse.", "color": Colors.orange};
    } else {
      return {"mensaje": "Stock disponible", "color": Colors.green};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gestión de Plantas"),
        backgroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: TextButton.icon(
              icon: const Icon(Icons.add, color: Color.fromARGB(255, 48, 105, 58)),
              label: const Text(
                "Agregar planta ",
                style: TextStyle(
                    color: Color.fromARGB(255, 62, 153, 89),
                    fontWeight: FontWeight.bold),
              ),
              onPressed: () => _mostrarDialogoPlanta(),
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: "Buscar planta",
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) {
                      setState(() => filtro = val);
                      _cargarDatos();
                    },
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _cargarDatos,
                    child: ListView.builder(
                      itemCount: plantas.length,
                      itemBuilder: (context, i) {
                        final p = plantas[i];
                        final stockInfo = _verificarStock(p.stock);

                        return Card(
                          margin: const EdgeInsets.all(8),
                          child: ListTile(
                            title: Text(
                              p.nombrePlantas,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Categoría: ${p.categoria}"),
                                Text("Precio: \$${p.precio}"),
                                Text("Cantidad: ${p.stock}",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: stockInfo["color"])),
                                Text(stockInfo["mensaje"],
                                    style: TextStyle(
                                        fontStyle: FontStyle.italic,
                                        color: stockInfo["color"])),
                              ],
                            ),
                            trailing: Wrap(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => _mostrarDialogoPlanta(planta: p),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_forever,
                                      color: Colors.redAccent),
                                  tooltip: "Eliminar planta",
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text("Eliminar planta"),
                                        content: const Text(
                                            "¿Estás seguro de que deseas eliminar esta planta?"),
                                        actions: [
                                          TextButton(
                                              onPressed: () => Navigator.pop(context, false),
                                              child: const Text("Cancelar")),
                                          TextButton(
                                              onPressed: () => Navigator.pop(context, true),
                                              child: const Text("Eliminar")),
                                        ],
                                      ),
                                    );

                                    if (confirm == true) {
                                      final ok = await eliminarPlanta(p.id!);
                                      if (ok) {
                                        _cargarDatos();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                              content: Text("Planta eliminada correctamente")),
                                        );
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                              content: Text("Error al eliminar la planta")),
                                        );
                                      }
                                    }
                                  },
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
    );
  }
}
