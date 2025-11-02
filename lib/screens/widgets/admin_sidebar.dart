import 'package:flutter/material.dart';
import 'package:inventivo/screens/widgets/logout.dart';

// Color principal de la aplicación
const Color primaryGreen = Color(0xFF2E7D32);
const Color secondaryGreen = Color(0xFF43A047);

// Definición del Widget modular para el menú lateral
class AdminSidebar extends StatelessWidget {
  final List<Map<String, dynamic>> modules;
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final String? nombreUsuario;
 // Añadido para mostrar el rol

  const AdminSidebar({
    required this.modules,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.nombreUsuario,
    super.key,
  });
  
  // Genera los ítems del menú lateral con diseño mejorado
  Widget _buildDrawerItem(Map<String, dynamic> module, int index, BuildContext context) {
    final isSelected = selectedIndex == index;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            onItemSelected(index);
            // Si no es pantalla grande, cerramos el drawer (caso móvil)
            if (MediaQuery.of(context).size.width < 800) {
              Navigator.pop(context); 
            }
          },
          // Contenedor para el efecto de selección y esquinas redondeadas
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                const SizedBox(width: 16),
                Icon(
                  module['icon'] as IconData, 
                  color: isSelected ? Colors.white : Colors.white70,
                ),
                const SizedBox(width: 12),
                Text(
                  module['title'] as String,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70, 
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Encabezado mejorado de la aplicación
  Widget _buildCustomHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF2E7D32), // Un verde más claro para el área del usuario
        border: Border(bottom: BorderSide(color: Colors.black.withOpacity(0.1), width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            backgroundColor: Colors.white,
            radius: 30,
            child: Icon(Icons.spa, color: primaryGreen, size: 35),
          ),
          const SizedBox(height: 10),
          Text(
            nombreUsuario ?? 'Usuario', 
            style: const TextStyle(
              color: Colors.white, 
              fontSize: 18, 
              fontWeight: FontWeight.bold
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280, // Ligeramente más ancho
      color: primaryGreen,
      child: Column(
        children: [
          // Área de Perfil/Encabezado
          _buildCustomHeader(),
          
          // Lista de Módulos
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: modules.asMap().entries.map((entry) {
                return _buildDrawerItem(entry.value, entry.key, context);
              }).toList(),
            ),
          ),

          // Botón de Cerrar Sesión (al final)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(bottom: 20.0, top: 10.0),
            child: const LogoutButton(isSidebar: true), 
          ),
        ],
      ),
    );
  }
}