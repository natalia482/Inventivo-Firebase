import 'package:flutter/material.dart';
import 'package:inventivo/core/utils/session_manager.dart';
import 'package:inventivo/screens/widgets/logout.dart';
import 'package:inventivo/screens/widgets/admin_sidebar.dart'; // ✅ IMPORTAMOS EL NUEVO HEADER/SIDEBAR

// Importar los módulos que se cargarán en el cuerpo
import 'package:inventivo/screens/modulos/plantas/plantas_page.dart';
import 'package:inventivo/screens/modulos/insumos/insumo_list.dart';
import 'package:inventivo/screens/modulos/personal/listar_personal.dart';
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
  int? idEmpresa; 
  String nombreUsuario = ''; 
  
  // ✅ Estado para rastrear la página seleccionada (0 = Bienvenida, 1 = Plantas, etc.)
  int _selectedIndex = 0; 

  // --- Definición de Módulos (Lógica y Permisos) ---
  List<Map<String, dynamic>> _getModules() {
    // Permisos
    final String role = userRole ?? '';
    final bool isPropietario = role == 'PROPIETARIO';
    final bool canManageStaff = (role == 'PROPIETARIO' || role == 'ADMINISTRADOR');
    final bool hasData = idSede != null && idEmpresa != null;

    // Inicializamos con la pantalla de bienvenida (index 0)
    final List<Map<String, dynamic>> modules = [
      {'title': 'Panel Principal', 'icon': Icons.home, 'screen': _buildWelcomeScreen()},
    ];

    if (!hasData) return modules; // Si no hay datos de sesión, solo mostramos el panel.

    // Módulos visibles para Trabajador, Administrador y Propietario
    modules.addAll([
      {'title': 'Módulo de Insumos', 'icon': Icons.inventory_2_outlined, 'screen': const InsumosPage()},
      {'title': 'Módulo de Plantas', 'icon': Icons.local_florist_outlined, 'screen': const PlantasPage()},
    ]);
    
    // Módulos restringidos por rol
    if (canManageStaff) {
      modules.add({'title': 'Módulo Personal', 'icon': Icons.people_outline, 'screen': ListaTrabajadores(idSede: idSede!)});
    }

    if (isPropietario) {
      modules.add({'title': 'Historial de Cambios', 'icon': Icons.history_edu_outlined, 'screen': HistorialAuditoriaScreen(idEmpresa: idEmpresa!)});
    }
    
    return modules;
  }
  
  // Widget de Bienvenida (se usa como la página inicial)
  Widget _buildWelcomeScreen() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
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
            const Text(
              "Seleccione un módulo del menú lateral para comenzar a trabajar.",
              style: TextStyle(color: Colors.black54, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }


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
      nombreUsuario = user?['nombre'] ?? 'Usuario'; 
    });
  }
  
  // Función para manejar la selección de un ítem del sidebar
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }


  @override
  Widget build(BuildContext context) {
    final modules = _getModules();
    final isLargeScreen = MediaQuery.of(context).size.width > 800;
    
    // Si aún no se cargan los datos, podemos mostrar un loader
    if (userRole == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
        backgroundColor: Color(0xFFEFF7EE),
      );
    }

    // Obtenemos el título de la página actual
    final currentTitle = modules[_selectedIndex]['title'] as String;

    return Scaffold(
      appBar: AppBar(
        title: Text(currentTitle, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 4,
        // Ocultamos el botón de logout de la barra para dejarlo solo en el sidebar/drawer.
        actions: isLargeScreen ? null : const [ 
          Padding(
            padding: EdgeInsets.only(right: 12.0),
           
          ),
        ],
      ),
      
      // ✅ Sidebar Permanente para Pantallas Grandes
      body: Row(
        children: [
          if (isLargeScreen)
            // Llama al widget Sidebar para el menú permanente
            AdminSidebar(
              modules: modules,
              selectedIndex: _selectedIndex,
              onItemSelected: _onItemTapped,
              nombreUsuario: nombreUsuario,
            ),
          
          // ✅ Contenido de la Pantalla Seleccionada
          Expanded(
            child: modules[_selectedIndex]['screen'] as Widget,
          ),
        ],
      ),
      
      // ✅ Drawer para Pantallas Pequeñas (Móviles)
      drawer: isLargeScreen
          ? null
          : Drawer(
              child: AdminSidebar(
                modules: modules,
                selectedIndex: _selectedIndex,
                onItemSelected: _onItemTapped,
                nombreUsuario: nombreUsuario,
              ),
            ),
    );
  }
}