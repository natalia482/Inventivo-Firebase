import 'package:flutter/material.dart';
import 'package:inventivo/screens/widgets/logout.dart';

class TrabajadorDashboard extends StatelessWidget {
  const TrabajadorDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Panel Trabajador"),
        actions: const [LogoutButton()],
      ),
      body: const Center(
        child: Text(
          "Bienvenido Trabajador 👷‍♂️",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
