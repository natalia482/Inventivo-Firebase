import 'package:flutter/material.dart';
import 'package:inventivo/core/utils/session_manager.dart';
import 'package:inventivo/screens/auth/login_screen.dart';

class LogoutButton extends StatelessWidget {
  const LogoutButton({super.key, required bool isSidebar});

  @override
  Widget build(BuildContext context) {
    final session = SessionManager();

    return IconButton(
      icon: const Icon(Icons.logout),
      style: IconButton.styleFrom(foregroundColor: Colors.white),
      tooltip: 'Cerrar sesión',
      onPressed: () async {
        await session.logout();
        Navigator.push(context, MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ));
      },
    );
  }
}
