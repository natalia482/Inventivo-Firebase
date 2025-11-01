import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:inventivo/core/constants/api_config.dart';
import 'package:inventivo/core/utils/session_manager.dart';
import 'package:inventivo/services/planta_service.dart';
import 'package:inventivo/screens/modulos/remision/remision_screen.dart'; // Asegúrate de renombrar esto

class PlantasPage extends StatefulWidget {
  const PlantasPage({Key? key}) : super(key: key);

  @override
  State<PlantasPage> createState() => _PlantasPageState();
}

class _PlantasPageState extends State<PlantasPage> {
  final PlantaService _plantaService = PlantaService();
  List<Planta> plantas = [];
  bool isLoading = true;
  String filtro = '';
  
  int? idSede; // Modificado
  int? idVendedor; // (Usuario logueado)
  String? userRole;
  int? idUsuario;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final session = SessionManager();
    final user = await session.getUser();
    
    idSede = int.tryParse(user?["id_sede"]?.toString() ?? '0');
    idVendedor = int.tryParse(user?["id"]?.toString() ?? '0');
    idUsuario = int.tryParse(user?["id"]?.toString() ?? '0'); // ✅ Obtener ID de Usuario
    userRole = user?["rol"];
    
    if (idSede != null && idSede! > 0) {
      await obtenerPlantas(filtro: filtro);
    } else {
      setState(() => isLoading = false);
      // Mostrar error si no hay sede
    }
  }

  Future<void> obtenerPlantas({String filtro = ''}) async {
    if (idSede == null) return;
    setState(() => isLoading = true);
    final data = await _plantaService.obtenerPlantas(idSede!, filtro: filtro);
    setState(() {
      plantas = data;
      isLoading = false;
    });
  }

 void _mostrarPopupRemisiones() {
    if (idSede == null || idVendedor == null || idVendedor == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text("Error: Datos de empresa o vendedor no disponibles.")),
      );
      return;
    }

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
            child: RemisionesScreen(
              idSede: idSede!,
              idVendedor: idVendedor!,
            ),
          ),
        );
      },
    ).then((_) => _cargarDatos());
  }

  Future<void> _mostrarDialogoPlanta({Planta? planta}) async {
    final nombreCtrl = TextEditingController(text: planta?.nombrePlantas ?? '');
    final bolsaCtrl = TextEditingController(text: planta?.numeroBolsa ?? '');
    final precioCtrl =
        TextEditingController(text: planta?.precio.toString() ?? '');
    final categoriaCtrl =
        TextEditingController(text: planta?.categoria ?? '');
    final stockCtrl =
        TextEditingController(text: planta?.stock.toString() ?? '');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(planta == null ? "Agregar Planta" : "Editar Planta"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              _buildInput(nombreCtrl, "Nombre"),
              _buildInput(bolsaCtrl, "Número Bolsa"),
              _buildInput(precioCtrl, "Precio de venta",
                  type: TextInputType.number),
              _buildInput(categoriaCtrl, "Categoría"),
              _buildInput(stockCtrl, "Cantidad", type: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar",
                style: TextStyle(color: Colors.redAccent)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              final nombre = nombreCtrl.text.trim();
              final stockActual = int.tryParse(stockCtrl.text) ?? 0;

              if (nombre.isEmpty ||
                  precioCtrl.text.isEmpty ||
                  stockCtrl.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text("Por favor completa todos los campos")),
                );
                return;
              }

              final existe = plantas.any((p) =>
                  p.nombrePlantas.toLowerCase() == nombre.toLowerCase() &&
                  p.id != planta?.id);
              if (existe) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content:
                          Text("Ya existe una planta con ese nombre")),
                );
                return;
              }

              int nuevoStock = stockActual;

              if (planta != null) {
                final agregarMas = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("¿Nuevas unidades?"),
                    content: const Text(
                        "¿Ingresaron más unidades de esta planta al inventario?"),
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
                  ),
                );

                if (agregarMas == true) {
                  final cantidadCtrl = TextEditingController();
                  await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title:
                          const Text("¿Cuántas unidades nuevas ingresaron?"),
                      content: TextField(
                        controller: cantidadCtrl,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: "Cantidad"),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Cancelar"),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            final nuevas =
                                int.tryParse(cantidadCtrl.text) ?? 0;
                            nuevoStock = stockActual + nuevas;
                            Navigator.pop(context);
                          },
                          child: const Text("Agregar"),
                        ),
                      ],
                    ),
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
                fechaCreacion:
                planta?.fechaCreacion ?? DateTime.now().toString(),
                idSede: idSede!,
              );

             final bool ok;
              if (planta == null) {
                  ok = await _plantaService.registrarPlanta(
                      nueva, idUsuario!, idSede!
                  );
              } else {
                  ok = await _plantaService.actualizarPlanta(
                      nueva, idUsuario!, idSede!
                  );
              }

              if (ok) {
                Navigator.pop(context);
                _cargarDatos();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(planta == null
                          ? "Planta registrada"
                          : "Planta actualizada")),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text("Error al guardar la planta")),
                );
              }
            },
            child: const Text("Guardar"),
          ),
        ],
      ),
    );
  }

  Widget _buildInput(TextEditingController ctrl, String label,
      {TextInputType type = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: ctrl,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  Future<void> eliminarPlanta(int id) async { // Cambiamos el retorno a void
      // 1. Confirmación
      bool? confirmar = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Eliminar planta"),
          content: const Text(
              "⚠️ ¿Estás seguro de ELIMINAR PERMANENTEMENTE esta planta? Esta acción es irreversible."),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancelar")),
            ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text("Eliminar")),
          ],
        ),
      );

      if (confirmar == true) {
        // 2. Ejecutar eliminación con IDs de auditoría
        // Aseguramos que los IDs no sean nulos (ya están chequeados en _cargarDatos)
        if (idUsuario == null || idSede == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Error: Faltan datos de sesión para auditar.")),
            );
            return;
        }
        
        final ok = await _plantaService.eliminarPlanta(id, idUsuario!, idSede!);
        
        // 3. Manejar resultado
        if (ok) {
          _cargarDatos(); // Recargar la lista
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("✅ Planta eliminada correctamente")),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("❌ Error al eliminar la planta")),
          );
        }
      }
    }
    Map<String, dynamic> _verificarStock(int stock) {
      if (stock <= 0) {
        return {"mensaje": "No disponible. Reabastecer.", "color": Colors.red};
      } else if (stock <= 20) {
        return {"mensaje": "Pronto a agotarse", "color": Colors.orange};
      } else {
        return {"mensaje": "Stock disponible", "color": Colors.green};
      }
    }

  @override
  Widget build(BuildContext context) {
    final bool canModify = userRole == 'PROPIETARIO' || userRole == 'ADMINISTRADOR';
    final bool datosListos = idSede != null && idVendedor != null && idVendedor != 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Gestión de Plantas"),
        backgroundColor: Colors.white,
        actions: [
          // Botón "Lista Remisiones"
          TextButton.icon(
            onPressed: datosListos ? _mostrarPopupRemisiones : null,
            icon: const Icon(Icons.receipt_long, color: Color.fromARGB(255, 48, 105, 58)),
            label: const Text(
              "Lista Remisiones",
              style: TextStyle(
                  color: Color.fromARGB(255, 62, 153, 89),
                  fontWeight: FontWeight.bold),
            ),
          ),
          
          // Botón "Agregar planta" (Solo Admin/Propietario)
          if (canModify)
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
                      obtenerPlantas(filtro: filtro); // Llama al filtro
                    },
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => _cargarDatos(),
                    child: ListView.builder(
                      itemCount: plantas.length,
                      itemBuilder: (context, i) {
                        final p = plantas[i];
                        final stockInfo = _verificarStock(p.stock);

                        return Card(
                          margin: const EdgeInsets.all(8),
                          child: ListTile(
                            title: Text(p.nombrePlantas, style: const TextStyle(fontWeight: FontWeight.bold)),
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
                            // Botones de acción (Solo Admin/Propietario)
                            trailing: canModify ? Wrap(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => _mostrarDialogoPlanta(planta: p),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
                                  tooltip: "Eliminar planta",
                                  onPressed: () async { await eliminarPlanta(p.id!); },                                ),
                              ],
                            ) : null, // No mostrar nada si es Trabajador
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
