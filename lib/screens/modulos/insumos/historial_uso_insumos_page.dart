import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:inventivo/core/constants/api_config.dart';
import 'package:inventivo/core/utils/session_manager.dart';

class HistorialUsoInsumosPage extends StatefulWidget {
  const HistorialUsoInsumosPage({Key? key}) : super(key: key);

  @override
  _HistorialUsoInsumosPageState createState() => _HistorialUsoInsumosPageState();
}

class _HistorialUsoInsumosPageState extends State<HistorialUsoInsumosPage> {
  List<dynamic> movimientos = [];
  bool isLoading = true;
  int? idEmpresa;

  @override
  void initState() {
    super.initState();
    _loadHistorial();
  }

  Future<void> _loadHistorial() async {
    final session = SessionManager();
    final user = await session.getUser();

    if (user != null && user["id_empresa"] != null) {
      idEmpresa = user["id_empresa"];
      await _listarHistorial();
    } else {
      setState(() => isLoading = false);
    }
  }

  Future<void> _listarHistorial() async {
    if (idEmpresa == null) return;

    final url = Uri.parse(ApiConfig.listarAbonos(idEmpresa!));
    print("📡 Solicitando historial desde: $url");

    try {
      final response = await http.get(url);

      print("📥 Respuesta (${response.statusCode}): ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["success"] == true) {
          setState(() {
            movimientos = data["data"];
            isLoading = false;
          });
        } else {
          setState(() {
            movimientos = [];
            isLoading = false;
          });
        }
      } else {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error en el servidor (${response.statusCode})")),
        );
      }
    } catch (e) {
      print("❌ Error al procesar respuesta: $e");
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al conectar con el servidor.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Historial de Uso de Insumos")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : movimientos.isEmpty
              ? const Center(child: Text("No hay movimientos registrados."))
              : RefreshIndicator(
                  onRefresh: _listarHistorial,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text("Fecha")),
                          DataColumn(label: Text("Producto")),
                          DataColumn(label: Text("Cantidad")),
                          DataColumn(label: Text("Dosificación")),
                          DataColumn(label: Text("Objetivo")),
                          DataColumn(label: Text("Responsable")),
                        ],
                        rows: movimientos.map((m) {
                          return DataRow(cells: [
                            DataCell(Text(m["fecha"] ?? "-")),
                            DataCell(Text(m["producto"] ?? "-")),
                            DataCell(Text(m["cantidad_utilizada"].toString())),
                            DataCell(Text(m["dosificacion"] ?? "-")),
                            DataCell(Text(m["objetivo"] ?? "-")),
                            DataCell(Text(m["responsable"] ?? "-")),
                          ]);
                        }).toList(),
                      ),
                    ),
                  ),
                ),
    );
  }
}
