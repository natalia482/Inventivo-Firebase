import 'package:flutter/material.dart';
import 'package:inventivo/core/utils/session_manager.dart';
import 'package:inventivo/screens/dashboard/admin_dashboar.dart';
import 'package:inventivo/screens/dashboard/trabajador_dashboard.dart';
import 'package:inventivo/screens/auth/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final SessionManager _session = SessionManager();

  @override
  void initState() {
    super.initState();
    _verificarSesion();
  }

  Future<void> _verificarSesion() async {
    await Future.delayed(const Duration(seconds: 2)); // Simula carga
    final usuario = await _session.getUser();

    if (!mounted) return;

    if (usuario != null) {
      final rol = usuario['rol'];
      final idEmpresa = int.tryParse(usuario['id_empresa'].toString()) ?? 0;

      if (rol == 'ADMINISTRADOR') {
        // 🚀 Navega directamente al dashboard con el parámetro
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => AdminDashboard(idEmpresa: idEmpresa),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const TrabajadorDashboard(),
          ),
        );
      }
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.green,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.eco, size: 80, color: Colors.white),
            SizedBox(height: 20),
            Text(
              "INVENTIVO",
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            SizedBox(height: 10),
            CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
