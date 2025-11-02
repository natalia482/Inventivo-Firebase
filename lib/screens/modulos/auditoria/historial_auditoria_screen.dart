import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:inventivo/core/constants/api_config.dart';

class HistorialAuditoriaScreen extends StatefulWidget {
  final int idEmpresa;
  const HistorialAuditoriaScreen({super.key, required this.idEmpresa});

  @override
  State<HistorialAuditoriaScreen> createState() => _HistorialAuditoriaScreenState();
}

class _HistorialAuditoriaScreenState extends State<HistorialAuditoriaScreen> {
  List<dynamic> registros = [];
  bool isLoading = true;
  
  // ✅ 1. ESTADO PARA EL FILTRO DEL MÓDULO
  String _moduloSeleccionado = 'TODOS'; 
  final List<String> modulos = ['TODOS', 'PLANTAS', 'INSUMOS', 'USUARIOS','REMISIONES'];


  @override
  void initState() {
    super.initState();
    _cargarHistorial();
  }

  Future<void> _cargarHistorial() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.listarAuditoria(widget.idEmpresa)),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            registros = data['data'] ?? [];
            isLoading = false;
          });
        } else {
          setState(() => isLoading = false);
        }
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint("Error al cargar historial: $e");
    }
  }

  // ✅ 2. FUNCIÓN PARA FILTRAR LOS REGISTROS POR MÓDULO SELECCIONADO
  List<dynamic> get _registrosFiltrados {
    if (_moduloSeleccionado == 'TODOS') {
      return registros;
    }
    // El backend devuelve 'plantas', 'insumos', 'usuarios' (todo en minúsculas)
    final filtroTabla = _moduloSeleccionado.toLowerCase();
    
    return registros.where((log) {
      final tablaAfectada = log['tabla_afectada']?.toLowerCase() ?? '';
      return tablaAfectada == filtroTabla;
    }).toList();
  }

  // Helper para asignar iconos (se mantiene)
  IconData _getIconForOperation(String operacion) {
    switch (operacion.toUpperCase()) {
      case 'AGREGAR':
        return Icons.add_circle_outline;
      case 'ACTUALIZAR':
        return Icons.edit_outlined;
      case 'ELIMINAR':
        return Icons.delete_outline;
      case 'CAMBIO_ESTADO':
        return Icons.toggle_on_outlined;
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Usamos la lista filtrada
    final List<dynamic> registrosAMostrar = _registrosFiltrados; 

    return Scaffold(
      appBar: AppBar(
        title: const Text("Historial de Cambios"),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Color.fromARGB(255, 255, 255, 255),
      ),
      body: Column( // Usar Column para el filtro y la lista
        children: [
          // DropdownButton para el filtro
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Filtrar por Módulo:", style: TextStyle(fontWeight: FontWeight.bold)),
                DropdownButton<String>(
                  value: _moduloSeleccionado,
                  icon: const Icon(Icons.filter_list, color: Color(0xFF2E7D32)),
                  items: modulos.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _moduloSeleccionado = newValue;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          
          Expanded( // Envuelve el ListView en Expanded para que ocupe el espacio restante
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
                : registrosAMostrar.isEmpty
                    ? Center(
                        child: Text(
                          _moduloSeleccionado == 'TODOS'
                            ? "No hay registros de auditoría."
                            : "No hay registros para el módulo de $_moduloSeleccionado.",
                          style: const TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      )
                    : RefreshIndicator(
                        color: const Color(0xFF2E7D32),
                        onRefresh: _cargarHistorial,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: registrosAMostrar.length,
                          itemBuilder: (context, index) {
                            final log = registrosAMostrar[index];
                            final IconData icon = _getIconForOperation(log['tipo_operacion']);
                            final moduloNombre = log['tabla_afectada']?.toUpperCase() ?? 'N/A';
                            
                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.grey.shade200,
                                  child: Icon(icon, color: const Color(0xFF2E7D32)),
                                ),
                                title: Text(
                                  // Mostrar Modulo y luego el detalle
                                  "[$moduloNombre] ${log['detalle_cambio'] ?? 'Acción registrada'}",
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  "Usuario: ${log['usuario_nombre'] ?? 'N/A'} (${log['rol']})\n"
                                  "Sede: ${log['nombre_sede'] ?? 'N/A'}\n"
                                  "Fecha: ${log['fecha_cambio']}",
                                ),
                                isThreeLine: true,
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