import 'package:flutter/material.dart';
import 'package:inventivo/core/utils/session_manager.dart';
import 'package:inventivo/screens/modulos/facturacion/facturas_screen.dart';
import 'package:inventivo/screens/modulos/plantas/plantas_page.dart';
import 'package:inventivo/screens/widgets/logout.dart';
import 'package:inventivo/screens/modulos/personal/listar_personal.dart';
import 'package:inventivo/screens/modulos/insumos/insumo_list.dart';

class AdminDashboard extends StatelessWidget {
  final int idEmpresa;

  const AdminDashboard({super.key, required this.idEmpresa});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Panel Administrador"),
        actions: const [LogoutButton()],
      ),
      body: Center(
        child: SingleChildScrollView( 
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Bienvenido Administrador ",
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 20),

              // 🔹 Lista de trabajadores
              ElevatedButton.icon(
                icon: const Icon(Icons.people),
                label: const Text("Modulo trabajadores"),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ListaTrabajadores(idEmpresa: idEmpresa),
                    ),
                  );
                },
              ),

              // 🔹 Listar insumos
              ElevatedButton.icon(
                icon: const Icon(Icons.inventory),
                label: const Text("Modulo de Insumos"),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>  InsumosPage(),
                    ),
                  );
                },
              ),
              // 🔹 Plantas
              ElevatedButton.icon(
                icon: const Icon(Icons.local_florist),
                label: const Text("Modulo de Plantas"),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PlantasPage(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
