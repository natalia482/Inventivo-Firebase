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

  // Helper para asignar iconos
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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Historial de Cambios"),
        backgroundColor: const Color(0xFF2E7D32),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
          : registros.isEmpty
              ? const Center(
                  child: Text(
                    "No hay registros de auditoría.",
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                )
              : RefreshIndicator(
                  color: const Color(0xFF2E7D32),
                  onRefresh: _cargarHistorial,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: registros.length,
                    itemBuilder: (context, index) {
                      final log = registros[index];
                      final IconData icon = _getIconForOperation(log['tipo_operacion']);
                      
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
                            log['detalle_cambio'] ?? 'Acción registrada',
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
    );
  }
}