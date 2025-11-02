import 'package:flutter/material.dart';
import 'package:inventivo/screens/auth/home_page.dart';
import 'package:inventivo/screens/auth/splash_screen.dart';
import 'package:inventivo/screens/auth/login_screen.dart';
import 'package:inventivo/screens/auth/registro_admin.dart';
import 'package:inventivo/screens/auth/reset_password_screen.dart'; // ✅ Importar ResetPasswordScreen

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
      
      // Mantenemos routes para las rutas simples
      routes: {
        '/': (_) => const SplashScreen(), 
        '/info_home': (_) => const HomePage(),
        '/login': (_) => const LoginScreen(),
        '/registro_admin': (_) => RegistroAdminScreen(),
        // No definimos /reset_password aquí, lo manejamos en onGenerateRoute
      },

      // ✅ NUEVO: onGenerateRoute para manejar rutas dinámicas como Deep Links
      onGenerateRoute: (settings) {
        // Intercepta la ruta /reset_password
        if (settings.name?.startsWith('/reset_password') ?? false) {
          final uri = Uri.parse(settings.name!);
          // Extrae el tken del parámetro de consulta (ej: ?token=XYZ)
          final token = uri.queryParameters['token'];

          // Construye y devuelve la pantalla de restablecimiento de contraseña
          return MaterialPageRoute(
            builder: (context) => ResetPasswordScreen(token: token),
            settings: settings, // Esto es importante para que el sistema lo reconozca
          );
        }
        // Retorna null para usar el mapeo de rutas por defecto si no es /reset_password
        return null;
      },
    );
  }
}