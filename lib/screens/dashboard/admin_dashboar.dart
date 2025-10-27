import 'package:flutter/material.dart';
import 'package:inventivo/screens/modulos/insumos/historial_uso_insumos_page.dart';
import 'package:inventivo/screens/modulos/insumos/registrar_uso_insumo.dart' show RegistrarUsoInsumoPage;
import 'package:inventivo/screens/widgets/logout.dart';
import 'package:inventivo/screens/modulos/personal/listar_personal.dart';
import 'package:inventivo/screens/modulos/insumos/registrar_insumo.dart';
import 'package:inventivo/screens/modulos/insumos/insumo_list.dart';

import '../auth/registro_trabajador.dart' show RegistroTrabajadorScreen;

class AdminDashboard extends StatelessWidget {
  final int idEmpresa; // 👈 Agrega esta línea

  const AdminDashboard({super.key, required this.idEmpresa}); // 👈 Requiere el idEmpresa

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Panel Administrador"),
        actions: const [LogoutButton()],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Bienvenido Administrador 🌿 ",
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.people),
              label: const Text("Ver lista de trabajadores"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ListaTrabajadores(idEmpresa: idEmpresa),
                  ),
                );
              },
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.people),
              label: const Text("Registrar trabajadores"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RegistroTrabajadorScreen(),
                  ),
                );
              },
            ),
             ElevatedButton.icon(
              icon: const Icon(Icons.people),
              label: const Text("Lista Insumo"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ListarInsumosPage(),
                  ),
                );
              },
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.people),
              label: const Text("Registrar Insumo"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RegistroInsumoScreen(),
                  ),
                );
              },
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.people),
              label: const Text("Registrar Actividad Agricola"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RegistrarUsoInsumoPage(),
                  ),
                );
              },
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.people),
              label: const Text("Lista Actividad Agricola"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HistorialUsoInsumosPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
