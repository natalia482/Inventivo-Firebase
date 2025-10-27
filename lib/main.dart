import 'package:flutter/material.dart';
import 'package:inventivo/screens/auth/registro_trabajador.dart';
import 'package:inventivo/screens/auth/splash_screen.dart';
import 'package:inventivo/screens/auth/login_screen.dart';
import 'package:inventivo/screens/auth/registro_admin.dart';
import 'package:inventivo/screens/dashboard/trabajador_dashboard.dart';

void main() {
  runApp(const InventivoApp());
}

class InventivoApp extends StatelessWidget {
  const InventivoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Inventivo',
      theme: ThemeData(primarySwatch: Colors.green),
      initialRoute: '/',
      routes: {
        '/': (_) => const SplashScreen(),
        '/login': (_) => const LoginScreen(),
        '/registro_admin': (_) => RegistroAdminScreen(),
        '/dashboard_trabajador': (_) => const TrabajadorDashboard(),
        '/registro': (_) => const RegistroTrabajadorScreen(),
      },
    );
  }
}
