import 'package:flutter/material.dart';
import 'package:inventivo/core/utils/session_manager.dart';

class TrabajadorDashboard extends StatefulWidget {
  const TrabajadorDashboard({super.key});

  @override
  State<TrabajadorDashboard> createState() => _TrabajadorDashboardState();
}

class   _TrabajadorDashboardState extends State<TrabajadorDashboard> {
  String? userName = '';

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final session = SessionManager();
    final user = await session.getUser();
    setState(() {
      userName = user?['nombre'] ?? 'l';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Trabajador'),
      ),
      body: Center(
        child: Text(
          'Bienvenido',
          style: const TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}