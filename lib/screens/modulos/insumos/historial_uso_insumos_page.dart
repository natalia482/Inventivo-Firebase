import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:inventivo/core/constants/api_config.dart';
import 'package:inventivo/core/utils/session_manager.dart';

class HistorialUsoInsumosPage extends StatefulWidget {
  const HistorialUsoInsumosPage({super.key});

  @override
  State<HistorialUsoInsumosPage> createState() =>
      _HistorialUsoInsumosPageState();
}

class _HistorialUsoInsumosPageState extends State<HistorialUsoInsumosPage> {
  List<dynamic> actividades = [];
  bool isLoading = true;
  int? idSede; // Asumiendo migración a Sedes

  @override
  void initState() {
    super.initState();
    _cargarDatosIniciales();
  }

  Future<void> _cargarDatosIniciales() async {
    final session = SessionManager();
    idSede = await session.getIdSede(); 
    cargarActividades();
  }

  Future<void> cargarActividades() async {
    if (idSede == null) {
      if(mounted) setState(() => isLoading = false);
      return;
    }

    if(mounted) setState(() => isLoading = true);
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.listarUsoInsumos),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"id_sede": idSede}), 
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          if(mounted) {
            setState(() {
              actividades = data['data'] ?? [];
              isLoading = false;
            });
          }
        } else {
          if(mounted) setState(() => isLoading = false);
        }
      } else {
        if(mounted) setState(() => isLoading = false);
      }
    } catch (e) {
      if(mounted) setState(() => isLoading = false);
    }
  }

  void mostrarPopupRegistro() {
     if (idSede == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(" No se ha cargado la información de la sede aún. Intenta nuevamente."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (context) => RegistrarActividadPopup(
        idSede: idSede, 
        onRegistrada: () => cargarActividades(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      appBar: AppBar(
        title: const Text(
          "Historial de Uso de Insumos",
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFF8FAF8)),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 3,
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
          : actividades.isEmpty
              ? const Center(
                  child: Text(
                    "No hay actividades registradas.",
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                )
              : RefreshIndicator(
                  color: const Color(0xFF2E7D32),
                  onRefresh: cargarActividades,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: actividades.length,
                    itemBuilder: (context, index) {
                      final a = actividades[index];
                      
                      // Manejo de valores nulos
                      final String nombreInsumo = a['nombre_insumo'] ?? 'Insumo desconocido';
                      final String fecha = a['fecha'] ?? '-';
                      final String responsable = a['responsable'] ?? '-';
                      final String cantidad = a['cantidad_utilizada']?.toString() ?? '0';
                      final String objetivo = a['objetivo'] ?? '-';

                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 3,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                nombreInsumo,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF2E7D32),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(" $fecha"),
                                  Text(" $responsable"),
                                ],
                              ),
                              const Divider(height: 15),
                              Text(" Cantidad utilizada: $cantidad"),
                              Text(" Objetivo: $objetivo"),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: idSede == null ? Colors.grey : const Color(0xFF43A047),
          onPressed: idSede == null ? null : mostrarPopupRegistro,
          icon: const Icon(Icons.add),
          label: const Text("Registrar actividad"),
      ),
    );
  }
}

class RegistrarActividadPopup extends StatefulWidget {
  final VoidCallback onRegistrada;
  final int? idSede; 
  
  const RegistrarActividadPopup({
    super.key, 
    required this.onRegistrada,
    required this.idSede,
  });

  @override
  State<RegistrarActividadPopup> createState() => _RegistrarActividadPopupState();
}

class _RegistrarActividadPopupState extends State<RegistrarActividadPopup> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _cantidadCtrl = TextEditingController();
  final TextEditingController _otroObjetivoCtrl = TextEditingController();
  final TextEditingController _medidaCtrl = TextEditingController();

  bool isLoading = false;
  bool mostrarOtroObjetivo = false;
  List<dynamic> insumos = [];
  
  List<dynamic> personalEmpresa = []; 
  
  int? selectedResponsableId; 
  String? selectedInsumo;
  String? medida;
  String? objetivo;

  @override
  void initState() {
    super.initState();
    if (widget.idSede != null) {
      cargarInsumos(widget.idSede!);
      cargarPersonalEmpresa(widget.idSede!); 
      
    }
  }


  // Carga el personal de la sede
  Future<void> cargarPersonalEmpresa(int idSede) async {
    try {
      final session = SessionManager();
      final user = await session.getUser();

      // Usamos obtenerPersonal de ApiConfig que filtra por sede y excluye propietario
      final response = await http.get( 
        Uri.parse(ApiConfig.obtenerPersonal(idSede)), 
      );
      
      final data = jsonDecode(response.body);
      if (data['status'] == 'success') { 
        if (mounted) {
          setState(() => personalEmpresa = data['data']);
        }
        
        // No necesitamos buscar el usuario actual aquí, solo cargamos la lista
      }
    } catch (e) {
      debugPrint("Error al cargar personal de la empresa: $e");
    }
  }


  Future<void> cargarInsumos(int idSede) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.listarInsumos(idSede)), 
      );

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        if(mounted) setState(() => insumos = data['data']);
      }
    } catch (e) {
      debugPrint("Error al cargar insumos: $e");
    }
  }

  Future<void> registrarActividad() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedInsumo == null || selectedResponsableId == null) { 
       ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Complete todos los campos.")));
      return;
    }
    if (widget.idSede == null) {
         ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Error: ID de Sede no encontrado.")));
      return;
    }

    // Validación de stock
    final cantidadNumerica = double.tryParse(_cantidadCtrl.text) ?? 0.0;
    
    // Obtenemos el stock disponible de la lista local
    final insumoSeleccionado = insumos.firstWhere((i) => i['nombre_insumo'] == selectedInsumo, orElse: () => null);
    final stockDisponible = double.tryParse(insumoSeleccionado?['cantidad']?.toString() ?? '0') ?? 0.0;


    if (cantidadNumerica <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("La cantidad utilizada debe ser mayor a cero.")));
      return;
    }
    if (cantidadNumerica > stockDisponible) {
       ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Stock insuficiente. Disponible: ${stockDisponible.toStringAsFixed(2)}")),
      );
      return;
    }

    if(mounted) setState(() => isLoading = true);
    

    try {
      final insumo =
          insumos.firstWhere((i) => i['nombre_insumo'] == selectedInsumo);
      final idInsumo = insumo['id'];

      final response = await http.post(
        Uri.parse(ApiConfig.registrarUsoInsumo),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "id_insumo": idInsumo,
          "cantidad_utilizada": _cantidadCtrl.text, 
          "objetivo":
              objetivo == "Otro" ? _otroObjetivoCtrl.text : objetivo,
          "responsable": selectedResponsableId, // 
          "id_sede": widget.idSede
        }),
      );

      final data = jsonDecode(response.body);
      
      if (mounted) setState(() => isLoading = false);

      if (data['success'] == true) {
        if(mounted) {
          Navigator.pop(context);
          widget.onRegistrada();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Actividad registrada y stock actualizado"),
            ),
          );
        }
      } else {
        if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  " Error: ${data['message'] ?? 'Error al registrar actividad'}"),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      if(mounted) setState(() => isLoading = false);
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al registrar la actividad: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filtrar insumos para mostrar solo los DISPONIBLES
    final List<dynamic> insumosDisponibles =
        insumos.where((i) => (i['estado']?.toString().toUpperCase() ?? 'DISPONIBLE') == 'DISPONIBLE').toList();

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        "Registrar Actividad Agrícola",
        style: TextStyle(
          color: Color(0xFF2E7D32),
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: selectedInsumo,
                items: insumosDisponibles.map<DropdownMenuItem<String>>((i) {
                  final String nombre = i['nombre_insumo'] ?? 'Sin Nombre';
                  final String medida = i['medida'] ?? 'Sin Medida';
                  return DropdownMenuItem<String>(
                    value: nombre, // Usamos el nombre (String) como valor
                    child: Text("$nombre ($medida)"),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedInsumo = value;
                    final insumo = insumosDisponibles.firstWhere(
                        (i) => i['nombre_insumo'] == value,
                        orElse: () => {});
                    medida = insumo['cantidad']?.toString() ?? ''; 
                    _medidaCtrl.text = medida ?? '';
                  });
                },
                decoration: const InputDecoration(
                  labelText: "Seleccionar insumo (Solo DISPONIBLE)",
                  prefixIcon:
                      Icon(Icons.grass_outlined, color: Color(0xFF43A047)),
                ),
                validator: (v) => v == null ? "Campo obligatorio" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _medidaCtrl,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: "Cantidad disponible",
                  prefixIcon: Icon(Icons.scale, color: Color(0xFF43A047)),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _cantidadCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Cantidad utilizada",
                  prefixIcon:
                      Icon(Icons.local_drink_outlined, color: Color(0xFF43A047)),
                ),
                validator: (v) => v!.isEmpty ? "Campo obligatorio" : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: objetivo,
                decoration: const InputDecoration(
                  labelText: "Objetivo de la actividad",
                  prefixIcon: Icon(Icons.flag_outlined, color: Color(0xFF43A047)),
                ),
                items: const [
                  DropdownMenuItem(
                      value: "Fertilización", child: Text("Fertilización")),
                  DropdownMenuItem(value: "Abono", child: Text("Abono")),
                  DropdownMenuItem(
                      value: "Matamaleza", child: Text("Matamaleza")),
                  DropdownMenuItem(value: "Otro", child: Text("Otro")),
                ],
                onChanged: (val) {
                  setState(() {
                    objetivo = val;
                    mostrarOtroObjetivo = val == "Otro";
                  });
                },
                validator: (v) => v == null ? "Campo obligatorio" : null,
              ),
              if (mostrarOtroObjetivo)
                TextFormField(
                  controller: _otroObjetivoCtrl,
                  decoration: const InputDecoration(
                    labelText: "Especificar otro objetivo",
                    prefixIcon:
                        Icon(Icons.text_fields, color: Color(0xFF43A047)),
                  ),
                  validator: (v) =>
                      mostrarOtroObjetivo && v!.isEmpty ? "Campo obligatorio" : null,
                ),
              const SizedBox(height: 12),
              
              // ✅ CORRECCIÓN: Usar el ID (int) como valor único
              DropdownButtonFormField<int>( 
                value: selectedResponsableId, 
                decoration: const InputDecoration(
                  labelText: "Responsable",
                  prefixIcon:
                      Icon(Icons.person_outline, color: Color(0xFF43A047)),
                ),
                items: personalEmpresa.map<DropdownMenuItem<int>>((p) { 
                final int id = p['id'] as int; 
                final String nombre = p['nombre'] ?? '';
                final String apellido = p['apellido'] ?? ''; 
                return DropdownMenuItem<int>( 
                  value: id, 
                  child: Text("$nombre $apellido"), // Mostramos Nombre Apellido
                );
              }).toList(),
                onChanged: (val) {
                  if (mounted) {
                    setState(() {
                      selectedResponsableId = val;
                    });
                  }
                },
                validator: (v) => v == null ? "Campo obligatorio" : null,
              ),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancelar"),
        ),
        ElevatedButton.icon(
          onPressed: isLoading ? null : registrarActividad,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF43A047),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: isLoading
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.save),
          label: Text(isLoading ? "Guardando..." : "Registrar"),
        ),
      ],
    );
  }
}