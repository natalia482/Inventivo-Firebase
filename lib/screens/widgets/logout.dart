import 'package:flutter/material.dart';
import 'package:inventivo/core/utils/session_manager.dart';

class LogoutButton extends StatelessWidget {
  const LogoutButton({super.key});

  @override
  Widget build(BuildContext context) {
    final session = SessionManager();

    return IconButton(
      icon: const Icon(Icons.logout),
      style: IconButton.styleFrom(foregroundColor: Colors.white),
      tooltip: 'Cerrar sesión',
      onPressed: () async {
        await session.logout();
        Navigator.pushReplacementNamed(context, '/login');
      },
    );
  }
}
