import 'package:flutter/material.dart';
import 'package:inventivo/core/utils/session_manager.dart';
import 'package:inventivo/screens/modulos/facturacion/facturas_screen.dart';
import 'package:inventivo/screens/modulos/plantas/plantas_page.dart';
import 'package:inventivo/screens/widgets/logout.dart';
import 'package:inventivo/screens/modulos/personal/listar_personal.dart';
import 'package:inventivo/screens/modulos/insumos/insumo_list.dart';

class AdminDashboard extends StatefulWidget {
  final int idEmpresa;

  const AdminDashboard({super.key, required this.idEmpresa});
  
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  String? userRole; // ✅ Estado para almacenar el rol

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final session = SessionManager();
    final user = await session.getUser();
    setState(() {
      userRole = user?['rol']; // Capturamos el rol
    });
  }

  // 🌿 Método para crear botones uniformes
  Widget _buildModuleButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton.icon(
        icon: Icon(icon, color: Colors.white, size: 24),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2E7D32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          shadowColor: Colors.black.withOpacity(0.2),
          elevation: 5,
        ),
        onPressed: onPressed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Muestra un loader hasta que el rol se cargue
    if (userRole == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFEFF7EE),
        appBar: AppBar(
          title: const Text("Cargando Panel..."),
          backgroundColor: const Color(0xFF2E7D32),
        ),
        body: const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32))),
      );
    }
    
    final bool isAdmin = userRole == 'ADMINISTRADOR';

    final isLargeScreen = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: const Color(0xFFEFF7EE),
      appBar: AppBar(
        title: const Text(
          "Panel Principal",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 4,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12.0),
            child: LogoutButton(),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: isLargeScreen ? 500 : double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 30),
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
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.admin_panel_settings,
                    color: Color(0xFF2E7D32), size: 70),
                const SizedBox(height: 10),
                Text(
                  "Bienvenido ${isAdmin ? 'Administrador' : 'Trabajador'}",
                  style: const TextStyle(
                    color: Color(0xFF2E7D32),
                    fontWeight: FontWeight.bold,
                    fontSize: 26,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),

                // 🔹 Módulo Trabajadores (SOLO ADMINISTRADOR)
                if (isAdmin) // ✅ Renderizado Condicional
                  Column(
                    children: [
                      _buildModuleButton(
                        context,
                        icon: Icons.people_outline,
                        label: "Módulo Trabajadores",
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ListaTrabajadores(idEmpresa: widget.idEmpresa),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 15),
                    ],
                  ),

                // 🔹 Módulo de Insumos (Visible para todos)
                _buildModuleButton(
                  context,
                  icon: Icons.inventory_2_outlined,
                  label: "Módulo de Insumos",
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const InsumosPage(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 15),

                // 🔹 Módulo de Plantas (Visible para todos)
                _buildModuleButton(
                  context,
                  icon: Icons.local_florist_outlined,
                  label: "Módulo de Plantas",
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PlantasPage(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 30),
                const Divider(),
                const SizedBox(height: 10),
                const Text(
                  "Inventivo 🌱 - Gestión Inteligente para Viveros",
                  style: TextStyle(color: Colors.black54, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}