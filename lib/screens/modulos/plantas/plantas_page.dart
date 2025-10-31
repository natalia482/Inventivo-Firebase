import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:inventivo/core/constants/api_config.dart';
import 'package:inventivo/core/utils/session_manager.dart';
import 'package:inventivo/services/planta_service.dart';
import 'package:inventivo/screens/modulos/facturacion/facturas_screen.dart';

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
  int? idEmpresa;
  int? idVendedor;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final session = SessionManager();
    final user = await session.getUser();

    idEmpresa = user?["id_empresa"];
    idVendedor = int.tryParse(user?["id"]?.toString() ?? '0');
    if (idVendedor == 0) idVendedor = null;

    if (idEmpresa != null) {
      final data =
          await _plantaService.obtenerPlantas(idEmpresa!, filtro: filtro);
      setState(() {
        plantas = data;
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
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
                idEmpresa: idEmpresa!,
              );

              bool ok = planta == null
                  ? await _plantaService.registrarPlanta(nueva)
                  : await _plantaService.actualizarPlanta(nueva);

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

  void _mostrarPopupRemisiones() {
    if (idEmpresa == null || idVendedor == null || idVendedor == 0) {
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
            child: FacturasScreen(
              idEmpresa: idEmpresa!,
              idVendedor: idVendedor!,
            ),
          ),
        );
      },
    ).then((_) => _cargarDatos());
  }

  Future<bool> eliminarPlanta(int id) async {
    return await _plantaService.eliminarPlanta(id);
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
    final bool datosListos =
        idEmpresa != null && idVendedor != null && idVendedor != 0;

    return Scaffold(
      backgroundColor: const Color(0xFFEFF7EE),
      appBar: AppBar(
        title: const Text("Gestión de Plantas",
            style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF2E7D32),
        actions: [
          TextButton.icon(
            onPressed: datosListos ? _mostrarPopupRemisiones : null,
            icon: const Icon(Icons.receipt_long, color: Colors.white),
            label: const Text("Lista Remisiones",
                style: TextStyle(color: Colors.white)),
          ),
          TextButton.icon(
            onPressed: () => _mostrarDialogoPlanta(),
            icon: const Icon(Icons.add_circle_outline, color: Colors.white),
            label: const Text("Agregar Planta",
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
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
                          labelText: "Buscar planta",
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
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
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15)),
                              margin: const EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 12),
                              elevation: 4,
                              child: ListTile(
                                leading: const Icon(Icons.local_florist,
                                    color: Color(0xFF2E7D32), size: 35),
                                title: Text(
                                  p.nombrePlantas,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text("Categoría: ${p.categoria}"),
                                      Text("Precio: \$${p.precio}"),
                                      Text("Cantidad: ${p.stock}",
                                          style: TextStyle(
                                              color: stockInfo["color"],
                                              fontWeight: FontWeight.bold)),
                                      Text(stockInfo["mensaje"],
                                          style: TextStyle(
                                              fontStyle: FontStyle.italic,
                                              color: stockInfo["color"])),
                                    ],
                                  ),
                                ),
                                trailing: Wrap(
                                  spacing: 8,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit,
                                          color: Colors.blueAccent),
                                      onPressed: () =>
                                          _mostrarDialogoPlanta(planta: p),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_forever,
                                          color: Colors.redAccent),
                                      onPressed: () async {
                                        final confirm =
                                            await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title:
                                                const Text("Eliminar planta"),
                                            content: const Text(
                                                "¿Deseas eliminar esta planta?"),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(
                                                        context, false),
                                                child: const Text("Cancelar"),
                                              ),
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(
                                                        context, true),
                                                child: const Text("Eliminar",
                                                    style: TextStyle(
                                                        color:
                                                            Colors.redAccent)),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (confirm == true) {
                                          final ok =
                                              await eliminarPlanta(p.id!);
                                          if (ok) {
                                            _cargarDatos();
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                  content: Text(
                                                      "Planta eliminada correctamente")),
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
              ),
            ),
    );
  }
}
