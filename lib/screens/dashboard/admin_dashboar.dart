import 'package:flutter/material.dart';
import 'package:inventivo/core/utils/session_manager.dart';
import 'package:inventivo/screens/modulos/remision/remision_screen.dart'; 
import 'package:inventivo/screens/modulos/plantas/plantas_page.dart';
import 'package:inventivo/screens/widgets/logout.dart';
import 'package:inventivo/screens/modulos/personal/listar_personal.dart';
import 'package:inventivo/screens/modulos/insumos/insumo_list.dart';
import 'package:inventivo/screens/modulos/auditoria/historial_auditoria_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final SessionManager _session = SessionManager();
  String? userRole;
  int? idSede;
  int? idEmpresa; // (Lo mantenemos por si lo necesitas para el título de la empresa, etc.)
  String nombreUsuario = ''; // Para el saludo

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = await _session.getUser();
    setState(() {
      userRole = user?['rol']?.toUpperCase();
      idSede = int.tryParse(user?['id_sede']?.toString() ?? '0');
      idEmpresa = int.tryParse(user?['id_empresa']?.toString() ?? '0');
      nombreUsuario = user?['nombre'] ?? 'Usuario'; // Guardamos el nombre
    });
  }

  // Método para crear botones uniformes
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
    // Si los datos aún no están listos, muestra un loader
   // Banderas de control de roles
    final bool isPropietario = userRole == 'PROPIETARIO';
    final bool canManageStaff = (userRole == 'PROPIETARIO' || userRole == 'ADMINISTRADOR');

    final isLargeScreen = MediaQuery.of(context).size.width > 800;
    
    return Scaffold(
      backgroundColor: const Color(0xFFEFF7EE),
      appBar: AppBar(
        title: const Text("Panel Principal", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                  "Bienvenido $nombreUsuario",
                  style: const TextStyle(
                    color: Color(0xFF2E7D32),
                    fontWeight: FontWeight.bold,
                    fontSize: 26,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  "Rol: $userRole", 
                  style: const TextStyle(color: Colors.black54, fontSize: 16),
                ),
                const SizedBox(height: 30),

                // 🔹 Módulo Personal (PROPIETARIO / ADMIN)
                if (canManageStaff)
                  Column(
                    children: [
                      _buildModuleButton(
                        context,
                        icon: Icons.people_outline,
                        label: "Módulo Personal",
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ListaTrabajadores(idSede: idSede!), 
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 15),
                    ],
                  ),

                // 🔹 Módulo de Insumos (Todos)
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

                // 🔹 Módulo de Plantas (Todos)
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
                const SizedBox(height: 15),
                
                // ✅ NUEVO: Módulo de Auditoría (SOLO PROPIETARIO)
                if (isPropietario)
                  Column(
                    children: [
                      _buildModuleButton(
                        context,
                        icon: Icons.history_edu_outlined, // Icono de historial
                        label: "Historial de Cambios",
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  HistorialAuditoriaScreen(idEmpresa: idEmpresa!),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 15),
                    ],
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